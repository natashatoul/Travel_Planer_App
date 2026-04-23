//
//  ContentView.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 07/04/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    //save location
    @EnvironmentObject var locationController: LocationController
    
    var body: some View {
        TabView {
            // Tab 1: Home
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            // Tab 2: Search POIs
            NavigationStack {
                SearchPOIsView(controller: LocationController(modelContext: modelContext))
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            
            // Tab 3: Budget Planner
            NavigationStack {
                SetBudgetView(controller: CalculatorController(modelContext: modelContext))
            }
            .tabItem {
                Label("Budget", systemImage: "sterlingsign")
            }
            
            // Tab to my trip
            NavigationStack {
                CityListView()
                    .environmentObject(locationController)
            }
            .tabItem {
                Label("My Trips", systemImage: "heart.fill")
            }
        }
    }
}

// MARK: Home View
struct HomeView: View {
    
    @State private var animate = false
    
    var body: some View {
        VStack {
            Image("travel_background")
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()
                .scaleEffect(animate ? 1.05 : 1.0)
                .animation(
                    .easeInOut(duration: 6)
                    .repeatForever(autoreverses: true), value: animate)
                .padding(.bottom, 24)

            VStack(spacing: 8) {
                Text("Travel Nomads")
                    .font(.system(size: 26, weight: .bold))
            }
            .padding(.horizontal)
            Spacer()
            
            // Cards
            VStack(alignment: .leading, spacing: 12) {
                FeatureCard(
                    imageName: "discover_trips",
                    title: "Discover new places",
                    description: "Find breathtaking destinations and must-see points of interest to make every journey truly unique and unforgettable."
                )
                
                FeatureCard(
                    imageName: "budjet_planner",
                    title: "Budget planner",
                    description: "Take full control of your travel finances by planning budgets and tracking every expense easily."
                )
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 20)
        .onAppear {
            animate = true
        }
    }
}

// MARK: Feature Card Component
struct FeatureCard: View {
    let imageName: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .background(Color(UIColor.white))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [GeoLocationModel.self, CalculatorModel.self])
}

