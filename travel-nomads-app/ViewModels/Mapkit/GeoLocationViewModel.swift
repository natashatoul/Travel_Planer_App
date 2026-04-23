//
//  GeoLocationViewModel.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 07/04/2026.
//

import Foundation
import SwiftData
import MapKit
import CoreLocation
import Combine

// USAGE: View map, search for cities and mark points of interest
// Debugging with Claude - marked where used

@MainActor
class GeoLocationViewModel: ObservableObject {
    //    MARK: local state variables
    // General Map - search and save city locations
    @Published var geoLocation: [GeoLocationModel] = []
    @Published var mapRegion: MKCoordinateRegion
    @Published var searchResults: [GeoLocationModel] = []
    // POIs - 5 suggested (preset) and others can be added and marked
    @Published var markedPOIs: [GeoLocationModel] = []
    @Published private(set) var presetPOIs: [GeoLocationModel] = []
    @Published var discoveredPOIs: [GeoLocationModel] = []
    @Published var currentCitySavedPOIs: [GeoLocationModel] = []
    // Local state vars not to be saved in Swift Data or DBs
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    // MARK: Intialise the controller with default location (central London)
    private var controller: LocationController
    init(controller: LocationController) {
        self.controller = controller
        // Initialise to London coordinates - single source of truth for default location
        let londonCoordinate = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        self.mapRegion = MKCoordinateRegion(
            center: londonCoordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
    }
    
    // MARK: Business logic - functions that update local state
    // Search for cities on the search bar
    func searchLocations(query: String) async {
        guard !query.isEmpty else {
            geoLocation = []
            return
        }
        // Change based on ui
        isSearching = true
        geoLocation = [] // clean old search
        errorMessage = nil
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        // Map initialised to London but local UI
        // requires region to change when user types Paris, Rome etc
        // This is commented out to prevent this blocking behaviour (Claude)
        // searchRequest.region = mapRegion
        
        
        // global search - worldwide
        searchRequest.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
            )
        
        let search = MKLocalSearch(request: searchRequest)
        // Async call to Mapkit API
        do {
            let response = try await search.start()
            // Convert search results using the modern MKMapItem location API
            geoLocation = response.mapItems.compactMap { item in
                let coordinate = item.location.coordinate
                guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
                return GeoLocationModel(
                    locationName: item.name ?? "Unknown Location",
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    locationType: .city
                )
            }
            
            // Zoom to first result if available
            if let firstResult = geoLocation.first {
                centerMap(on: firstResult)
            }
            
        } catch {
            print("Search error: \(error.localizedDescription)")
            geoLocation = []
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
        
        // Set back to false as user completes search on pressing enter
        isSearching = false
    }
    
    // Method to mark the centre of the city searched and search 1km distance
    func centerMap(on location: GeoLocationModel) {
        mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
    }
    
    // Update local state to save the location and navigate to the next page
    func saveLocation(_ location: GeoLocationModel) {
        controller.saveLocation(location)
    }
    
    func isSaved(_ location: GeoLocationModel) -> Bool {
        return controller.isSaved(location)
    }
    
    func toggleSave(_ location: GeoLocationModel) {
        controller.toggleSave(location)
    }
    
    func deleteLocation(_ location: GeoLocationModel) {
        controller.deleteLocation(location)
    }
    // MARK: Places of interest (POIs) business logic functions
    
    // Once city is chosen, mark places of interest
    func reloadCurrentCityPOIs(for city: GeoLocationModel) {
        currentCitySavedPOIs = controller.savedLocations.filter {
            $0.parentCity?.id == city.id && $0.locationType == .poi
        }
        // Load saved POIs into markedPOIs to show on map
//        markedPOIs = currentCitySavedPOIs
//        print("[DEBUG] Loaded \(markedPOIs.count) saved POIs into markedPOIs for display")
    }
    
    // Check if a POI is saved
    func isPOISaved(_ poi: GeoLocationModel) -> Bool {
        controller.isSaved(poi)
    }
    
    // Save a POI under a city
//    func savePOI(_ poi: GeoLocationModel, underCity city: GeoLocationModel) {
//        // POI should already have correct locationType and parentCity from creation
//        let alreadySaved = currentCitySavedPOIs.contains {
//            $0.locationName == poi.locationName
//        }
//        guard !alreadySaved else {
//            print("[DEBUG] POI '\(poi.locationName)' already saved, skipping")
//            return
//        }
//        
//        if !controller.isSaved(city) {
//            controller.saveLocation(city)
//        }
//        poi.locationType = .poi
//        poi.parentCity = city
//        controller.saveLocation(poi)
//        reloadCurrentCityPOIs(for: city)
//    }
    func savePOI(_ poi: GeoLocationModel, underCity city: GeoLocationModel) {
        // POI should already have correct locationType and parentCity from creation
        controller.saveLocation(poi)
        reloadCurrentCityPOIs(for: city)
    }
    
    // Delete a POI
    func deletePOI(_ poi: GeoLocationModel) {
        controller.deleteLocation(poi)
        if let city = poi.parentCity {
            reloadCurrentCityPOIs(for: city)
        }
    }
    
    // Discover preset POIs (max 5, unique in a 1km radius)
    func discoverPOIs(for city: GeoLocationModel) async {
        mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude),
            latitudinalMeters: 2000,
            longitudinalMeters: 2000
        )
        let request = MKLocalSearch.Request()
        //         Note - this returned shops and restaurants - filter had to be set
        request.naturalLanguageQuery = "tourist places"
        request.region = mapRegion
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            let uniquePOIs = response.mapItems.compactMap { item -> GeoLocationModel? in
                let coordinate = item.location.coordinate
                guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
                return GeoLocationModel(
                    locationName: item.name ?? "Unknown Place",
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    locationType: .poi,
                    parentCity: city
                )
            }
            // Only keep unique POIs by name and coordinates
            var seen = Set<String>()
            let filtered = uniquePOIs.filter { poi in
                let key = "\(poi.locationName)-\(poi.latitude)-\(poi.longitude)"
                if seen.contains(key) { return false }
                seen.insert(key)
                return true
            }
            presetPOIs = Array(filtered.prefix(15))
            //presetPOIs = filtered
            print("🔍 Discovered preset POIs: \(presetPOIs.map { $0.locationName })")
        } catch {
            print("❌ Error discovering POIs: \(error.localizedDescription)")
            presetPOIs = []
            errorMessage = "Failed to discover places: \(error.localizedDescription)"
        }
    }
    
    // Manual search for POIs (filtered for landmarks and tourist places)
    func searchPOIs(query: String, in city: GeoLocationModel) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        
        // Filter to show only landmarks, museums, and tourist attractions (Claude)
        searchRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: [
            .museum,
            .nationalPark,
            .park,
            .theater,
            .movieTheater,
            .aquarium,
            .zoo,
            .stadium,
            .castle,
            .fortress,
            .landmark
        ])
        
        searchRequest.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude),
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        
        let search = MKLocalSearch(request: searchRequest)
        do {
            let response = try await search.start()
            let savedPOIKeys = Set(controller.savedLocations
                .filter { $0.locationType == .poi && $0.parentCity?.id == city.id }
                .map { "\($0.locationName)-\($0.latitude)-\($0.longitude)" })
            
            let queryLowercased = query.lowercased()
            
            let results = response.mapItems.compactMap { item -> GeoLocationModel? in
                let coordinate = item.location.coordinate
                guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
                
                let itemName = item.name ?? "Unknown Location"
                // Only include exact or very close matches (Claude)
                guard itemName.lowercased().contains(queryLowercased) ||
                        queryLowercased.contains(itemName.lowercased()) else {
                    return nil
                }
                
                let poi = GeoLocationModel(
                    locationName: itemName,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    locationType: .poi,
                    parentCity: city
                )
                let key = "\(poi.locationName)-\(poi.latitude)-\(poi.longitude)"
                // Exclude if already saved in database
                return savedPOIKeys.contains(key) ? nil : poi
            }
            
            // MARK: Only return exact matches (top 3 most relevant)
            searchResults = Array(results.prefix(3))
            print("🔍 Found \(searchResults.count) exact matches for '\(query)'")
            
            // MARK: Zoom map to first search result for better visibility
            if let firstResult = searchResults.first {
                centerMap(on: firstResult)
            }
        } catch {
            print("❌ Search error: \(error.localizedDescription)")
            searchResults = []
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
        isSearching = false
    }
    
    // MARK: - Mark/unmark POIs (heart icon)
    func markPOI(_ poi: GeoLocationModel) {
        // If in preset, only mark if not already marked
        if presetPOIs.contains(where: { $0.id == poi.id }) {
            if !markedPOIs.contains(where: { $0.id == poi.id }) {
                markedPOIs.append(poi)
            }
        } else {
            // User can add more than 10, but not duplicate
            if !markedPOIs.contains(where: { $0.id == poi.id }) {
                markedPOIs.append(poi)
            }
        }
    }
    
    func unmarkPOI(_ poi: GeoLocationModel) {
        // Remove from markedPOIs, but do not remove from presetPOIs
        markedPOIs.removeAll(where: { $0.id == poi.id })
    }
    
    // MARK: - Helpers
    func isPOIMarked(_ poi: GeoLocationModel) -> Bool {
        return markedPOIs.contains(where: { $0.id == poi.id })
    }
    
    func isPresetPOI(_ poi: GeoLocationModel) -> Bool {
        return presetPOIs.contains(where: { $0.id == poi.id })
    }
    
    func clearSearch() {
        searchResults = []
    }
}
