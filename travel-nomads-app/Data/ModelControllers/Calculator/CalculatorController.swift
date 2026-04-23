//
//  CalculatorController.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 06/04/2026.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

// USAGE: Data container controls the Model-ViewModel connectivity
// @MainActor - single source of truth for budget calculations
// ModelContext - initialises data in Swift DB and creates a data container
// Container with data in memory stored in root
// @EnvironmentObject co-ordinates data access across view models and views
// VM @Published vars updated by delegating control to controller functions

// single source of truth - main actor
@MainActor
class CalculatorController: ObservableObject {
    @Published var savedTravelBudget: [CalculatorModel] = []
    
    // Initialise model context not a private var
    var modelContext: ModelContext?
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        print("[DEBUG] CalculatorController initialised with SwiftData")
    }
    
    init() {
        self.modelContext = nil
        print("[DEBUG] CalculationsController initialized without SwiftData")
    }
    
    // MARK: CRUD ops
    // Load all saved travel budgets from persistent store
    func loadSavedTravelBudget() {
        guard let modelContext = modelContext else {
            print("[DEBUG] loadSavedTravelBudget: modelContext is nil")
            return
        }
        let descriptor = FetchDescriptor<CalculatorModel>(
            sortBy: [SortDescriptor(\.typeOfCostName)]
        )
        do {
            savedTravelBudget = try modelContext.fetch(descriptor)
            print("[DEBUG] loadSavedTravelBudget: Loaded \(savedTravelBudget.count) budgets")
        } catch {
            print("[ERROR] Failed to load travel budget costs: \(error.localizedDescription)")
            savedTravelBudget = []
        }
    }
    
    
    // MARK: - Persistence and debug prints
    // Save the current model context to persistent storage
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
