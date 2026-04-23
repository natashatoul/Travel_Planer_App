//
//  WikipediaViewModel.swift
//  travel-nomads-app
//
//  Created by Natalia Kiriachek on 10/04/2026.
//

import Foundation
import Observation

@Observable
@MainActor
class WikipediaViewModel {
    var cityInfo: WikipediaResponse?
    var isLoading = false
    var errorMessage = ""
    
    private let service = WikipediaService()
    
    func fetchCityInfo(for city: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            cityInfo = try await service.fetchCityInfo(for: city)
        } catch {
            errorMessage = "Could not load info for \(city)"
        }
        
        isLoading = false
    }
}
