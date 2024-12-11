// Models/APIError.swift

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case rateLimited(retryAfter: TimeInterval, message: String)
    case serverError(code: Int, message: String)
    case launchNotFound
    case decodingError(underlying: Error, data: String?)
    case networkError(underlying: URLError)
    case unknownError
    case invalidAPIKey
    case noData
    case parsingError(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .rateLimited(let retryAfter, let message):
            return "Rate limited: \(message). Retry after \(Int(retryAfter)) seconds."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .launchNotFound:
            return "The requested launch was not found."
        case .decodingError(let error, let data):
            let dataInfo = data.map { "\nResponse data: \($0)" } ?? ""
            return "Failed to decode the response: \(error.localizedDescription)\(dataInfo)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknownError:
            return "An unknown error occurred."
        case .invalidAPIKey:
            return "The provided API key is invalid or missing."
        case .noData:
            return "No data received from the server."
        case .parsingError(let message):
            return "Failed to parse response: \(message)"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .rateLimited, .networkError, .serverError:
            return true
        default:
            return false
        }
    }

    var retryDelay: TimeInterval? {
        switch self {
        case .rateLimited(let delay, _):
            return delay
        case .networkError:
            return 1.0
        case .serverError:
            return 2.0
        default:
            return nil
        }
    }
}
