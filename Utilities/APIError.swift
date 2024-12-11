// Utilities/APIError.swift

import Foundation

/// Errors specific to API interactions.
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case rateLimited
    case serverError(code: Int)
    case networkError(Error)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The API URL is invalid."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .decodingError(let error):
            return "Failed to decode the response: \(error.localizedDescription)"
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let code):
            return "Server returned an error with status code \(code)."
        case .networkError(let error):
            return "Network error occurred: \(error.localizedDescription)"
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}
