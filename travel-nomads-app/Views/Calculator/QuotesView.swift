//
//  QuotesView.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 06/04/2026.
//

import SwiftUI
import SwiftData

// USAGE: Refactor add Swift Data import
// @ObservedObject required for empty state view
// @Query fetches data from model and orders to typeofCostName
// Preview initialised with in-memory container & controller functions 

struct QuotesView: View {
    @ObservedObject var viewModel: CalculatorViewModel
    @Query(sort: \CalculatorModel.typeOfCostName) var travelBudget: [CalculatorModel]
    var body: some View {
        ZStack{
            Color.blue.opacity(0.08)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    Text("Saved Budgets")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Spacer()
                    
                    // Show List if there are saved quotes, otherwise show empty state
                    if travelBudget.isEmpty {
                        // Empty State Card
                        VStack(spacing: 15) {
                            Image(systemName: "tray")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                            
                            Text("No Budgets Yet")
                                .font(.headline)
                            
                            Text("Create a budget!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(15)
                        .padding(.horizontal)
                        Spacer()
                    } else {
                        // List container for saved quotes (persisted)
                        ForEach(travelBudget, id: \.id) { quote in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(quote.typeOfCostName)
                                        .font(.headline)
                                    Text("Total: £\(quote.totalTripCosts, specifier: "%.2f")")
                                        .font(.subheadline)
                                }
                                Spacer()
                                // Button to delete this saved quote
                                Button(role: .destructive) {
                                    viewModel.deleteBudget(quote)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
            }
        }
        
    }
}

#Preview {
    let container = try! ModelContainer(for: CalculatorModel.self, configurations: .init(isStoredInMemoryOnly: true))
    let controller = CalculatorController(modelContext: container.mainContext)
    let viewModel = CalculatorViewModel(controller: controller, modelContext: controller.modelContext)
    QuotesView(viewModel: viewModel)
}

