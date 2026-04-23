//
//  CalculatorViewModel.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 06/04/2026.
//

import Foundation
import Combine
import SwiftData

// USAGE: Once Swift Data added to root
// Model Data is passed via the inmemory container injected in root
// The VM will need to be initialised to accept the Controller functions

class CalculatorViewModel: ObservableObject {
    // REFACTOR:   fields (all @Published for UI binding
    // moved from UI component where they were @State vars)
    @Published var travelBudget: [CalculatorModel] = []
    @Published var typeOfCostName: String = "My ideal 7-day budget"
    @Published var flightCosts: Double = 1000.0
    @Published var hotelPerNight: Double = 100.0
    @Published var poiCosts: Double = 25.0
    @Published var foodAndTravelPerDay: Double = 75.0
    @Published var numberOfDays: Int = 7
    @Published var numberOfPeople: Int = 1
    @Published var baseCurrencyValue: Double = 1.0
    //    MARK: API data requirements (refactor)
    @Published var baseCurrency: String = "GBP"
    @Published var forex: Double = 5.0
    @Published var selectedCurrency: String = "USD"
    
    //    MARK: COMPUTED VALUES
    @Published var totalTripCosts: Double = 0.0
    @Published var tripCostsPerPerson: Double = 0.0
    @Published var forexPerPerson: Double = 0.0
    @Published var costsInLocalCurrency: Double = 0.0
    
    //    MARK: OPTIONAL VALUES for saved quotes, but required for variance
    var budgetQuote: Double = 0
    var varianceToBudget: Double = 0
    
    // MARK: Local UI state, this data will not be stored in DB
    @Published var alertMessage: String = ""
    @Published var showAlert = false
    @Published var reset: Double = 0.0
    
    
    // MARK: initialise VM to use controller functions
    private let controller: CalculatorController
    // MARK: Fix data persistence bug - not a private var (Claude)
    var modelContext: ModelContext?
    // MARK: Fix data persistence bug (Claude)
    init(controller: CalculatorController, modelContext: ModelContext?) {
        self.controller = controller
        self.modelContext = modelContext
    }
    
    // MARK: GET FOREX API DATA - constraint of free view is that USD base currency
    // API returns USD-based rates; convert to GBP base:
    // rate = rates[selectedCurrency] / rates["GBP"] = units of selectedCurrency per 1 GBP
    func fetchForexData() async {
        do {
            let forexData = try await ForexAPIService().fetchForexAPI(currency: selectedCurrency)
            DispatchQueue.main.async {
                let gbpRate = forexData.rates["GBP"] ?? 1.0
                let targetRate = forexData.rates[self.selectedCurrency] ?? 1.0
                // Convert USD-base to GBP-base: how many selectedCurrency per 1 GBP
                self.forex = gbpRate > 0 ? targetRate / gbpRate : 1.0
                self.baseCurrency = "GBP"
            }
        } catch {
            DispatchQueue.main.async {
                self.alertMessage = "Failed to fetch forex data: \(error.localizedDescription)"
                self.showAlert = true
            }
        }
    }
    
    //  MARK: Functions for bugdet quote computed values
    
    //  calculate variable budgeted sterling daily costs
    func calcCostsPerDay() -> Double {
        let dailyCosts = hotelPerNight + poiCosts + foodAndTravelPerDay
        return dailyCosts
    }
    //   add flight costs and variable budgeted sterling costs
    func calcCostPerPerson() -> Double {
        return calcCostsPerDay() + flightCosts
    }
    
    // total cost in base currency
    func calcTotalTripCosts() -> Double {
        return calcCostPerPerson() * Double(numberOfDays)
    }
    
    // find out how much this will cost in local currency per day
    func calcSterlingCostsPerDay() -> Double {
        return calcCostsPerDay() / forex
    }
    //     How much forex to be purchased for the trip per person/ day
    func calcTotalForexRequired() -> Double {
        return calcCostsPerDay() * Double(numberOfPeople)
    }
    
    // reset so that different budgets can be set
    func resetToDefaultValues() -> Double {
        typeOfCostName = "My ideal 7-day budget"
        flightCosts = 1000.0
        hotelPerNight = 100.0
        poiCosts = 250.0
        foodAndTravelPerDay = 75.0
        numberOfDays = 7
        numberOfPeople = 1
        baseCurrencyValue = 1.0
        forex = 5.0
        totalTripCosts = 0.0
        tripCostsPerPerson = 0.0
        forexPerPerson = 0.0
        return 0.0
    }
    
    // MARK: Functions to save and load budgets (refactor to use model context container)
    // func addBudget(_ budget: CalculatorModel) {
    //     // Code to save the budget to the database
    //       travelBudget.append(budget)
    // }
    
    //  MARK: Create a new budget quote and save to the database,
    // then load all saved budgets to update the list
    func addBudget(_ budget: CalculatorModel) {
        modelContext?.insert(budget)
        loadBudgets()
    }
    
    // MARK: Delete a single saved budget
    func deleteBudget(_ budget: CalculatorModel) {
        modelContext?.delete(budget)
        loadBudgets()
    }
    
    func loadBudgets() {
        guard let modelContext = modelContext else { return }
        let fetchDescriptor = FetchDescriptor<CalculatorModel>()
        travelBudget = (try? modelContext.fetch(fetchDescriptor)) ?? []
    }
}
