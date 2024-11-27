import Foundation
import CoreData

extension CachedLaunch {
    func toLaunch() -> Launch {
        let providerStats = providerStatsData != nil ? try? JSONDecoder().decode(ProviderStats.self, from: providerStatsData!) : nil
        let padInfo = padInfoData != nil ? try? JSONDecoder().decode(PadInfo.self, from: padInfoData!) : nil
        let videoURLs = videoURLsData != nil ? try? JSONDecoder().decode([String].self, from: videoURLsData!) : nil
        let infoURLs = infoURLsData != nil ? try? JSONDecoder().decode([String].self, from: infoURLsData!) : nil
        let status = LaunchStatus(rawValue: statusRawValue) ?? .other

        return Launch(
            id: id,
            name: name,
            launchDate: launchDate,
            status: status,
            rocketName: rocketName,
            provider: provider,
            location: location,
            imageURL: imageURL,
            shortDescription: shortDescription,
            detailedDescription: detailedDescription,
            wikiURL: wikiURL,
            missionType: missionType,
            orbit: orbit,
            providerStats: providerStats,
            padInfo: padInfo,
            windowStart: windowStart,
            windowEnd: windowEnd,
            probability: Int(probability),
            weatherConcerns: weatherConcerns,
            videoURLs: videoURLs,
            infoURLs: infoURLs,
            imageCredit: imageCredit
        )
    }

    func update(from launch: Launch) {
        id = launch.id
        name = launch.name
        launchDate = launch.launchDate!
        statusRawValue = launch.status.rawValue
        rocketName = launch.rocketName
        provider = launch.provider
        location = launch.location
        imageURL = launch.imageURL
        shortDescription = launch.shortDescription
        detailedDescription = launch.detailedDescription
        wikiURL = launch.wikiURL
        missionType = launch.missionType
        orbit = launch.orbit
        providerStatsData = launch.providerStats != nil ? try? JSONEncoder().encode(launch.providerStats) : nil
        padInfoData = launch.padInfo != nil ? try? JSONEncoder().encode(launch.padInfo) : nil
        windowStart = launch.windowStart
        windowEnd = launch.windowEnd
        probability = Int16(launch.probability ?? 0)
        weatherConcerns = launch.weatherConcerns
        videoURLsData = launch.videoURLs != nil ? try? JSONEncoder().encode(launch.videoURLs) : nil
        infoURLsData = launch.infoURLs != nil ? try? JSONEncoder().encode(launch.infoURLs) : nil
        imageCredit = launch.imageCredit
    }
}
