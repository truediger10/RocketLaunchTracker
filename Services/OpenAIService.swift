import Foundation

/// Handles interactions with the OpenAI API.
class OpenAIService: OpenAIServiceProtocol {
    static let shared = OpenAIService(apiKey: Config.shared.openAIAPIKey)
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    /// Enriches launch data using OpenAI's API.
    func enrichLaunch(launch: Launch) async throws -> LaunchEnrichment {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw APIError.invalidURL
        }

        let messages: [[String: String]] = [
            ["role": "system", "content": "Provide engaging summaries for space launches."],
            ["role": "user", "content": "Create short and detailed descriptions for \(launch.name)."]
        ]
        
        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": messages,
            "max_tokens": 500
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        // Ensure the HTTP response is valid
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(code: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let content = decodedResponse.choices.first?.message.content, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APIError.decodingError("Empty or invalid response content.")
        }

        // Assuming the content contains valid JSON for `LaunchEnrichment`
        guard let enrichmentData = try? JSONDecoder().decode(LaunchEnrichment.self, from: Data(content.utf8)) else {
            throw APIError.decodingError("Failed to decode enrichment data.")
        }

        return enrichmentData
    }
}
