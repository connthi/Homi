import Foundation

// Internal response models used only for decoding simple API messages.
private struct APIMessageResponse: Codable { let message: String }
private struct AuthCredentials: Codable { let email: String; let password: String }
private struct RegisterPayload: Codable { let email: String; let password: String; let firstName: String?; let lastName: String? }
private struct RefreshTokenPayload: Codable { let refreshToken: String }

/// Centralized API client used for performing all authenticated and unauthenticated
/// requests to the backend. Handles URL construction, JSON encoding/decoding, and error mapping.
class APIService {
    static let shared = APIService()
    
    private let baseURL: String
    private let session: URLSession
    private let authService = AuthService.shared
    
    private init(session: URLSession = .shared) {
        self.session = session
        self.baseURL = APIService.resolveBaseURL()
    }
    
    // MARK: - Layout API Methods
    
    /// Fetches all layouts belonging to the authenticated user.
    func fetchLayouts() async throws -> [Layout] {
        let request = try makeRequest(path: "/layouts", requiresAuth: true)
        let data = try await send(request)
        return try decodeResponse([Layout].self, from: data)
    }
    
    /// Fetches a specific layout by ID.
    func fetchLayout(id: String) async throws -> Layout {
        let request = try makeRequest(path: "/layouts/\(id)", requiresAuth: true)
        let data = try await send(request)
        return try decodeResponse(Layout.self, from: data)
    }
    
    /// Creates a new layout on the server.
    func saveLayout(_ layout: Layout) async throws -> Layout {
        let body = try encodeBody(layout)
        let request = try makeRequest(path: "/layouts", method: "POST", body: body, requiresAuth: true)
        let data = try await send(request, expectedStatus: 201)
        return try decodeResponse(Layout.self, from: data)
    }
    
    /// Updates an existing layout with new properties.
    func updateLayout(_ layout: Layout) async throws -> Layout {
        guard let id = layout.id, !id.isEmpty else { throw APIError.invalidURL }
        
        let body = try encodeBody(layout)
        let request = try makeRequest(path: "/layouts/\(id)", method: "PUT", body: body, requiresAuth: true)
        let data = try await send(request)
        return try decodeResponse(Layout.self, from: data)
    }
    
    /// Deletes a layout from the server.
    func deleteLayout(id: String) async throws {
        let request = try makeRequest(path: "/layouts/\(id)", method: "DELETE", requiresAuth: true)
        _ = try await send(request)
    }
    
    // MARK: - Catalog API Methods
    
    /// Retrieves the furniture catalog for the authenticated user.
    func fetchCatalog() async throws -> [CatalogItem] {
        let request = try makeRequest(path: "/catalog", requiresAuth: true)
        let data = try await send(request)
        return try decodeResponse([CatalogItem].self, from: data)
    }
    
    // MARK: - Sharing API Methods

    struct ShareLinkResponse: Codable {
        let shareId: String
        let shareUrl: String
        let createdAt: Date?
        let expiresAt: Date?
    }

    func createShareLink(layoutId: String) async throws -> ShareLinkResponse {
        print("🔗 Creating share link for layout: \(layoutId)")
        print("🌐 API Base URL: \(baseURL)")
        
        let body = try encodeBody(["layoutId": layoutId])
        let request = try makeRequest(path: "/share", method: "POST", body: body, requiresAuth: true)
        
        print("📤 Full Request URL: \(request.url?.absoluteString ?? "nil")")
        
        do {
            let data = try await send(request, expectedStatus: 201)
            print("✅ Share link created successfully")
            return try decodeResponse(ShareLinkResponse.self, from: data)
        } catch {
            print("❌ Share link error: \(error)")
            throw error
        }
    }

    func fetchSharedLayout(shareId: String) async throws -> Layout {
        print("🔗 Fetching shared layout: \(shareId)")
        print("🌐 API Base URL: \(baseURL)")
        
        let request = try makeRequest(path: "/share/\(shareId)", requiresAuth: false)
        
        print("📤 Full Request URL: \(request.url?.absoluteString ?? "nil")")
        
        do {
            let data = try await send(request)
            print("✅ Shared layout fetched successfully")
            
            // Decode and log the response
            let layout = try decodeResponse(Layout.self, from: data)
            print("   Layout ID: \(layout.id ?? "nil")")
            print("   Layout Name: \(layout.name)")
            print("   User ID: \(layout.userId)")
            print("   Furniture Items: \(layout.furnitureItems.count)")
            
            return layout
        } catch {
            print("❌ Fetch shared layout error: \(error)")
            throw error
        }
    }

