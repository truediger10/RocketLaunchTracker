//
//  OpenAIService.swift
//  RocketLaunchTracker
//
//  Uses GPT to enrich a single Launch. Actual caching is done by CacheManager.
//
import Foundation

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

/// A single shared actor that calls OpenAI to enrich Launch data.
actor OpenAIService: @unchecked Sendable {
    static let shared = OpenAIService()
    
    private enum Constants {
        static let endpoint = "https://api.openai.com/v1/chat/completions"
        static let model = "gpt-4"
        static let maxRetries = 3
        static let initialDelay: UInt64 = 500_000_000 // 0.5s
        static let maxDelay: UInt64 = 8_000_000_000   // 8s
    }
    
    private let urlSession: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        print("OpenAIService initialized")
    }
    
    /// Enrich a single Launch with additional textual details.
    func enrichLaunch(_ launch: Launch) async throws -> LaunchEnrichment {
        print("Enriching launch ID: \(launch.id) with OpenAI")
        
        let request = OpenAIRequest(
            model: Constants.model,
            messages: createPromptMessages(for: launch),
            temperature: 0.7,
            max_tokens: 500
        )
        
        do {
            let enrichment = try await sendRequestWithRetry(request: request, retries: Constants.maxRetries)
            print("Successfully enriched launch ID: \(launch.id)")
            return enrichment
        } catch {
            print("Failed to enrich launch ID: \(launch.id) with error: \(error)")
            throw error
        }
    }
    
    // MARK: - Private
    
    private func createPromptMessages(for launch: Launch) -> [Message] {
        let systemPrompt = """
        You are a space mission analyst. Given the raw launch details, generate JSON with keys:
          shortDescription (max 100 chars),
          detailedDescription (max 300 chars).
        Respond ONLY in JSON with exactly these keys.
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
    
    private func sendRequestWithRetry(request: OpenAIRequest, retries: Int) async throws -> LaunchEnrichment {
        var attempt = 1
        var delay = Constants.initialDelay
        
        while attempt <= retries {
            do {
                let enrichment = try await sendOpenAIRequest(request)
                return enrichment
            } catch OpenAIServiceError.rateLimited {
                if attempt == retries {
                    throw OpenAIServiceError.rateLimited
                }
                let jitter = UInt64.random(in: 0...100_000_000)
                let totalDelay = min(delay, Constants.maxDelay) + jitter
                print("Rate-limited by OpenAI. Retrying in \(Double(totalDelay)/1e9)s...")
                try await Task.sleep(nanoseconds: totalDelay)
                delay = min(delay * 2, Constants.maxDelay)
                attempt += 1
            }
        }
        
        throw OpenAIServiceError.rateLimited
    }
    
    private func sendOpenAIRequest(_ request: OpenAIRequest) async throws -> LaunchEnrichment {
        guard let url = URL(string: Constants.endpoint) else {
            throw OpenAIServiceError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        // If you have an API key set in Config, do:
        // urlRequest.setValue("Bearer \(Config.shared.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        try validate(response as? HTTPURLResponse)
        
        return try parseOpenAIResponse(data)
    }
    
    private func validate(_ response: HTTPURLResponse?) throws {
        guard let response = response else {
            throw OpenAIServiceError.invalidResponse
        }
        guard (200...299).contains(response.statusCode) else {
            switch response.statusCode {
            case 429:
                throw OpenAIServiceError.rateLimited
            default:
                let message = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
                throw OpenAIServiceError.serverError(code: response.statusCode, message: message)
            }
        }
    }
    
    private func parseOpenAIResponse(_ data: Data) throws -> LaunchEnrichment {
        do {
            let response = try decoder.decode(OpenAIResponse.self, from: data)
            guard let content = response.choices.first?.message.content,
                  let contentData = content.data(using: .utf8) else {
                throw OpenAIServiceError.processingError(detail: "Missing or invalid content in response")
            }
            let enrichment = try decoder.decode(LaunchEnrichment.self, from: contentData)
            return enrichment
        } catch {
            throw OpenAIServiceError.processingError(detail: "Failed to decode enrichment: \(error.localizedDescription)")
        }
    }
}

// MARK: - Models for OpenAI request/response
private struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int
}

private struct Message: Codable {
    let role: String
    let content: String
}

private struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        let finish_reason: String?
    }
}
