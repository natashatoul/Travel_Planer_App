//
//  SetBudgetView.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 06/04/2026.
//

import SwiftUI
import SwiftData


// USAGE: Refactor from @State vars to use Swift Data
// Move all state vars to VM
// initialise controller and use @StateObject to use VM functions and data
// @EnvironmentObject to access data across views and VMs
// @ModelContext invoked for previews

struct SetBudgetView: View {
    //  initalise with controller
    let controller: CalculatorController
    @StateObject private var viewModel: CalculatorViewModel
    @State private var editingQuote: CalculatorModel?
    
    // Local state for alert and navigation
    @State private var alertMessage = ""
    @State private var navigateToQuotes = false
    @FocusState private var isInputFocused: Bool
    
    //   MARK: initialise view model with controller functions
    init(controller: CalculatorController) {
        self.controller = controller
        // Fix data persistence bug (Claude)
        let context = controller.modelContext
        _viewModel = StateObject(wrappedValue: CalculatorViewModel(controller: controller, modelContext: context))
    }
    
    var body: some View {
        // Add a navigation stack to enable navigation to the quotes view
        NavigationStack {
            ScrollView {
                VStack {
                    // Title Section
                    Text("Travel Budget")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    //  MARK: Form fields - local state updates
                    // Budget Quote Name Field
                    VStack(alignment: .leading, spacing: 20) {
                        Label("Budget Quote Name", systemImage: "tag")
                            .font(.title)
                            
                        TextField("Enter name", text: $viewModel.typeOfCostName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    .cornerRadius(5)
                    
                    // Calculated Results Section
                    // Shows the total budget per person
                    
                    
                    // Flight Costs Field
                    HStack {
                        Label("Flights: £", systemImage: "airplane")
                        Spacer()
                        TextField("Amount", value: $viewModel.flightCosts, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding()
                    .cornerRadius(10)
                    
                    //  Hotel Per Night Field
                    HStack {
                        Label("Hotel / Night: : £", systemImage: "bed.double")
                        Spacer()
                        TextField("Amount", value: $viewModel.hotelPerNight, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding()
                    .cornerRadius(10)
                    
                    // POI (Entry Ticket) Costs Field
                    HStack {
                        Label("Entry Ticket Costs/ day : £", systemImage: "ticket")
                        Spacer()
                        TextField("Amount", value: $viewModel.poiCosts, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding()
                    .cornerRadius(10)
                    
                    // Food & Travel Per Day Field
                    HStack {
                        Label("Food & Travel / Day : £", systemImage: "fork.knife")
                        Spacer()
                        TextField("Amount", value: $viewModel.foodAndTravelPerDay, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding()
                    .cornerRadius(10)
                    
                    // Currency Search Field - enter currency code e.g. EUR, INR
                    VStack(alignment: .leading) {
                        HStack {
                            Label("Currency", systemImage: "magnifyingglass")
                            Spacer()
                            TextField("e.g. EUR, INR, USD", text: $viewModel.selectedCurrency)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocorrectionDisabled()
                                .frame(width: 120)
                                .font(.system(.body, design: .monospaced))
                        }
                        
                        // Tap to fetch the live rate for the currency entered above - button added to trigger fetch
                        Button {
                            viewModel.selectedCurrency = viewModel.selectedCurrency.trimmingCharacters(in: .whitespaces).uppercased()
                            Task { await viewModel.fetchForexData() }
                        } label: {
                            Label("Fetch live rate", systemImage: "arrow.clockwise")
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.teal)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()

                    
                    // Forex Rate Field - populated with live rate against GBP
                    HStack {
                        Label("Forex Rate to GBP", systemImage: "globe")
                        Spacer()
                        TextField("Rate", value: $viewModel.forex, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                    }
                    .padding()

                    
                    // Number of Days Field
                    HStack {
                        Label("Days", systemImage: "calendar")
                        Spacer()
                        TextField("Days", value: $viewModel.numberOfDays, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                    }
                    .padding()
                    
                    // Number of People Field
                    HStack {
                        Label("People", systemImage: "person.2")
                        Spacer()
                        TextField("People", value: $viewModel.numberOfPeople, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                    }
                    .padding()
                    Text("Total budget per day: £\(viewModel.tripCostsPerPerson, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding()
                        .foregroundColor(.blue)
                    
                    // Shows the forex required per person per day
                    Text("USD/person per day: \(viewModel.forexPerPerson, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.indigo)
                    
                    //  MARK: Computed values
                    VStack(spacing: 12) {
                        // Top: Calculate button
                        Button("Calculate Total costs") {
                            viewModel.totalTripCosts = viewModel.calcTotalTripCosts()
                            viewModel.tripCostsPerPerson = viewModel.calcCostPerPerson()
                            viewModel.forexPerPerson = viewModel.calcTotalForexRequired()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        // Bottom: Save + Reset side by side
                        HStack(spacing: 12) {
                            Button("Save Quote") {
                                viewModel.totalTripCosts = viewModel.calcTotalTripCosts()
                                viewModel.tripCostsPerPerson = viewModel.calcCostPerPerson()
                                viewModel.forexPerPerson = viewModel.calcTotalForexRequired()
                                let newQuote = CalculatorModel(
                                    typeOfCostName: viewModel.typeOfCostName,
                                    flightCosts: viewModel.flightCosts,
                                    hotelPerNight: viewModel.hotelPerNight,
                                    poiCosts: viewModel.poiCosts,
                                    foodAndTravelPerDay: viewModel.foodAndTravelPerDay,
                                    numberOfDays: viewModel.numberOfDays,
                                    numberOfPeople: viewModel.numberOfPeople,
                                    baseCurrencyValue: viewModel.baseCurrencyValue,
                                    baseCurrency: viewModel.baseCurrency,
                                    selectedCurrency: viewModel.selectedCurrency,
                                    forex: viewModel.forex,
                                    totalTripCosts: viewModel.totalTripCosts,
                                    tripCostsPerPerson: viewModel.tripCostsPerPerson,
                                    forexPerPerson: viewModel.forexPerPerson,
                                    costsInLocalCurrency: viewModel.costsInLocalCurrency,
                                    budgetQuote: viewModel.budgetQuote,
                                    varianceToBudget: viewModel.varianceToBudget
                                )
                                viewModel.addBudget(newQuote)
                                navigateToQuotes = true
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)

                            Button("Reset to default") {
                                isInputFocused = false
                                _ = viewModel.resetToDefaultValues() // Ignore unused result
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.top, 16)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            // MARK: Auto-fetch live forex rate on view appear
            .task { await viewModel.fetchForexData() }
            // MARK: Fix deprecated NavigationLink
            .navigationDestination(isPresented: $navigateToQuotes) {
                QuotesView(viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: QuotesView(viewModel: viewModel)) {
                        Text("Saved Quotes")
                    }
                }
            }
        }
    }
}

// MARK: to use stored data in model context container
private struct SetBudgetViewPreview: View {
    static let container: ModelContainer = {
        try! ModelContainer(for: CalculatorModel.self, configurations: .init(isStoredInMemoryOnly: true))
    }()
    let controller = CalculatorController(modelContext: container.mainContext)
    var body: some View {
        SetBudgetView(controller: controller)
            .modelContainer(Self.container)
    }
}

#Preview {
    SetBudgetViewPreview()
}
