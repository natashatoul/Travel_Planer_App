//
//  CityItineraryView.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 07/04/2026.
//

import SwiftUI
import MapKit
import SwiftData
import Combine

//  USAGE: A list of POIs can be selected for a city
//  Interactive map that user can save and remove POIs
// Added for annotation views @Binding need for connection between child and parents. Child can even change somothing and parents will know about it
struct PresetPOIAnnotation: View {
    let poi: GeoLocationModel
    @ObservedObject var viewModel: GeoLocationViewModel
    let city: GeoLocationModel
    @Binding var savedPOIName: String
    @Binding var showSaveToast: Bool
    
    var body: some View {
            VStack {
                Button {
                    viewModel.markPOI(poi)
                    viewModel.savePOI(poi, underCity: city)
                    savedPOIName = poi.locationName
                    withAnimation { showSaveToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation { showSaveToast = false }
                    }
                } label: {
                    Image(systemName: "heart")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
                Text(poi.locationName)
                    .font(.caption2)
                    .padding(4)
                    .background(.white)
                    .cornerRadius(4)
            }
        }
}

// Annotation for saved POI - red heart
struct MarkedPOIAnnotation: View {
    let poi: GeoLocationModel

    var body: some View {
        VStack {
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .font(.title3)
            Text(poi.locationName)
                .font(.caption2)
                .padding(4)
                .background(.white)
                .cornerRadius(4)
        }
    }
}

// Annotation for search results - blue star
struct SearchResultPOIAnnotation: View {
    let poi: GeoLocationModel
    @ObservedObject var viewModel: GeoLocationViewModel
    let city: GeoLocationModel
    @Binding var savedPOIName: String
    @Binding var showSaveToast: Bool
    var onClearSearch: () -> Void

