//
//  WikipediaService.swift
//  travel-nomads-app
//
//  Created by Natalia Kiriachek on 10/04/2026.
//

import Foundation

struct WikipediaResponse: Codable {
    let pageid: Int?
    let title: String
    let extract: String
    let thumbnail: WikiThumbnail?
}

struct WikiThumbnail: Codable {
    let source: String
}

class WikipediaService {
    func fetchCityInfo(for city: String) async throws -> WikipediaResponse {
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? city
        let urlString = "https://en.wikipedia.org/api/rest_v1/page/summary/\(encodedCity)"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(WikipediaResponse.self, from: data)
    }
}

