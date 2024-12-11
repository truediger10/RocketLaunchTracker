// Services/OpenAIService.swift

import Foundation

/// Errors specific to OpenAI service interactions.
enum OpenAIServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case processingError(detail: String)
    case rateLimited
    case serverError(code: Int, message: String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration."
        case .invalidResponse:
            return "Invalid response from server."
        case .processingError(let detail):
            return "Processing error: \(detail)."
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)."
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}

/// Service responsible for enriching launch data using OpenAI.
actor OpenAIService: @unchecked Sendable {
    // MARK: - Constants
    static let shared = OpenAIService()
    
    private enum Constants {
        static let endpoint = "https://api.openai.com/v1/chat/completions"
        static let model = "gpt-4"
        static let maxRetries = 3
        static let initialDelay: UInt64 = 500_000_000 // 0.5 seconds
        static let maxDelay: UInt64 = 8_000_000_000 // 8 seconds
    }
    
    // MARK: - Properties
    private let urlSession: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var enrichmentCache: [String: LaunchEnrichment] = [:]
    
    // MARK: - Initialization
    private init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        print("OpenAIService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Enriches a launch with additional descriptive information using OpenAI.
    /// - Parameter launch: The launch to enrich.
    /// - Returns: An enriched `LaunchEnrichment` object.
    func enrichLaunch(_ launch: Launch) async throws -> LaunchEnrichment {
        print("Enriching launch ID: \(launch.id) with OpenAI")
        
        if let cached = enrichmentCache[launch.id] {
            print("Retrieved enrichment from in-memory cache for launch ID: \(launch.id)")
            return cached
        }
        
        let request = OpenAIRequest(
            model: Constants.model,
            messages: createPromptMessages(for: launch),
            temperature: 0.7,
            max_tokens: 500
        )
        
        do {
            let enrichment = try await sendRequestWithRetry(request: request, retries: Constants.maxRetries)
            enrichmentCache[launch.id] = enrichment
            print("Successfully enriched launch ID: \(launch.id)")
            return enrichment
        } catch {
            print("Failed to enrich launch ID: \(launch.id) with error: \(error)")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    /// Creates the prompt messages for the OpenAI API based on launch details.
    /// - Parameter launch: The launch to create prompts for.
    /// - Returns: An array of `Message` objects.
    private func createPromptMessages(for launch: Launch) -> [Message] {
        let systemPrompt = """
        You are a space mission analyst providing exciting descriptions of rocket launches.
        Create two descriptions, with strict character limits:
        1. Short summary (max 100 chars) capturing mission essence
        2. Detailed overview (max 300 chars) including goals and specifications
        
        Format response as JSON:
        {
            "shortDescription": "Brief mission summary here",
            "detailedDescription": "Comprehensive mission details here"
        }
        """
        
        let userPrompt = """
        Launch Details:
        - Name: \(launch.name)
        - Provider: \(launch.provider)
        - Rocket: \(launch.rocketName)
        - Location: \(launch.location)
        - Orbit: \(launch.orbit ?? "N/A")
        - Date: \(launch.formattedDate)
        """
        
        return [
            Message(role: "system", content: systemPrompt),
            Message(role: "user", content: userPrompt)
        ]
    }
    
    /// Sends a request to the OpenAI API with retry logic.
    /// - Parameters:
    ///   - request: The `OpenAIRequest` to send.
    ///   - retries: The number of retry attempts.
    /// - Returns: A `LaunchEnrichment` object.
    private func sendRequestWithRetry(request: OpenAIRequest, retries: Int) async throws -> LaunchEnrichment {
        var delay = Constants.initialDelay
        var attempt = 1
        
        while attempt <= retries {
            do {
                print("Sending OpenAI request. Attempt \(attempt)")
                let enrichment = try await sendOpenAIRequest(request)
                print("OpenAI request successful on attempt \(attempt)")
                return enrichment
            } catch OpenAIServiceError.rateLimited {
                print("OpenAI rate limited on attempt \(attempt)")
                if attempt == retries {
                    throw OpenAIServiceError.rateLimited
                }
                print("Retrying after \(Double(delay) / 1_000_000_000) seconds...")
                try await executeRetryDelay(attempt: attempt, delay: delay)
                delay = min(delay * 2, Constants.maxDelay)
                attempt += 1
            } catch {
                print("OpenAI request failed on attempt \(attempt) with error: \(error)")
                throw error
            }
        }
        throw OpenAIServiceError.rateLimited
    }
    
    /// Executes a delay before retrying a request.
    /// - Parameters:
    ///   - attempt: The current attempt number.
    ///   - delay: The delay duration in nanoseconds.
    private func executeRetryDelay(attempt: Int, delay: UInt64) async throws {
        let jitter = UInt64.random(in: 0...100_000_000)
        let totalDelay = min(delay, Constants.maxDelay) + jitter
        print("Waiting for \(Double(totalDelay) / 1_000_000_000) seconds before retrying...")
        try await Task.sleep(nanoseconds: totalDelay)
    }
    
    /// Sends a request to the OpenAI API.
    /// - Parameter request: The `OpenAIRequest` to send.
    /// - Returns: A `LaunchEnrichment` object.
    private func sendOpenAIRequest(_ request: OpenAIRequest) async throws -> LaunchEnrichment {
        guard let url = URL(string: Constants.endpoint) else {
            print("Invalid OpenAI URL: \(Constants.endpoint)")
            throw OpenAIServiceError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(Config.shared.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)
        
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            try validateResponse(response as? HTTPURLResponse)
            let enrichment = try parseOpenAIResponse(data)
            return enrichment
        } catch {
            print("Error during OpenAI request: \(error)")
            throw error
        }
    }
    
    /// Validates the HTTP response from the OpenAI API.
    /// - Parameter response: The `HTTPURLResponse` to validate.
    private func validateResponse(_ response: HTTPURLResponse?) throws {
        guard let response = response else {
            print("No HTTP response received from OpenAI API")
            throw OpenAIServiceError.invalidResponse
        }
        
        guard (200...299).contains(response.statusCode) else {
            switch response.statusCode {
            case 429:
                print("OpenAI API rate limited with status code: 429")
                throw OpenAIServiceError.rateLimited
            default:
                let message = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
                print("OpenAI API server error with status code: \(response.statusCode), message: \(message)")
                throw OpenAIServiceError.serverError(code: response.statusCode, message: message)
            }
        }
    }
    
    /// Parses the response data from the OpenAI API into a `LaunchEnrichment` object.
    /// - Parameter data: The response `Data` from the API.
    /// - Returns: A `LaunchEnrichment` object.
    private func parseOpenAIResponse(_ data: Data) throws -> LaunchEnrichment {
        do {
            let response = try decoder.decode(OpenAIResponse.self, from: data)
            guard let content = response.choices.first?.message.content,
                  let contentData = content.data(using: .utf8) else {
                print("Invalid content in OpenAI response")
                throw OpenAIServiceError.processingError(detail: "Missing or invalid content in response")
            }
            
            let enrichment = try decoder.decode(LaunchEnrichment.self, from: contentData)
            return enrichment
        } catch {
            print("Failed to parse OpenAI response with error: \(error)")
            throw OpenAIServiceError.processingError(detail: "Failed to decode enrichment: \(error.localizedDescription)")
        }
    }
}

// MARK: - Models

/// Represents a request to the OpenAI API.
private struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int
}

/// Represents a message in the OpenAI chat.
private struct Message: Codable {
    let role: String
    let content: String
}

/// Represents the response from the OpenAI API.
private struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        let finish_reason: String?
    }
}
