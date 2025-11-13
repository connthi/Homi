import Foundation

private struct APIMessageResponse: Codable {
    let message: String
}

private struct AuthCredentials: Codable {
    let email: String
    let password: String
}

private struct RegisterPayload: Codable {
    let email: String
    let password: String
    let firstName: String?
    let lastName: String?
}

private struct RefreshTokenPayload: Codable {
    let refreshToken: String
}

class APIService {
    static let shared = APIService()
    
    private let baseURL = "http://192.168.0.183:5001/api"
    private let session: URLSession
    private let authService = AuthService.shared
    
    private init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Layout API Methods
    
    func fetchLayouts() async throws -> [Layout] {
        let request = try makeRequest(path: "/layouts", requiresAuth: true)
        let data = try await send(request)
        return try decodeResponse([Layout].self, from: data)
    }
    
    func fetchLayout(id: String) async throws -> Layout {
        let request = try makeRequest(path: "/layouts/\(id)", requiresAuth: true)
        let data = try await send(request)
        return try decodeResponse(Layout.self, from: data)
    }
    
    func saveLayout(_ layout: Layout) async throws -> Layout {
        let body = try encodeBody(layout)
        let request = try makeRequest(path: "/layouts", method: "POST", body: body, requiresAuth: true)
        let data = try await send(request, expectedStatus: 201)
        return try decodeResponse(Layout.self, from: data)
    }
    
    func updateLayout(_ layout: Layout) async throws -> Layout {
        guard let id = layout.id, !id.isEmpty else {
            throw APIError.invalidURL
        }
        
        let body = try encodeBody(layout)
        let request = try makeRequest(path: "/layouts/\(id)", method: "PUT", body: body, requiresAuth: true)
        let data = try await send(request)
        return try decodeResponse(Layout.self, from: data)
    }
    
    func deleteLayout(id: String) async throws {
        let request = try makeRequest(path: "/layouts/\(id)", method: "DELETE", requiresAuth: true)
        _ = try await send(request)
    }
    
    // MARK: - Catalog API Methods
    
    func fetchCatalog() async throws -> [CatalogItem] {
        let request = try makeRequest(path: "/catalog", requiresAuth: true)
        let data = try await send(request)
        return try decodeResponse([CatalogItem].self, from: data)
    }
    
    // MARK: - Authentication API Methods
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let payload = AuthCredentials(email: email, password: password)
        let body = try encodeBody(payload)
        let request = try makeRequest(path: "/auth/login", method: "POST", body: body)
        let data = try await send(request)
        return try decodeResponse(AuthResponse.self, from: data)
    }
    
    func register(email: String, password: String, firstName: String?, lastName: String?) async throws -> AuthResponse {
        let payload = RegisterPayload(email: email, password: password, firstName: firstName, lastName: lastName)
        let body = try encodeBody(payload)
        let request = try makeRequest(path: "/auth/register", method: "POST", body: body)
        let data = try await send(request, expectedStatus: 201)
        return try decodeResponse(AuthResponse.self, from: data)
    }
    
    func getCurrentUser() async throws -> User {
        let request = try makeRequest(path: "/auth/me", requiresAuth: true)
        let data = try await send(request)
        let response = try decodeResponse(UserEnvelope.self, from: data)
        return response.user
    }
    
    func refreshToken(refreshToken: String) async throws -> AuthResponse {
        let payload = RefreshTokenPayload(refreshToken: refreshToken)
        let body = try encodeBody(payload)
        let request = try makeRequest(path: "/auth/refresh", method: "POST", body: body)
        let data = try await send(request)
        return try decodeResponse(AuthResponse.self, from: data)
    }
    
    func logout(refreshToken: String) async throws {
        let payload = RefreshTokenPayload(refreshToken: refreshToken)
        let body = try encodeBody(payload)
        let request = try makeRequest(path: "/auth/logout", method: "POST", body: body, requiresAuth: true)
        _ = try await send(request)
    }
    
    // MARK: - Request Helpers
    
    private func makeRequest(path: String,
                             method: String = "GET",
                             body: Data? = nil,
                             requiresAuth: Bool = false) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if requiresAuth {
            guard let accessToken = authService.getAccessToken() else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func send(_ request: URLRequest, expectedStatus: Int? = nil) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            let successRange = 200..<300
            if let expectedStatus = expectedStatus, httpResponse.statusCode != expectedStatus {
                try handleServerError(statusCode: httpResponse.statusCode, data: data)
            } else if !successRange.contains(httpResponse.statusCode) {
                try handleServerError(statusCode: httpResponse.statusCode, data: data)
            }
            
            return data
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    private func handleServerError(statusCode: Int, data: Data) throws {
        if statusCode == 401 {
            throw APIError.unauthorized
        }
        
        let message = try? decoder.decode(APIMessageResponse.self, from: data).message
        throw APIError.serverError(statusCode: statusCode, message: message)
    }
    
    private func encodeBody<T: Encodable>(_ body: T) throws -> Data {
        do {
            return try encoder.encode(body)
        } catch {
            throw APIError.encodingError(error)
        }
    }
    
    private func decodeResponse<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - JSON Helpers
    
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatters: [(ISO8601DateFormatter) -> Void] = [
                { $0.formatOptions = [.withInternetDateTime, .withFractionalSeconds] },
                { $0.formatOptions = [.withInternetDateTime] },
                { $0.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime] }
            ]
            
            for configure in formatters {
                let formatter = ISO8601DateFormatter()
                configure(formatter)
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
            fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = fallbackFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
        }
        
        return decoder
    }
    
    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

// MARK: - Error Handling

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(statusCode: Int, message: String?)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "You need to log in again."
        case .serverError(let statusCode, let message):
            if let message = message, !message.isEmpty {
                return message
            }
            return "Server error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
