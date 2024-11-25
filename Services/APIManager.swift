import Foundation

actor APIManager {
    static let shared = APIManager()
    private let baseURL = "https://ll.thespacedevs.com/2.3.0/launches/upcoming/?limit=10"
    private let cache = CacheManager.shared
    private let openAIService = OpenAIService.shared
    
    private init() {}
    
    func fetchLaunches() async throws -> [Launch] {
        print("🚀 Fetching launches...")
        
        if let cachedLaunches = await cache.getCachedLaunches() {
            print("📦 Retrieved \(cachedLaunches.count) launches from cache")
            return cachedLaunches
        }
        
        print("🌐 Fetching upcoming launches from API...")
        
        guard let url = URL(string: baseURL) else {
            print("❌ Invalid URL: \(baseURL)")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("🔵 Status Code: \(httpResponse.statusCode)")
            
            if (200...299).contains(httpResponse.statusCode) {
                let decoder = JSONDecoder()
                let spaceDevsResponse = try decoder.decode(SpaceDevsResponse.self, from: data)
                print("✅ Decoded \(spaceDevsResponse.results.count) launches")
                
                var enrichedLaunches: [Launch] = []
                
                for spaceDevsLaunch in spaceDevsResponse.results {
                    if let cachedEnrichment = await cache.getCachedEnrichment(for: spaceDevsLaunch.id) {
                        print("🧠 Using cached enrichment for launch \(spaceDevsLaunch.id)")
                        enrichedLaunches.append(spaceDevsLaunch.toAppLaunch(withEnrichment: cachedEnrichment))
                    } else {
                        do {
                            let enrichment = try await openAIService.enrichLaunch(spaceDevsLaunch)
                            await cache.cacheEnrichment(enrichment, for: spaceDevsLaunch.id)
                            enrichedLaunches.append(spaceDevsLaunch.toAppLaunch(withEnrichment: enrichment))
                        } catch {
                            print("⚠️ Enrichment failed for launch \(spaceDevsLaunch.id): \(error)")
                            enrichedLaunches.append(spaceDevsLaunch.toAppLaunch())
                        }
                    }
                }
                
                print("⭐️ Converted to app launches")
                await cache.cacheLaunches(enrichedLaunches)
                print("📱 Received \(enrichedLaunches.count) launches")
                return enrichedLaunches
                
            } else {
                throw APIError.serverError(code: httpResponse.statusCode)
            }
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
}
