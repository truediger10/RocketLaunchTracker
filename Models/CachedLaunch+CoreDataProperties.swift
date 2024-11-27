import Foundation
import CoreData

extension CachedLaunch {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedLaunch> {
        return NSFetchRequest<CachedLaunch>(entityName: "CachedLaunch")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var launchDate: String
    @NSManaged public var statusRawValue: String
    @NSManaged public var rocketName: String
    @NSManaged public var provider: String
    @NSManaged public var location: String
    @NSManaged public var imageURL: String?
    @NSManaged public var shortDescription: String?
    @NSManaged public var detailedDescription: String?
    @NSManaged public var wikiURL: String?
    @NSManaged public var missionType: String?
    @NSManaged public var orbit: String?
    @NSManaged public var providerStatsData: Data?
    @NSManaged public var padInfoData: Data?
    @NSManaged public var windowStart: String?
    @NSManaged public var windowEnd: String?
    @NSManaged public var probability: Int16
    @NSManaged public var weatherConcerns: String?
    @NSManaged public var videoURLsData: Data?
    @NSManaged public var infoURLsData: Data?
    @NSManaged public var imageCredit: String?
}

extension CachedLaunch: Identifiable {

}
