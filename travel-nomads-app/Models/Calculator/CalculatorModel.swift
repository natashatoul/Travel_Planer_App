//
//  CalculatorModel.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 06/04/2026.
//

import Foundation
import SwiftData

// USAGE: Defines data structure - stores data initial state in Swift Data
// Note: maintain var order of @Model - prevents Swift Data crashes
// Some of these could be made optional

@Model
final class CalculatorModel {
    var id: UUID = UUID()
    // local state vars
    var typeOfCostName: String
    var flightCosts: Double
    var hotelPerNight: Double
    var poiCosts: Double
    var foodAndTravelPerDay: Double
    var numberOfDays: Int
    var numberOfPeople: Int
    var baseCurrencyValue: Double
    // API data requirements
    var baseCurrency: String  // Base currency code (e.g., "GBP")
    var selectedCurrency: String  // Selected foreign currency code
    var forex: Double  // Exchange rate for selected currency
    // Computed/cached values for UI display
    var totalTripCosts: Double
    var tripCostsPerPerson: Double
    var forexPerPerson: Double
    var costsInLocalCurrency: Double
    // Budget comparison
    var budgetQuote: Double
    var varianceToBudget: Double
    // MARK: initialisation
    init(
        typeOfCostName: String,
        flightCosts: Double,
        hotelPerNight: Double,
        poiCosts: Double,
        foodAndTravelPerDay: Double,
        numberOfDays: Int,
        numberOfPeople: Int,
        baseCurrencyValue: Double,
        baseCurrency: String,
        selectedCurrency: String,
        forex: Double,
        totalTripCosts: Double,
        tripCostsPerPerson: Double,
        forexPerPerson: Double,
        costsInLocalCurrency: Double,
        budgetQuote: Double,
        varianceToBudget: Double
    )
    //MARK: Bindings
    {
        self.id = UUID()
        self.typeOfCostName = typeOfCostName
        self.flightCosts=flightCosts
        self.hotelPerNight = hotelPerNight
        self.poiCosts = poiCosts
        self.foodAndTravelPerDay = foodAndTravelPerDay
        self.numberOfDays = numberOfDays
        self.numberOfPeople = numberOfPeople
        self.baseCurrencyValue = baseCurrencyValue
        self.baseCurrency = baseCurrency
        self.selectedCurrency = selectedCurrency
        self.forex = forex
        self.totalTripCosts = totalTripCosts
        self.tripCostsPerPerson = tripCostsPerPerson
        self.forexPerPerson = forexPerPerson
        self.costsInLocalCurrency = costsInLocalCurrency
        self.budgetQuote = budgetQuote
        self.varianceToBudget = varianceToBudget
    }
}
