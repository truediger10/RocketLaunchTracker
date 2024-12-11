// Utilities/APIError.swift

import Foundation

/// Errors that can occur during API interactions.
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case rateLimited
    case serverError(code: Int)
    case networkError(Error)
    case decodingError(Error) // Added decodingError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The API URL is invalid."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let code):
            return "Server encountered an error with status code \(code)."
        case .networkError(let error):
            return "Network error occurred: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}
