import XCTest
@testable import RocketLaunchTracker

final class RocketLaunchTrackerTests: XCTestCase {

    func testSpaceDevsLaunchToLaunchMapping() throws {
        // Given: A sample JSON response (list mode)
        let jsonData = """
        {
            "id": "launch123",
            "name": "Mission Alpha",
            "net": "2024-12-31T12:00:00Z",
            "status": {
                "name": "Go",
                "abbrev": "GO"
            },
            "launch_service_provider": {
                "name": "SpaceX"
            },
            "rocket": {
                "configuration": {
                    "full_name": "Falcon 9 Block 5"
                }
            },
            "mission": {
                "description": "Test mission for new payload."
            },
            "pad": {
                "location": "Kennedy Space Center",
                "wiki_url": "https://en.wikipedia.org/wiki/Launch_Complex_39A"
            },
            "image": {
                "image_url": "https://example.com/image.jpg"
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let spaceDevsLaunch = try decoder.decode(SpaceDevsLaunch.self, from: jsonData)
        
        // When: Mapping to our internal Launch model using an enrichment object.
        let enrichment = LaunchEnrichment(
            shortDescription: "A test mission to deploy new payloads.",
            detailedDescription: "Mission Alpha aims to test the deployment mechanisms of our new payload systems, ensuring reliability and efficiency for future missions."
        )
        let launch = spaceDevsLaunch.toAppLaunch(withEnrichment: enrichment)
        
        // Then: Verify that fields map correctly.
        XCTAssertEqual(launch.id, "launch123")
        XCTAssertEqual(launch.name, "Mission Alpha")
        XCTAssertEqual(launch.status.statusName, "Go")
        XCTAssertEqual(launch.status.abbreviation, "GO")
        XCTAssertEqual(launch.rocket, "Falcon 9 Block 5")
        XCTAssertEqual(launch.provider, "SpaceX")
        XCTAssertEqual(launch.location, "Kennedy Space Center")
        XCTAssertEqual(launch.imageURL, "https://example.com/image.jpg")
        XCTAssertEqual(launch.shortDescription, "A test mission to deploy new payloads.")
        XCTAssertEqual(launch.detailedDescription, "Mission Alpha aims to test the deployment mechanisms of our new payload systems, ensuring reliability and efficiency for future missions.")
        XCTAssertNil(launch.orbit) // No orbit data provided in JSON.
        XCTAssertEqual(launch.wikiURL, "https://en.wikipedia.org/wiki/Launch_Complex_39A")
        XCTAssertEqual(launch.twitterURL, "https://twitter.com/search?q=Mission%20Alpha")
        XCTAssertTrue(launch.badges?.isEmpty ?? true)
    }
}
