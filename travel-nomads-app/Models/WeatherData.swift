//
//  WeatherData.swift
//  travel-nomads-app
//
//  Created by Natalia Kiriachek on 10/04/2026.
//

import Foundation

struct WeatherData: Codable {
    let main: Main
    let weather: [WeatherDescription]
    let name: String
    let wind: Wind?
}

struct Main: Codable {
    let temp: Double
    let feelsLike: Double
    let humidity: Int
    let tempMin: Double
    let tempMax: Double

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case humidity
        case tempMin = "temp_min"
        case tempMax = "temp_max"
    }
}

struct WeatherDescription: Codable {
    let description: String
    let icon: String
}

struct Wind: Codable {
    let speed: Double
}
