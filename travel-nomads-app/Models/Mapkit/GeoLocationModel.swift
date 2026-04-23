//
//  GeoLocationModel.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 07/04/2026.
//

import Foundation
import SwiftData

// USAGE: Main map search data structure
// Parent - city child - POIs
// One to many city to many POIs
// One to one - POI to city

// Enum for location type to avoid ambiguity
// as location is used both as a city and point of interest
enum LocationType: String, Codable, CaseIterable {
    case city
    case poi
}

@Model
class GeoLocationModel: Identifiable, Equatable {
    @Attribute(.unique) var id: UUID = UUID()  // ensures unique ID for SwiftUI
    var locationName: String
    var latitude: Double
    var longitude: Double
    var locationType: LocationType //enum removes ambiguity and ensures type safety
    
    // Wikipedia metadata
    var wikipediaPageID: Int?
    var wikipediaTitle: String?
    var thumbnailURLString: String?
    
    // MARK: Add parent-child relationships - points of interest for a city
    @Relationship(inverse: \GeoLocationModel.pointsOfInterest)
    var parentCity: GeoLocationModel?
    // Allows clean removal of all information associated with the POI if removed 
    @Relationship(deleteRule: .cascade)
    var pointsOfInterest: [GeoLocationModel] = []
    
    init(id: UUID = UUID(), locationName: String, latitude: Double, longitude: Double, locationType: LocationType = .city, parentCity: GeoLocationModel? = nil, wikipediaPageID: Int? = nil, wikipediaTitle: String? = nil, thumbnailURLString: String? = nil) {
        self.id = id
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.locationType = locationType
        self.parentCity = parentCity
        self.pointsOfInterest = []
        // Added for wiki data
        self.wikipediaPageID = wikipediaPageID
        self.wikipediaTitle = wikipediaTitle
        self.thumbnailURLString = thumbnailURLString
    }
}