    var body: some View {
        VStack {
            Button {
                if !viewModel.isPOIMarked(poi) {
                    viewModel.markPOI(poi)
                    viewModel.savePOI(poi, underCity: city)
                    savedPOIName = poi.locationName
                    withAnimation { showSaveToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation { showSaveToast = false }
                    }
                    onClearSearch()
                }
            } label: {
                Image(systemName: viewModel.isPOIMarked(poi) ? "heart.fill" : "star.fill")
                    .foregroundColor(viewModel.isPOIMarked(poi) ? .red : .blue)
                    .font(.title2)
            }
            .disabled(viewModel.isPOIMarked(poi))
            Text(poi.locationName)
                .font(.caption2)
                .padding(4)
                .background(.white)
                .cornerRadius(4)
        }
    }
}

// Main view

struct CityItineraryView: View {
    @EnvironmentObject var controller: LocationController
    @StateObject private var viewModel: GeoLocationViewModel
    // local state vars
    @State private var searchText: String = ""
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var showSaveToast: Bool = false
    @State private var showFailToast: Bool = false
    @State private var savedPOIName: String = ""
    @State private var currentRegion: MKCoordinateRegion?
    @State private var showAboutSheet = false
    var city: GeoLocationModel
    init(city: GeoLocationModel, controller: LocationController) {
        self.city = city
        _viewModel = StateObject(wrappedValue: GeoLocationViewModel(controller: controller))
        let initialCenter = CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude)
        let initialSpan = MKCoordinateSpan(latitudeDelta: 0.045, longitudeDelta: 0.045)
        let initialRegion = MKCoordinateRegion(center: initialCenter, span: initialSpan)
        _mapPosition = State(initialValue: .region(initialRegion))
        _currentRegion = State(initialValue: initialRegion)
    }
    // Subviews
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            TextField("Search places in \(city.locationName)", text: $searchText)
                .textFieldStyle(.plain)
                .onSubmit {
                    Task {
                        await viewModel.searchPOIs(query: searchText, in: city)
                        if let firstResult = viewModel.searchResults.first {
                            withAnimation {
                                mapPosition = .region(MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(
                                        latitude: firstResult.latitude,
                                        longitude: firstResult.longitude
                                    ),
                                    latitudinalMeters: 1000,
                                    longitudinalMeters: 1000
                                ))
                            }
                        } else if viewModel.searchResults.isEmpty && !searchText.isEmpty {
                            withAnimation { showFailToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation { showFailToast = false }
                            }
                        }
                    }
                }
            if viewModel.isSearching { ProgressView().scaleEffect(0.8) }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
        .padding()
    }
        
    private var legendView: some View {
        HStack {
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                    Text("Saved")
                        .font(.subheadline)
                }
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                    Text("Search Results")
                        .font(.subheadline)
                }
            }

            Spacer()
            
            Button {
                showAboutSheet = true
            } label: {
                Text("About \(city.locationName)")
                    .font(.system(size: 20))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
        .sheet(isPresented: $showAboutSheet) {
            NavigationStack {
                AboutCityView(city: city)
            }
        }
    }
    
    private var searchResultsListView: some View {
            Group {
                if !viewModel.searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Search Results (\(viewModel.searchResults.count))")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        ForEach(viewModel.searchResults) { poi in
                            HStack {
                                Text(poi.locationName).font(.footnote)
                                Spacer()
                                Button {
                                    viewModel.markPOI(poi)
                                    viewModel.savePOI(poi, underCity: city)
                                    savedPOIName = poi.locationName
                                    withAnimation { showSaveToast = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                        withAnimation { showSaveToast = false }
                                    }
                                    viewModel.clearSearch()
                                    searchText = ""
                                } label: {
                                    HStack {
                                        Text("Save to Map")
                                        Image(systemName: "heart")
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            Divider()
                        }
                    }
                    .background(Color.yellow.opacity(0.1))
                }
            }
    }
    
    private var savedPlacesView: some View {
        Group {
            if !viewModel.markedPOIs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved Places")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    ForEach(viewModel.markedPOIs) { poi in
                        HStack {
                            Text(poi.locationName).font(.footnote)
                            Spacer()
                            Button {
                                viewModel.unmarkPOI(poi)
                                viewModel.deletePOI(poi)
                            } label: {
                                HStack {
                                    Image(systemName: "trash").foregroundColor(.red)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Divider()
                    }
                }
                .padding(.horizontal)
            } else {
                Text("Tap the heart icon to save a place")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
    
    private var mapView: some View {
            ZStack(alignment: .bottomTrailing) {
                Map(position: $mapPosition) {
                    // Маркер города
                    Annotation(city.locationName, coordinate: CLLocationCoordinate2D(
                        latitude: city.latitude, longitude: city.longitude)) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.blue)
                            .font(.title)
                    }
                    // Present POIs - grey hearts
                    ForEach(viewModel.presetPOIs) { poi in
                        Annotation("", coordinate: CLLocationCoordinate2D(
                            latitude: poi.latitude, longitude: poi.longitude)) {
                                PresetPOIAnnotation(
                                    poi: poi,
                                    viewModel: viewModel,
                                    city: city,
                                    savedPOIName: $savedPOIName,
                                    showSaveToast: $showSaveToast
                                )
                            }
                    }
                    // Saved POIs - red hearts
                    ForEach(viewModel.markedPOIs) { poi in
                        Annotation("", coordinate: CLLocationCoordinate2D(
                            latitude: poi.latitude, longitude: poi.longitude)) {
                                MarkedPOIAnnotation(poi: poi)
                            }
                    }
                    
                    // Result of search - blue stars and read hearts
                    ForEach(viewModel.searchResults) { poi in
                        Annotation("", coordinate: CLLocationCoordinate2D(
                            latitude: poi.latitude, longitude: poi.longitude)) {
                                SearchResultPOIAnnotation(
                                    poi: poi,
                                    viewModel: viewModel,
                                    city: city,
                                    savedPOIName: $savedPOIName,
                                    showSaveToast: $showSaveToast,
                                    onClearSearch: {
                                        viewModel.clearSearch()
                                        searchText = ""
                                    }
                                )
                            }
                    }
                }
                .mapStyle(.standard(elevation: .automatic))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    MapPitchToggle()
                }
                .frame(height: 300)
                .clipped()
                .scrollDisabled(true)
                .onMapCameraChange { context in
                    currentRegion = context.region
                }
                
                // Zoom button
                VStack(spacing: 10) {
                    Button(action: zoomIn) {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Button(action: zoomOut) {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
            .padding(.bottom, 8)
    }
    
    
    // MARK: - Body
                
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    searchBarView
                    mapView
                    legendView
                    searchResultsListView
                    savedPlacesView
                    
                    if viewModel.presetPOIs.isEmpty && viewModel.markedPOIs.isEmpty {
                        Text("Discover places above or search for specific locations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
            }
            .navigationTitle("\(city.locationName) trip planner")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SavedItinerariesView(city: city)
                            .environmentObject(controller)
                    } label: {
                        Text("My saved itinerary")
                    }
                }
            }
            .task {
                await viewModel.discoverPOIs(for: city)
                viewModel.reloadCurrentCityPOIs(for: city)
            }
            
                
                // MARK: Toasts (Success)
                if showSaveToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text(savedPOIName).bold().foregroundColor(.white)
                            Text(" saved to itinerary!").foregroundColor(.white)
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
                
                // MARK: Fail Toast
                if showFailToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Check the spelling - we couldn't find that location")
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(16)
                        .shadow(radius: 8)
                        .padding(.bottom, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeOut(duration: 0.3), value: showFailToast)
                }
            } // end outer ZStack
        }
        
        func zoomIn() {
            guard let region = currentRegion else { return }
            withAnimation {
                let newSpan = MKCoordinateSpan(
                    latitudeDelta: region.span.latitudeDelta / 2,
                    longitudeDelta: region.span.longitudeDelta / 2
                )
                let newRegion = MKCoordinateRegion(center: region.center, span: newSpan)
                mapPosition = .region(newRegion)
                currentRegion = newRegion
            }
        }
        
        func zoomOut() {
            guard let region = currentRegion else { return }
            withAnimation {
                let newSpan = MKCoordinateSpan(
                    latitudeDelta: min(region.span.latitudeDelta * 2, 180),
                    longitudeDelta: min(region.span.longitudeDelta * 2, 180)
                )
                let newRegion = MKCoordinateRegion(center: region.center, span: newSpan)
                mapPosition = .region(newRegion)
                currentRegion = newRegion
            }
        }
    }
    
    //  NOTE: There may be a duplication of controller set up in the body
    //  And preview - redundancy issue is not a runtime/compiletime issue
    //  TODO: Clean up preview
    
    #Preview {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: GeoLocationModel.self, configurations: config)
        let controller = LocationController(modelContext: container.mainContext)
        
        //  MARK: - Using Paris as default city for preview, can be changed to any city with lat/long
        let city = GeoLocationModel(locationName: "Paris", latitude: 48.8566, longitude: 2.3522)
        let locationController = LocationController(modelContext: container.mainContext)
        
        // The preview will use the controller, data-container passed from root
        NavigationStack {
            CityItineraryView(city: city, controller: locationController)
                .environmentObject(controller)
        }
        .modelContainer(container)
    }

