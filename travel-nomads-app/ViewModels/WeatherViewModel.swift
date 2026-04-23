//
//  WeatherViewModel.swift
//  travel-nomads-app
//
//  Created by Natalia Kiriachek on 10/04/2026.
//

import Foundation
import Observation

@Observable
@MainActor
class WeatherViewModel {
    var weather: WeatherData?
    var errorMessage: String = ""
    var isLoading: Bool = false
    
    private let service = APIWeatherService()
    
    func fetchWeather(for city: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            weather = try await service.fetchWeather(for: city)
        } catch {
            errorMessage = "Could not load weather for \(city)"
        }
        
        isLoading = false
    }
}
