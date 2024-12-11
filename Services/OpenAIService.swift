// Services/OpenAIService.swift

import Foundation

/// Errors specific to OpenAI service interactions.
enum OpenAIServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case processingError(detail: String)
    case rateLimited
    case serverError(code: Int, message: String)
    case timeout
    case unexpectedFormat
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
        case .timeout:
            return "The request timed out."
        case .unexpectedFormat:
            return "The response format was unexpected."
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}

/**
 Service responsible for enriching launch data using OpenAI.
 */
actor OpenAIService {
    // MARK: - Constants
    static let shared = OpenAIService()

    private enum Constants {
        static let endpoint = "https://api.openai.com/v1/chat/completions"
        static let model = "gpt-4"
        static let enrichmentTimeout: TimeInterval = 10 // 10 seconds
    }

    // MARK: - Properties
    private let urlSession: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let cache: CacheManager

    // MARK: - Initialization
    private init(urlSession: URLSession = .shared, cache: CacheManager = .shared) {
        self.urlSession = urlSession
        self.cache = cache
        // Initialization log without exposing API keys
        print("🔧 OpenAIService initialized")
    }

    // MARK: - Public Methods
    /**
     Enriches a launch with additional descriptive information using OpenAI.

     - Parameter launch: The `Launch` instance to enrich.
     - Returns: A `LaunchEnrichment` containing enhanced descriptions.
     - Throws: `OpenAIServiceError` if enrichment fails.
     */
    func enrichLaunch(_ launch: Launch) async throws -> LaunchEnrichment {
        // Check if enrichment is already cached
        if let cached = await cache.getCachedEnrichment(for: launch.id) {
            print("💾 Using cached enrichment for launch: \(launch.name)")
            return cached
        }

        // Create OpenAI request
        let request = OpenAIRequest(
            model: Constants.model,
            messages: createPromptMessages(for: launch),
            temperature: 0.7,
            max_tokens: 500
        )

        // Execute request with timeout
        let enrichment = try await withTimeout(Constants.enrichmentTimeout) {
            try await self.sendOpenAIRequest(request)
        }

        // Cache the enrichment
        await cache.cacheEnrichment(enrichment, for: launch.id)

        print("✅ Enrichment successful for launch: \(launch.name)")
        return enrichment
    }

    // MARK: - Private Methods
    /// Creates prompt messages for OpenAI based on launch details.
    private func createPromptMessages(for launch: Launch) -> [Message] {
        let systemPrompt = """
        You are a knowledgeable space mission analyst. Create engaging descriptions for a rocket launch using any available information.
        Even with minimal data, provide informative descriptions based on the launch provider, rocket type, and similar historical missions.

        Rules:
        1. Never mention "unknown payload" or "details TBD"
        2. For classified missions, focus on the rocket and provider capabilities
        3. Use technical knowledge to make educated guesses about mission type based on orbit and launch site
        4. Keep short description under 100 characters
        5. Keep detailed description under 300 characters
        6. Always be accurate but engaging

        Format response strictly as JSON:
        {
            "shortDescription": "Brief mission summary",
            "detailedDescription": "Comprehensive overview"
        }
        """

        let context = buildLaunchContext(launch)

        return [
            Message(role: "system", content: systemPrompt),
            Message(role: "user", content: context)
        ]
    }

    /// Builds the context string for the OpenAI prompt based on launch details.
    private func buildLaunchContext(_ launch: Launch) -> String {
        return """
        Launch Details:
        - Mission: \(launch.name)
        - Provider: \(launch.provider)
        - Rocket: \(launch.rocketName)
        - Location: \(launch.location)
        - Orbit: \(launch.orbit ?? "Not specified")
        - Date: \(launch.formattedDate)

        Provider Context: \(getProviderInfo(launch.provider))
        Launch Site: \(getLaunchSiteInfo(launch.location))
        Mission Type Hints: \(getMissionTypeHints(launch))
        """
    }

    /// Provides contextual information about the launch provider.
    private func getProviderInfo(_ provider: String) -> String {
        switch provider.lowercased() {
        case let p where p.contains("spacex"):
            return "Commercial provider known for reusable rockets and Starlink missions"
        case let p where p.contains("nasa"):
            return "US space agency focused on exploration and scientific research"
        case let p where p.contains("roscosmos"):
            return "Russian space agency with extensive launch history"
        case let p where p.contains("rocket lab"):
            return "Specialized in small satellite launches with high frequency"
        default:
            return "Active launch provider in the space industry"
        }
    }

    /// Provides contextual information about the launch site.
    private func getLaunchSiteInfo(_ location: String) -> String {
        switch location.lowercased() {
        case let l where l.contains("kennedy"):
            return "Historic Florida launch site suitable for all orbits"
        case let l where l.contains("vandenberg"):
            return "California site specialized for polar orbits"
        case let l where l.contains("baikonur"):
            return "Kazakhstan-based site with long history of crewed launches"
        default:
            return "Operational spaceport supporting orbital launches"
        }
    }

    /// Provides hints about the mission type based on launch name and orbit.
    private func getMissionTypeHints(_ launch: Launch) -> String {
        let name = launch.name.lowercased()
        let orbit = launch.orbit?.lowercased() ?? ""

        switch true {
        case name.contains("starlink"):
            return "Internet satellite constellation deployment"
        case name.contains("crew"):
            return "Human spaceflight mission"
        case name.contains("cargo"):
            return "Space station resupply mission"
        case orbit.contains("geo"):
            return "Likely communications or weather satellite"
        case orbit.contains("leo"):
            return "Earth observation or communications mission"
        default:
            return "Orbital space mission"
        }
    }

    /// Sends the OpenAI request and parses the response.
    private func sendOpenAIRequest(_ request: OpenAIRequest) async throws -> LaunchEnrichment {
        guard let url = URL(string: Constants.endpoint) else {
            throw OpenAIServiceError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(Config.shared.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode request
        do {
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            throw OpenAIServiceError.processingError(detail: "Failed to encode request: \(error.localizedDescription)")
        }

        // Send request
        let (data, response) = try await urlSession.data(for: urlRequest)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            switch httpResponse.statusCode {
            case 429:
                throw OpenAIServiceError.rateLimited
            case 408, 504:
                throw OpenAIServiceError.timeout
            default:
                let message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                throw OpenAIServiceError.serverError(code: httpResponse.statusCode, message: message)
            }
        }

        // Decode response
        let openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)
        guard let content = openAIResponse.choices.first?.message.content else {
            throw OpenAIServiceError.unexpectedFormat
        }

        // Parse JSON from content
        guard let contentData = content.data(using: .utf8) else {
            throw OpenAIServiceError.unexpectedFormat
        }

        let enrichment = try decoder.decode(LaunchEnrichment.self, from: contentData)
        return enrichment
    }

    /// Executes an asynchronous operation with a timeout.
    private func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw OpenAIServiceError.timeout
            }

            guard let result = try await group.next() else {
                throw OpenAIServiceError.timeout
            }

            group.cancelAll()
            return result
        }
    }

    /// Generates fallback enrichment data if OpenAI enrichment fails.
    private func generateFallbackEnrichment(for launch: Launch) -> LaunchEnrichment {
        let shortDesc = "\(launch.provider) launch of \(launch.rocketName) from \(launch.location)."
        let detailedDesc = """
            \(launch.provider) is conducting a launch of their \(launch.rocketName) rocket from \(launch.location). \
            This mission demonstrates the provider's ongoing commitment to space access and technological advancement.
            """

        return LaunchEnrichment(
            shortDescription: String(shortDesc.prefix(100)),
            detailedDescription: String(detailedDesc.prefix(300))
        )
    }

    // MARK: - Models

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
}
