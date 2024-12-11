// /Users/troyruediger/Desktop/RocketLaunchTracker/Models/SpaceDevsLaunch.swift

import Foundation

struct SpaceDevsLaunch: Codable, Identifiable {
    let id: String
    let name: String
    let status: Status
    let net: String
    let launchServiceProvider: LaunchServiceProvider
    let rocket: RocketInfo
    let pad: PadInfo
    let image: ImageData?
    let orbit: OrbitInfo?
    
    struct Status: Codable {
        let name: String
        let abbrev: String
    }
    
    struct LaunchServiceProvider: Codable {
        let name: String
    }
    
    struct RocketInfo: Codable {
        let configuration: RocketConfiguration
        
        struct RocketConfiguration: Codable {
            let name: String
            let fullName: String
            
            enum CodingKeys: String, CodingKey {
                case name
                case fullName = "full_name"
            }
        }
    }
    
    struct PadInfo: Codable {
        let name: String
        let location: Location
        let wikiURL: String?
        
        struct Location: Codable {
            let name: String
        }
        
        enum CodingKeys: String, CodingKey {
            case name
            case location
            case wikiURL = "wiki_url"
        }
    }
    
    struct ImageData: Codable {
        let imageURL: String?
        
        enum CodingKeys: String, CodingKey {
            case imageURL = "image_url"
        }
    }
    
    struct OrbitInfo: Codable {
        let name: String
    }
}
