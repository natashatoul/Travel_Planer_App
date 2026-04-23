//
//  travel_nomads_appApp.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 07/04/2026.
//

import SwiftUI
import SwiftData

// ROOT FILE - creates the model container and
// injects it into the environment for app-wide access
// Model container data flows uni-directionally top-down to views

@main
struct travel_nomads_appApp: App {
    var sharedModelContainer: ModelContainer = {
        // Schemas to enforce data contracts
        let schema = Schema([
            CalculatorModel.self,
            GeoLocationModel.self,
        // MARK: add models here
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    // Controllers for data persistence across app
    @StateObject private var calculatorController: CalculatorController
    @StateObject private var locationController: LocationController
    // MARK: ADD DATA CONTROLLERS HERE
    
    //  Initialiser for model context and the data container
    //  wraps the state object with the model context for data access
    init() {
        let context = sharedModelContainer.mainContext
        _calculatorController = StateObject(wrappedValue: CalculatorController(modelContext: context))
        _locationController = StateObject(wrappedValue: LocationController(modelContext: context))
    
    // MARK: ADD OTHER MODEL CONTEXT INTIALISERS HERE
        
    }
    // Pass data to views with @EnvironmentObject
    var body: some Scene {
        WindowGroup {
            //  Environments passes controller functions to views and take dependencies in params
            //   ModelContainer provides access to data across views and view models
            ContentView()
                .environmentObject(calculatorController)
                .environmentObject(locationController)
            // MARK: ADD ENV OBJS HERE WITH THEIR CONTROLLERS
        }
        .modelContainer(sharedModelContainer)
    }
}
