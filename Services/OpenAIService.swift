import Foundation

/// Errors specific to OpenAI service calls.
enum OpenAIServiceError: Error {
    case invalidURL
    case invalidResponse
    case processingError
    case rateLimited
    case serverError(code: Int)
}

/// A service responsible for interacting with the OpenAI API to enrich launch descriptions.
actor OpenAIService {
    static let shared = OpenAIService()
    
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4"
    private let maxRetries = 3
    
    private let urlSession: URLSession
    
    private init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    /// Attempts to enrich a given SpaceDevsLaunch using OpenAI.
    /// Includes a retry mechanism with exponential backoff on network or server errors.
    func enrichLaunch(_ launch: SpaceDevsLaunch) async throws -> LaunchEnrichment {
        let systemPrompt = """
        You are a space mission analyst providing exciting descriptions of rocket launches.
        Create two descriptions for this launch:
        1. A short, engaging summary (max 150 characters)
        2. A detailed description (max 500 characters) including mission goals and significance
        Format the response as valid JSON with keys: "shortDescription" and "detailedDescription"
        """
        
        let userPrompt = """
        Launch Details:
        - Name: \(launch.name)
        - Provider: \(launch.launch_service_provider.name)
        - Rocket: \(launch.rocket.configuration.name)
        - Location: \(launch.pad.location.name)
        - Mission: \(launch.mission?.description ?? "No mission description available")
        """
        
        let request = OpenAIRequest(
            model: model,
            messages: [
                Message(role: "system", content: systemPrompt),
                Message(role: "user", content: userPrompt)
            ],
            temperature: 0.7,
            max_tokens: 1000
        )
        
        return try await sendRequestWithRetry(request: request, retries: maxRetries)
    }
    
    private func sendRequestWithRetry(request: OpenAIRequest, retries: Int) async throws -> LaunchEnrichment {
        var delay: UInt64 = 500_000_000 // 0.5 seconds
        var attempt = 1
        while true {
            do {
                return try await sendRequest(request)
            } catch let error as OpenAIServiceError {
                if attempt < retries {
                    print("🔄 OpenAI request failed (attempt \(attempt)): \(error). Retrying in \(delay/1_000_000_000)s...")
                    try await Task.sleep(nanoseconds: delay)
                    delay *= 2
                    attempt += 1
                } else {
                    print("❌ OpenAI request failed after \(attempt) attempts: \(error)")
                    throw error
                }
            } catch {
                if attempt < retries {
                    print("🔄 OpenAI unknown error (attempt \(attempt)): \(error). Retrying in \(delay/1_000_000_000)s...")
                    try await Task.sleep(nanoseconds: delay)
                    delay *= 2
                    attempt += 1
                } else {
                    print("❌ OpenAI unknown error after \(attempt) attempts: \(error)")
                    throw error
                }
            }
        }
    }
    
    private func sendRequest(_ request: OpenAIRequest) async throws -> LaunchEnrichment {
        guard let url = URL(string: endpoint) else {
            throw OpenAIServiceError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(Config.shared.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponse
        }
        
        print("🤖 OpenAI Status Code: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🤖 OpenAI Response: \(responseString)")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            switch httpResponse.statusCode {
            case 401:
                throw OpenAIServiceError.serverError(code: 401)
            case 429:
                throw OpenAIServiceError.rateLimited
            default:
                throw OpenAIServiceError.serverError(code: httpResponse.statusCode)
            }
        }
        
        let decoder = JSONDecoder()
        let openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content,
              let contentData = content.data(using: .utf8) else {
            throw OpenAIServiceError.processingError
        }
        
        do {
            return try decoder.decode(LaunchEnrichment.self, from: contentData)
        } catch {
            print("❌ Failed to decode enrichment: \(error)")
            // Provide a fallback in case parsing fails
            return LaunchEnrichment(
                shortDescription: "Launch of \(request.messages.last?.content ?? "unknown mission")",
                detailedDescription: content
            )
        }
    }
}

// MARK: - OpenAI Models
struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int
}

struct Message: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        let finish_reason: String?
    }
}
