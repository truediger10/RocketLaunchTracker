import Foundation

actor OpenAIService {
    static let shared = OpenAIService()
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4"
    
    private init() {}
    
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
        
        return try await sendRequest(request)
    }
    
    private func sendRequest(_ request: OpenAIRequest) async throws -> LaunchEnrichment {
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(Config.shared.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            urlRequest.httpBody = try encoder.encode(request)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("🤖 OpenAI Status Code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🤖 OpenAI Response: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                switch httpResponse.statusCode {
                case 401: throw APIError.unauthorized
                case 429: throw APIError.rateLimited
                default: throw APIError.serverError(code: httpResponse.statusCode)
                }
            }
            
            let decoder = JSONDecoder()
            let openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)
            
            guard let content = openAIResponse.choices.first?.message.content,
                  let contentData = content.data(using: .utf8) else {
                throw APIError.processingError
            }
            
            do {
                return try decoder.decode(LaunchEnrichment.self, from: contentData)
            } catch {
                print("❌ Failed to decode enrichment: \(error)")
                return LaunchEnrichment(
                    shortDescription: "Launch of \(request.messages.last?.content ?? "unknown mission")",
                    detailedDescription: content
                )
            }
        } catch {
            print("❌ OpenAI request failed: \(error)")
            throw error
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
