//
//  CityListView.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 07/04/2026.
//

import SwiftUI
import MapKit
import SwiftData
import Combine

//  USAGE: A list of cities saved when user chooses a city to visit
//  This is a simple list no map to prevent resource logjams
//  @EnvironmentObject updates UI from VM

struct CityListView:View {
    @EnvironmentObject var controller: LocationController
    @Environment(\.modelContext) private var modelContext
    
    // Filtered list of city locations derived from the controller's saved locations
    private var cities: [GeoLocationModel] {
        controller.savedLocations.filter { $0.locationType == LocationType.city }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !cities.isEmpty {
                List {
                    ForEach(cities) { location in
                        NavigationLink {
                            CityItineraryView(city: location, controller: controller)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(location.locationName)
                                        .font(.headline)
                                    Text("Lat: \(location.latitude, specifier: "%.4f"), Lon: \(location.longitude, specifier: "%.4f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    // Added delete location functionality
                    .onDelete { indexSet in
                        for index in indexSet {
                            let location = cities[index]
                            controller.deleteLocation(location)
                        }
                    }
                }
                .listStyle(.plain)
                Text("\(cities.count) saved location(s)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                
            } else {
                //                    Empty state
                VStack {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No saved locations yet")
                        .foregroundColor(.secondary)
                        .padding()
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Saved Locations")
    }
}

//  NOTE: Preview can have dummy data but not been added
//  General configuration of data container for preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: GeoLocationModel.self, configurations: config)
    let controller = LocationController(modelContext: container.mainContext)
    //     The preview will use the controller, data-container passed from root
    NavigationStack {
        CityListView()
            .environmentObject(controller)
    }
    .modelContainer(container)
}
