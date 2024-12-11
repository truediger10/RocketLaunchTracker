// RocketLaunchTrackerTests/RocketLaunchTrackerTests.swift

import XCTest
@testable import RocketLaunchTracker

final class RocketLaunchTrackerTests: XCTestCase {

    func testSpaceDevsLaunchToLaunchMapping() throws {
        // Given
        let jsonData = """
        {
            "id": "launch123",
            "name": "Mission Alpha",
            "net": "2024-12-31T12:00:00Z",
            "status": {
                "id": 1,
                "name": "Go",
                "abbrev": "GO",
                "description": "Launch is ready to proceed."
            },
            "launch_service_provider": {
                "id": 101,
                "name": "SpaceX"
            },
            "rocket": {
                "configuration": {
                    "name": "Falcon 9",
                    "full_name": "Falcon 9 Block 5"
                }
            },
            "mission": {
                "name": "Alpha Mission",
                "description": "Test mission for new payload.",
                "type": "Test",
                "orbit": {
                    "name": "LEO"
                }
            },
            "pad": {
                "name": "Launch Complex 39A",
                "wiki_url": "https://en.wikipedia.org/wiki/Launch_Complex_39A",
                "location": {
                    "name": "Kennedy Space Center"
                }
            },
            "image": {
                "image_url": "https://example.com/image.jpg"
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let spaceDevsLaunch = try decoder.decode(SpaceDevsLaunch.self, from: jsonData)
        
        // When
        let launch = spaceDevsLaunch.toAppLaunch(withEnrichment: LaunchEnrichment(
            shortDescription: "A test mission to deploy new payloads.",
            detailedDescription: "Mission Alpha aims to test the deployment mechanisms of our new payload systems, ensuring reliability and efficiency for future missions.",
            status: LaunchStatus(statusName: "Go", abbreviation: "GO")
        ))
        
        // Then
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
        XCTAssertEqual(launch.orbit, "LEO")
        XCTAssertEqual(launch.wikiURL, "https://en.wikipedia.org/wiki/Launch_Complex_39A")
        XCTAssertNil(launch.twitterURL)
        XCTAssertTrue(launch.badges.isEmpty)
    }
}
