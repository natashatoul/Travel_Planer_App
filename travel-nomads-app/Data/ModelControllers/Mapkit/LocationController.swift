//
//  LocationController.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 07/04/2026.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

// USAGE: Data container for location searches
// Maps locations to cities and points of interest (POIs)

@MainActor
class LocationController: ObservableObject {
    @Published var savedLocations: [GeoLocationModel] = []
    // Places of interest location controller
    // Returns only locations with locationType == .city
    var savedCities: [GeoLocationModel] {
        savedLocations.filter { $0.locationType == .city }
    }
    
    // Initialise model context
    private var modelContext: ModelContext?
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        print("[DEBUG] LocationController initialized with SwiftData")
        loadSavedLocations()
    }
    
    init() {
        self.modelContext = nil
        print("[DEBUG] LocationController initialized (preview mode - no persistence)")
    }
    // MARK: Business logic functions
    
    // Load all saved locations
    func loadSavedLocations() {
        guard let modelContext = modelContext else {
            print("[DEBUG]No modelContext - running in preview mode")
            return
        }
        
        let descriptor = FetchDescriptor<GeoLocationModel>(
            sortBy: [SortDescriptor(\.locationName)]
        )
        
        do {
            savedLocations = try modelContext.fetch(descriptor)
            print("[DEBUG]Loaded \(savedLocations.count) saved locations")
        } catch {
            print("[DEBUG]Failed to fetch locations: \(error)")
            savedLocations = []
        }
    }
    
    // Create and save a new (city) searched in the DB
    func saveLocation(_ location: GeoLocationModel) {
        guard !savedLocations.contains(where: { $0.id == location.id }) else {
            print("[DEBUG]Location already saved")
            return
        }
        modelContext?.insert(location)
        savedLocations.append(location)
        saveContext()
        print("[DEBUG] SAVED: '\(location.locationName)' - Total: \(savedLocations.count)")
    }
    
    // Checks if a specific location is already saved does not save to DB to retain uniques
    func isSaved(_ location: GeoLocationModel) -> Bool {
        return savedLocations.contains(where: { $0.id == location.id })
    }
    
    // Retrieves a specific saved location by its unique ID
    // - Parameter id: The UUID of the location to find
    // - Returns: The matching GeoLocationModel, or nil if not found
    func getLocation(by id: UUID) -> GeoLocationModel? {
        return savedLocations.first(where: { $0.id == id })
    }
    
    // Delete a saved location - allows users to toggle add/ remove
    func deleteLocation(_ location: GeoLocationModel) {
        if let modelContext = modelContext {
            modelContext.delete(location)
        }
        savedLocations.removeAll(where: { $0.id == location.id })
        saveContext()
        print("[DEBUG] WARNING! DELETED: '\(location.locationName)' - Total: \(savedLocations.count)")
    }
    
    // Removes all saved locations - not used
    // In UI can be used to clean up DB
    func clearAll() {
        let count = savedLocations.count
        
        if let modelContext = modelContext {
            for location in savedLocations {
                modelContext.delete(location)
            }
        }
        
        savedLocations.removeAll()
        saveContext()
        print("[DEBUG] WARNING! CLEARED ALL: \(count) locations removed")
    }
    
    // Toggle between save and delete in the DB
    // allows locations to be removed from DB easily
    func toggleSave(_ location: GeoLocationModel) {
        if isSaved(location) {
            deleteLocation(location)
        } else {
            saveLocation(location)
        }
    }
    
    //    MARK: - Persistence by saving the controller context ot a model context
    private func saveContext() {
        guard let modelContext = modelContext else {
            print("[ERROR] saveContext: No modelContext - changes not persisted")
            return
        }
        do {
            try modelContext.save()
            print("[DEBUG] saveContext: Context saved successfully")
        } catch {
            print("[ERROR] Failed to save context: \(error.localizedDescription)")
        }
    }
}
