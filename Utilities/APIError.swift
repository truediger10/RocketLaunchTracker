import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(String)
    case unauthorized
    case rateLimited
    case serverError(code: Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid."
        case .invalidResponse:
            return "Received invalid response from the server."
        case .decodingError(let message):
            return "Failed to decode data: \(message)"
        case .unauthorized:
            return "You are not authorized to perform this action."
        case .rateLimited:
            return "You have exceeded the rate limit."
        case .serverError(let code):
            return "Server error with code: \(code)."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
