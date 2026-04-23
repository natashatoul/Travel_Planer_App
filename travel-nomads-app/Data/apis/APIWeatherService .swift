//
//  APIWeatherService .swift
//  travel-nomads-app
//
//  Created by Natalia Kiriachek on 10/04/2026.
//

import Foundation

class APIWeatherService {
    private let apiKey = "8d69ffa80562036586c64f610ba4dc6f"
    
    func fetchWeather(for city: String) async throws -> WeatherData {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decodedData = try JSONDecoder().decode(WeatherData.self, from: data)
        return decodedData
    
    }
}
