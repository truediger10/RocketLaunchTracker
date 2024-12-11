// Utilities/APIError.swift

import Foundation

/// Errors that can occur during API interactions.
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case rateLimited
    case serverError(code: Int)
    case networkError(Error)
    case decodingError(Error)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Invalid response from server."
        case .rateLimited:
            return "Rate limit exceeded."
        case .serverError(let code):
            return "Server error with code: \(code)."
        case .networkError(let error):
            return error.localizedDescription
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}
