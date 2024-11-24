import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited
    case serverError(code: Int)
    case networkError(Error)
    case processingError    // Added this missing case
    case dataConversionError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized access"
        case .rateLimited:
            return "Too many requests. Please try again later"
        case .serverError(let code):
            return "Server error (Code: \(code))"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .processingError:
            return "Error processing data"
        case .dataConversionError:
            return "Error converting data"
        }
    }
}
