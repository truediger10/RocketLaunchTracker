// App/Config.swift

import Foundation

struct Config {
    static let shared = Config()
    
    let openAIAPIKey: String
    let spaceDevsAPIKey: String
    
    private init() {
        // Using environment variables for security
        openAIAPIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        spaceDevsAPIKey = ProcessInfo.processInfo.environment["SPACEDEVS_API_KEY"] ?? ""
        
        if openAIAPIKey.isEmpty || spaceDevsAPIKey.isEmpty {
            print("⚠️ Warning: API keys not found in environment variables")
        }
    }
}
