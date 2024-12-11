// Config/Config.swift

import Foundation

struct Config {
    enum ConfigError: LocalizedError {
        case missingAPIKey(String)
        
        var errorDescription: String? {
            switch self {
            case .missingAPIKey(let key):
                return "Missing required API key: \(key)"
            }
        }
    }
    
    static let shared = Config()
    
    var openAIAPIKey: String
    let spaceDevsAPIKey: String
    let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    let maxRetries: Int = 3
    
    private init() {
        func getEnvironmentVariable(_ key: String) throws -> String {
            // Use debug keys in development
            #if DEBUG
            let debugKeys = [
                "OPENAI_API_KEY": "sk-debug",
                "SPACEDEVS_API_KEY": "debug-key"
            ]
            if let debugValue = debugKeys[key] {
                return debugValue
            }
            #endif
            
            guard let value = ProcessInfo.processInfo.environment[key],
                  !value.isEmpty else {
                throw ConfigError.missingAPIKey(key)
            }
            return value
        }
        
        do {
            self.openAIAPIKey = try getEnvironmentVariable("OPENAI_API_KEY")
            self.spaceDevsAPIKey = try getEnvironmentVariable("SPACEDEVS_API_KEY")
        } catch {
            #if DEBUG
            print("⚠️ Using debug API keys: \(error.localizedDescription)")
            self.openAIAPIKey = "sk-debug"
            self.spaceDevsAPIKey = "debug-key"
            #else
            fatalError("\(error.localizedDescription)")
            #endif
        }
    }
}
