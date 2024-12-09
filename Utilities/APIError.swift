import Foundation

/**
 An enumeration representing various errors that can occur while interacting with APIs.

 Conforms to `LocalizedError` to provide user-friendly descriptions that can be displayed directly
 in the UI. This helps ensure consistency and makes debugging easier by giving more context about
 what went wrong during network operations.
 
 - Cases:
    - `invalidURL`: The URL provided to the API call was malformed or invalid.
    - `invalidResponse`: The response from the server did not meet expected criteria (e.g., invalid JSON).
    - `unauthorized`: Credentials or tokens are missing or invalid, preventing authorized access.
    - `rateLimited`: Too many requests have been sent in a short period, causing the server to limit requests temporarily.
    - `serverError(code:)`: A server-side error occurred, returning a specific HTTP status code.
    - `networkError(Error)`: A general networking error occurred (e.g., no internet connection, DNS issues).
    - `processingError`: Data was received but could not be processed or parsed (e.g., decoding failure).
    - `dataConversionError`: Unable to convert the received data into the required format (e.g., image, JSON structure).
 */
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited
    case serverError(code: Int)
    case networkError(Error)
    case processingError
    case dataConversionError
    
    /// Provides a user-friendly description for each error case, suitable for display to end-users.
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The requested resource could not be accessed due to an invalid URL."
        case .invalidResponse:
            return "The server returned an unexpected or invalid response."
        case .unauthorized:
            return "You are not authorized to perform this request. Please check your credentials."
        case .rateLimited:
            return "You have made too many requests in a short period. Please try again later."
        case .serverError(let code):
            return "The server encountered an error (Code: \(code)). Please try again later."
        case .networkError(let error):
            return "A network error occurred: \(error.localizedDescription)"
        case .processingError:
            return "There was a problem processing the data from the server."
        case .dataConversionError:
            return "The received data could not be converted into the required format."
        }
    }
}
