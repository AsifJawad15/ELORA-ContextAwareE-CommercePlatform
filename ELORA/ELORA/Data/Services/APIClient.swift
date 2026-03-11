import Foundation

/// Lightweight HTTP helper for external API calls.
enum APIClient {

    enum APIError: LocalizedError {
        case invalidURL
        case httpError(Int)
        case noData
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL."
            case .httpError(let code): return "HTTP error \(code)."
            case .noData: return "No data received."
            case .decodingFailed: return "Failed to decode response."
            }
        }
    }

    static func get<T: Decodable>(_ urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError.httpError(http.statusCode)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    static func post(_ urlString: String, body: [String: Any]) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError.httpError(http.statusCode)
        }
        return data
    }
}
