//
//  SavedItinerariesView.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 07/04/2026.
//

import SwiftUI
import SwiftData
import MapKit

// USAGE: Display saved POIs for a specific city as a simple list (no map - due to resource memory logjams)

struct SavedItinerariesView: View {
    @EnvironmentObject var controller: LocationController
    var city: GeoLocationModel
    
    // Computed property to get saved POIs for this city
    private var savedPOIs: [GeoLocationModel] {
        controller.savedLocations.filter {
            $0.parentCity?.id == city.id && $0.locationType == .poi
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !savedPOIs.isEmpty {
                List {
                    ForEach(savedPOIs) { poi in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(poi.locationName)
                                    .font(.headline)
                                Text("Lat: \(poi.latitude, specifier: "%.4f"), Lon: \(poi.longitude, specifier: "%.4f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            let poi = savedPOIs[index]
                            controller.deleteLocation(poi)
                        }
                    }
                }
                .listStyle(.plain)
                
                Text("\(savedPOIs.count) saved place(s)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                // Empty state
                VStack {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No saved places yet")
                        .foregroundColor(.secondary)
                        .padding()
                        .font(.caption)
                    Text("Go back and mark places on the map")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("\(city.locationName) Itinerary")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: GeoLocationModel.self, configurations: config)
    let controller = LocationController(modelContext: container.mainContext)
    let city = GeoLocationModel(locationName: "Paris", latitude: 48.8566, longitude: 2.3522)
    
    NavigationStack {
        SavedItinerariesView(city: city)
            .environmentObject(controller)
    }
    .modelContainer(container)
}
