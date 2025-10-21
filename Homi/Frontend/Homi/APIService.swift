import Foundation

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:5000/api"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Layout API Methods
    
    func fetchLayouts() async throws -> [Layout] {
        guard let url = URL(string: "\(baseURL)/layouts") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode([Layout].self, from: data)
    }
    
    func fetchLayout(id: String) async throws -> Layout {
        guard let url = URL(string: "\(baseURL)/layouts/\(id)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(Layout.self, from: data)
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
        request.httpBody = try encoder.encode(layout)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(Layout.self, from: data)
    }
    
    func updateLayout(_ layout: Layout) async throws -> Layout {
        guard let url = URL(string: "\(baseURL)/layouts/\(layout.id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(layout)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(Layout.self, from: data)
    }
    
    func deleteLayout(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/layouts/\(id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
    }
    
    // MARK: - Catalog API Methods
    
    func fetchCatalog() async throws -> [CatalogItem] {
        guard let url = URL(string: "\(baseURL)/catalog") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode([CatalogItem].self, from: data)
    }
}

// MARK: - Error Handling

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network error occurred"
        }
    }
}
