import Foundation

protocol OpenAIServiceProtocol {
    func enrichLaunch(launch: Launch) async throws -> LaunchEnrichment
}
