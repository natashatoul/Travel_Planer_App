//
//  FinalCostsView.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 06/04/2026.
//

import SwiftUI

// USAGE: After trip caclulate variance
// This component shows the process used
// It marks how the app can be scaled
// It has not been refactored

struct FinalCostsView: View {
    //    local state vars - REFACTOR WHEN SWIFT DATA ADDED
    @State private var baseCurrency: Double = 1.0
    @State private var forex: Double = 5.0
    @State private var flightCost: Double = 1000.0
    @State private var hotelPerNight: Double = 100.0
    @State private var poiCosts: Double = 250.0
    @State private var foodAndTravelPerDay: Double = 75.0
    @State private var numberOfDays: Int = 7
    @State private var numberOfPeople: Int = 1
    
    //    MARK: COMPUTED VALUES
    @State private var totalTripCosts: Double = 0.0
    @State private var costsInLocalCurrency: Double = 0.0
    @State private var varianceToBudget: Double = 0.0
    @State private var budgetQuote: Double = 3500.0
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                Text("Trip Cost & Variance")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                
                //    MARK:    Print variance computed results
                HStack {
                    Text("Total Trip Costs: £\(totalTripCosts, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding()
                    
                    Text("Total Local Currency Costs: £\(costsInLocalCurrency, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding()
                }
                
                
                HStack {
                    Text("Budget set: £ £\(budgetQuote, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding()
                    
                    Text("Variance to budget: £ £\(varianceToBudget, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding()
                    
                }
                //    MARK:    Inputs
                // Flight Cost
                HStack {
                    Label("Flights", systemImage: "airplane")
                    TextField("Amount", value: $flightCost, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                .cornerRadius(10)
                
                // Hotel Per Night
                HStack {
                    Label("Hotel / Night", systemImage: "bed.double")
                    TextField("Amount", value: $hotelPerNight, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                .cornerRadius(10)
                
                // POI Costs
                HStack {
                    Label("POI Costs", systemImage: "mappin.and.ellipse")
                    TextField("Amount", value: $poiCosts, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                .cornerRadius(10)
                
                // Food & Travel Per Day
                HStack {
                    Label("Food & Travel / Day", systemImage: "fork.knife")
                    TextField("Amount", value: $foodAndTravelPerDay, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                .cornerRadius(10)
                
                // Select local currency REFACTOR CALLING API
                HStack {
                    Label("Select local currency", systemImage: "")
                    TextField("Amount", value: $baseCurrency, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                .cornerRadius(10)
                
                // Foreign exchange REFACTOR CALLING API
                HStack {
                    Label("Cost in Local Currency", systemImage: " ")
                    TextField("Amount", value: $forex, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Number of Days
                HStack {
                    Label("Days", systemImage: "calendar")
                    TextField("Days", value: $numberOfDays, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                .cornerRadius(10)
                
                // Number of People
                HStack {
                    Label("People", systemImage: "person.2")
                    TextField("People", value: $numberOfPeople, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                .cornerRadius(10)
                
            }
            .padding()
        }
        // MARK: Computed values
        
        Button("Calculate Total costs") {
            totalTripCosts = calcTotalTripCosts()
            varianceToBudget = calcVariance()
        }
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
        
    }
    
    
    
    //     MARK: Functions for computed values
    //     REFACTOR AND MOVE TO VIEW MODEL WHEN SWIFT DATA ADDED
    
    //  calculate variable costs
    func calcCostsPerDay() -> Double {
        let dailyCosts = hotelPerNight + poiCosts + foodAndTravelPerDay
        return dailyCosts
    }
    // convert local currency into sterling
    func calcSterlingCostsPerDay() -> Double {
        return calcCostsPerDay() / forex
    }
    //   calculate variable costs and add fixed cost (flight)
    func calcCostPerPerson() -> Double {
        return calcSterlingCostsPerDay() * Double(numberOfDays) + flightCost
    }
    // total cost in base currency
    func calcTotalTripCosts() -> Double {
        return calcCostPerPerson() * Double(numberOfPeople)
    }
    //     How much forex to be purchased for the trip
    func calcTotalForexRequired() -> Double {
        return calcCostsPerDay() * Double(numberOfPeople)
    }
    
    func calcVariance() -> Double {
        // subtract total trip costs from budget
        return budgetQuote - totalTripCosts
    }
}


#Preview {
    FinalCostsView()
}
