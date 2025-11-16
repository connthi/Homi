import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://homi-sfhr.onrender.com/api"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Decoder Configuration
    
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        
        // Custom date decoder to handle various ISO8601 formats
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try multiple ISO8601 formats
            let formatters: [(ISO8601DateFormatter) -> Void] = [
                { formatter in
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                },
                { formatter in
                    formatter.formatOptions = [.withInternetDateTime]
                },
                { formatter in
                    formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
                }
            ]
            
            for configureFormatter in formatters {
                let formatter = ISO8601DateFormatter()
                configureFormatter(formatter)
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            // Fallback to a simple date formatter
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
            fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = fallbackFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
        
        return decoder
    }
    
    // MARK: - Layout API Methods
    
    func fetchLayouts() async throws -> [Layout] {
        guard let url = URL(string: "\(baseURL)/layouts") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        do {
            // Debug: Print raw JSON
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 Raw JSON from API:")
                print(jsonString)
            }
            
            return try decoder.decode([Layout].self, from: data)
        } catch {
            print("❌ Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Key '\(key.stringValue)' not found: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("Type '\(type)' mismatch: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Value '\(type)' not found: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error")
                }
            }
            throw APIError.decodingError(error)
        }
    }
    
    func fetchLayout(id: String) async throws -> Layout {
        guard let url = URL(string: "\(baseURL)/layouts/\(id)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode(Layout.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError(error)
        }
    }
    
    func saveLayout(_ layout: Layout) async throws -> Layout {
        guard let url = URL(string: "\(baseURL)/layouts") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            request.httpBody = try encoder.encode(layout)
        } catch {
            throw APIError.encodingError(error)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode(Layout.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError(error)
        }
    }
    
    func updateLayout(_ layout: Layout) async throws -> Layout {
        // Safely unwrap the optional ID
        guard let id = layout.id, !id.isEmpty else {
            throw APIError.invalidURL
        }

        guard let url = URL(string: "\(baseURL)/layouts/\(id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            request.httpBody = try encoder.encode(layout)
        } catch {
            throw APIError.encodingError(error)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode(Layout.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError(error)
        }
    }

    
    func deleteLayout(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/layouts/\(id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }
    
    // MARK: - Catalog API Methods
    
    func fetchCatalog() async throws -> [CatalogItem] {
        guard let url = URL(string: "\(baseURL)/catalog") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode([CatalogItem].self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - Error Handling

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
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