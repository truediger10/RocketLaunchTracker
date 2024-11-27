import Foundation

extension SpaceDevsLaunch {
    func toAppLaunch(withEnrichment enrichment: LaunchEnrichment?) -> Launch {
        let launchStatus = LaunchStatus(statusName: status.name)
        let padInfo = PadInfo(
            name: pad.name,
            location: pad.location.name,
            countryCode: pad.location.countryCode
        )

        return Launch(
            id: id,
            name: name,
            launchDate: net,
            status: launchStatus,
            rocketName: rocket.configuration.name,
            provider: "Unknown", // Update if provider information is available
            location: pad.location.name,
            imageURL: imageURL ?? image,
            shortDescription: enrichment?.shortDescription,
            detailedDescription: enrichment?.detailedDescription,
            wikiURL: nil, // Update if wikiURL is available
            missionType: mission?.type,
            orbit: mission?.orbit?.name,
            providerStats: nil, // Update if providerStats are available
            padInfo: padInfo,
            windowStart: nil, // Update if windowStart is available
            windowEnd: nil,   // Update if windowEnd is available
            probability: nil, // Update if probability is available
            weatherConcerns: nil, // Update if weatherConcerns are available
            videoURLs: vidURLs,
            infoURLs: infoURLs,
            imageCredit: nil // Update if imageCredit is available
        )
    }
}
