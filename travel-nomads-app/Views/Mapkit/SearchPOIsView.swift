//
//  SearchPOIsView.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 07/04/2026.
//
import SwiftUI
import MapKit
import SwiftData
import Combine

// USAGE: Default Location London changes as user selects new cities
// User can save and delete cities by clicking on animated hearts
// @StateObject updates UI from VM
// @State local vars not saved in DB
// Data controller initialised in View (LocationController)
// Views go to VM and update local vars with business logic functions

struct SearchPOIsView: View {
    // StateObject retreives default map location and other data from VM
    @StateObject private var viewModel: GeoLocationViewModel
    // MARK:   Local state vars - not saved in DB - map position, search text, animations
    @State private var searchText = ""
    @State private var showSaveToast: Bool = false
    @State private var savedCityName: String = ""
    // MARK: changes made on save button click
    @State private var navigateToSavedCities: Bool = false
    //  Local map state is updates so is required as a local var the user selects new cities and updates to save new location
    @State private var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
        latitudinalMeters: 1000,
        longitudinalMeters: 1000
    ))
    
    // MARK: initialise data-layer controllers
    private let controller: LocationController
    init(controller: LocationController) {
        self.controller = controller
        _viewModel = StateObject(wrappedValue: GeoLocationViewModel(controller: controller))
    }
    
    // MARK: Default location to show on map (London)
    private var locationsToDisplay: [GeoLocationModel] {
        if viewModel.geoLocation.isEmpty {
            // Show default London marker when no search results
            return [GeoLocationModel(
                locationName: "London",
                latitude: 51.5074,
                longitude: -0.1278,
                locationType: .city
            )]
        }
        return viewModel.geoLocation
    }
    
    // MARK: Search cities to save to a list
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                searchBar(viewModel: viewModel)
                mapView(viewModel: viewModel)
                resultsList(viewModel: viewModel)
            }
            // MARK: changes made on save button click (environment obj and controller required to pass data)
            .navigationDestination(isPresented: $navigateToSavedCities) {
                CityListView()
                    .environmentObject(controller)
            }
            if showSaveToast {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("") // This line is replaced below
                        Text("")
                        Text(savedCityName).bold().foregroundColor(.white)
                        Text(" has been saved to your travel bucket list").foregroundColor(.white)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(16)
                    .shadow(radius: 8)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeOut(duration: 0.3), value: showSaveToast)
            }
        }
    }
    
    // MARK: - Search Bar Component
    private func searchBar(viewModel: GeoLocationViewModel) -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search locations worldwide", text: $searchText)
                .textFieldStyle(.plain)
                .onSubmit {
                    Task {
                        await viewModel.searchLocations(query: searchText)
                        searchText = ""
                    }
                }
            
            if viewModel.isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    viewModel.geoLocation = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.gray).opacity(0.05))
        .cornerRadius(10)
        .padding()
    }
    
    // MARK: UI display for the map annotations shows city name - goes back to defaults
    private func mapView(viewModel: GeoLocationViewModel) -> some View {
        Map(position: $mapPosition) {
            ForEach(locationsToDisplay) { location in
                Annotation(location.locationName, coordinate: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                )) {
                    mapMarker(for: location, viewModel: viewModel)
                }
            }
        }
        .frame(height: 400)
        .clipped()
        .id(viewModel.geoLocation.count) // Forces view update when count changes (Claude)
        .onChange(of: viewModel.geoLocation.count) { oldValue, newValue in
            updateMapPosition(for: viewModel.geoLocation)
        }
    }
    
    // MARK: UI updated to show city name and save button on map annotation
    private func mapMarker(for location: GeoLocationModel, viewModel: GeoLocationViewModel) -> some View {
        VStack {
            // MARK: changes made on save button click (animation Claude)
            Button(action: {
                saveLocation(location, viewModel: viewModel)
            }) {
                Image(systemName: viewModel.isSaved(location) ? "heart.fill" : "heart.circle.fill")
                    .foregroundColor(viewModel.isSaved(location) ? .red : .blue)
                    .font(.title2)
                    .scaleEffect(viewModel.isSaved(location) ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isSaved(location))
            }
            Text(location.locationName)
                .font(.caption2)
                .padding(4)
                .background(.white.opacity(0.8))
                .cornerRadius(4)
        }
    }
    
    // MARK: UI display for the results list at the bottom of the map
    @ViewBuilder
    private func resultsList(viewModel: GeoLocationViewModel) -> some View {
        if !viewModel.geoLocation.isEmpty {
            locationList(viewModel: viewModel)
        } else {
            emptyState(viewModel: viewModel)
        }
    }
    
    // MARK: UI for the Location List with rows
    private func locationList(viewModel: GeoLocationViewModel) -> some View {
        List(viewModel.geoLocation) { location in
            locationRow(for: location, viewModel: viewModel)
        }
        .listStyle(.plain)
    }
    
    // MARK: - Location Row
    private func locationRow(for location: GeoLocationModel, viewModel: GeoLocationViewModel) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(location.locationName)
                    .font(.headline)
                Text("Lat: \(location.latitude, specifier: "%.4f"), Lon: \(location.longitude, specifier: "%.4f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            saveButton(for: location, viewModel: viewModel)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            zoomToLocation(location)
        }
    }
    
    // MARK: changes made on save button click
    //  Save Button - city saved and navigation to saved cities list (animations by Claude)
    private func saveButton(for location: GeoLocationModel, viewModel: GeoLocationViewModel) -> some View {
        Button(action: {
            saveLocation(location, viewModel: viewModel)
        }) {
            Text("Save cities selected")
            Image(systemName: viewModel.isSaved(location) ? "heart.fill" : "heart")
                .foregroundColor(viewModel.isSaved(location) ? .red : .gray)
                .scaleEffect(viewModel.isSaved(location) ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isSaved(location))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Empty State - if no cities found, map view with no cities
    @ViewBuilder
    private func emptyState(viewModel: GeoLocationViewModel) -> some View {
        if searchText.isEmpty && viewModel.geoLocation.isEmpty {
            VStack {
                Text("Search and tap ❤️ to save locations")
                    .foregroundColor(.secondary)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !viewModel.isSearching && viewModel.geoLocation.isEmpty {
            VStack {
                Image(systemName: "mappin.slash")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                Text("No results found")
                    .foregroundColor(.secondary)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: changes made on save button click (free search)
    private func saveLocation(_ location: GeoLocationModel, viewModel: GeoLocationViewModel) {
        let wasSaved = viewModel.isSaved(location)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            viewModel.toggleSave(location)
        }
        if !wasSaved {
            savedCityName = location.locationName
            withAnimation {
                showSaveToast = true
            }
            navigateToSavedCities = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation {
                    showSaveToast = false
                }
            }
        }
    }
    // MARK: Local UI is updated when user chooses new cities (add debug logs Claude)
    private func updateMapPosition(for locations: [GeoLocationModel]) {
        print("[DEBUG] updateMapPosition called with \(locations.count) locations")
        if let firstLocation = locations.first {
            print("[DEBUG] Moving map to: \(firstLocation.locationName) at \(firstLocation.latitude), \(firstLocation.longitude)")
            withAnimation {
                mapPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: firstLocation.latitude,
                        longitude: firstLocation.longitude
                    ),
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                ))
            }
            print("[DEBUG] mapPosition updated")
        }
    }
    // MARK: Aninmation (zoom to location - Claude)
    private func zoomToLocation(_ location: GeoLocationModel) {
        withAnimation {
            mapPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                ),
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            ))
        }
    }
}

//  NOTE: Testing in preview mode has slow tile loading performance
//  Limited netweork access,  incomplete lifecycle initialisation
//  map loading memory intensive, preview ahs resource constrains
//  rapid create-destory cyle results in preview crashes and async issues
//  debugs added - no errors in logs - some debugging facilitated by Claude

struct  SearchPOIsViewPreview: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: GeoLocationModel.self, configurations: config)
        let controller = LocationController(modelContext: container.mainContext)
        
        NavigationStack {
            SearchPOIsView(controller: controller)
                .environmentObject(controller)
        }
        .modelContainer(container)
    }
}
