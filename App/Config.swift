import Foundation

/**
 A singleton configuration object that provides access to API keys and other sensitive data.
 
 `Config` retrieves values from environment variables during debug builds for convenience,
 and defaults to empty values for release builds, encouraging a more secure retrieval method
 (e.g., secure storage in Keychain or a managed secrets tool).
 
 - Properties:
    - openAIAPIKey: The API key for interacting with the OpenAI API.
    - spaceDevsAPIKey: The API key for interacting with the SpaceDevs API.
 
 **Note:**
 In production or release builds, API keys should not be hard-coded or stored in environment variables
 directly. Instead, consider using secure storage solutions or managed secrets in your CI/CD pipeline.
 */
struct Config {
    /// The shared, singleton instance of `Config`.
    static let shared = Config()
    
    /// The API key for the OpenAI API.
    let openAIAPIKey: String
    
    /// The API key for the SpaceDevs API.
    let spaceDevsAPIKey: String
    
    /**
     Initializes the configuration.
     
     In debug builds, keys are fetched from environment variables, allowing simple local testing.
     In release builds, defaults to empty strings, encouraging secure retrieval methods rather than
     relying on environment variables.
     */
    private init() {
        #if DEBUG
        // Load keys from environment variables for local/testing scenarios.
        openAIAPIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        spaceDevsAPIKey = ProcessInfo.processInfo.environment["SPACEDEVS_API_KEY"] ?? ""
        
        // Warn if keys are not found when running locally in debug mode.
        if openAIAPIKey.isEmpty || spaceDevsAPIKey.isEmpty {
            print("⚠️ Warning: API keys not found in environment variables.")
        }
        #else
        // In production builds, do not rely on environment variables.
        // Retrieve keys from secure storage or another secure mechanism.
        openAIAPIKey = ""
        spaceDevsAPIKey = ""
        #endif
    }
}
