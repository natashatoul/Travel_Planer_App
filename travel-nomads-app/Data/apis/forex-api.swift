//
//  forex-api.swift
//  travel-nomads-app
//
//  Created by Sumi Sastri on 06/04/2026.
//

import Foundation

// USAGE: Data call uses only 1 param forex
// MVP shows how a paid-for API could be used with more data access

// MARK: - Forex Response Model
struct Forex: Codable {
    let disclaimer: String?
    let license: String?
    let timestamp: Int
    let base: String
    let rates: [String: Double]
}

// MARK: - Forex - API Service FIX ME INITIALISE
@MainActor
class ForexAPIService {
    private let baseURL = "https://openexchangerates.org/api/latest.json"
    private let apiKey = "696bf4f9c68a4366805f11715bfbe273"  // App ID 1 free (students)
    
    // define params
    // (forex = Forex)
    func fetchForexAPI(currency: String) async throws -> Forex {
        /// Safely construct URL using URLComponents to avoid URL encoding issues
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        /// Add query parameters for the API request
        urlComponents.queryItems = [
            URLQueryItem(name: "app_id", value: apiKey)
        ]
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        /// Make async network request using URLSession
        let (data, response) = try await URLSession.shared.data(from: url)
        
        ///Check for valid HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        /// Handle different HTTP status codes
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw NetworkError.currencyNotFound
            } else {
                throw NetworkError.invalidResponse
            }
        }
        
        /// Decode JSON response into Forex struct using Codable
        do {
            return try JSONDecoder().decode(Forex.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
}
// MARK: - Network Errors
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case decodingError
    case currencyNotFound
}