    func deleteShareLink(shareId: String) async throws {
        let request = try makeRequest(path: "/share/\(shareId)", method: "DELETE", requiresAuth: true)
        _ = try await send(request)
    }

    func fetchUserShareLinks() async throws -> [ShareLinkInfo] {
        let request = try makeRequest(path: "/share", requiresAuth: true)
        let data = try await send(request)
        return try decodeResponse([ShareLinkInfo].self, from: data)
    }

    struct ShareLinkInfo: Codable {
        let shareId: String
        let shareUrl: String
        let layoutName: String
        let createdAt: Date
        let expiresAt: Date?
        let viewCount: Int
    }

    // MARK: - Request Construction
    
    /// Builds a properly formatted URLRequest with optional body and authorization header.
    private func makeRequest(path: String,
                             method: String = "GET",
                             body: Data? = nil,
                             requiresAuth: Bool = false) throws -> URLRequest {
        let url = try buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if requiresAuth {
            guard let token = authService.getAccessToken() else { throw APIError.unauthorized }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    // MARK: - Request Sending
    
    /// Sends a request and validates the response status code. Maps server errors to APIError.
    private func send(_ request: URLRequest, expectedStatus: Int? = nil) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            
            let okRange = 200..<300
            if let expectedStatus, http.statusCode != expectedStatus {
                try handleServerError(statusCode: http.statusCode, data: data)
            } else if !okRange.contains(http.statusCode) {
                try handleServerError(statusCode: http.statusCode, data: data)
            }
            
            return data
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    /// Attempts to parse an error message from the server before throwing.
    private func handleServerError(statusCode: Int, data: Data) throws {
        let message = try? decoder.decode(APIMessageResponse.self, from: data).message
        
        if statusCode == 401 {
            if let message, !message.isEmpty {
                throw APIError.serverError(statusCode: statusCode, message: message)
            }
            throw APIError.unauthorized
        }
        
        throw APIError.serverError(statusCode: statusCode, message: message)
    }
    
    // MARK: - Encoding/Decoding
    
    /// Encodes a request body to JSON.
    private func encodeBody<T: Encodable>(_ body: T) throws -> Data {
        do { return try encoder.encode(body) }
        catch { throw APIError.encodingError(error) }
    }
    
    /// Decodes a JSON response body into the expected model.
    private func decodeResponse<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do { return try decoder.decode(T.self, from: data) }
        catch { throw APIError.decodingError(error) }
    }
    
    // MARK: - URL Building
    
    /// Safely joins base URL + endpoint path.
    private func buildURL(path: String) throws -> URL {
        let trimmedBase = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        let trimmedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let full = trimmedPath.isEmpty ? trimmedBase : "\(trimmedBase)/\(trimmedPath)"
        guard let url = URL(string: full) else { throw APIError.invalidURL }
        return url
    }
    
    /// Determines API base URL using environment override → Info.plist → default.
    private static func resolveBaseURL() -> String {
        if let override = ProcessInfo.processInfo.environment["API_BASE_URL"],
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return override
        }
        
        if let info = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !info.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return info
        }
        
        return "https://homi-sfhr.onrender.com/api"
    }
    
    // MARK: - JSON Helpers
    
    /// Shared JSON decoder with flexible date decoding support.
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let patterns: [(ISO8601DateFormatter) -> Void] = [
                { $0.formatOptions = [.withInternetDateTime, .withFractionalSeconds] },
                { $0.formatOptions = [.withInternetDateTime] },
                { $0.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime] }
            ]
            
            for configure in patterns {
                let fmt = ISO8601DateFormatter()
                configure(fmt)
                if let date = fmt.date(from: dateString) { return date }
            }
            
            let fallback = DateFormatter()
            fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            fallback.locale = Locale(identifier: "en_US_POSIX")
            fallback.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = fallback.date(from: dateString) { return date }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        return decoder
    }
    
    /// Shared JSON encoder using ISO-8601 dates.
    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

// MARK: - Error Handling

/// Errors thrown by the API layer, mapped to user-friendly descriptions.
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
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .unauthorized: return "You need to log in again."
        case .serverError(let code, let message):
            return message ?? "Server error: \(code)"
        case .decodingError(let err):
            return "Failed to decode response: \(err.localizedDescription)"
        case .encodingError(let err):
            return "Failed to encode request: \(err.localizedDescription)"
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        }
    }
}