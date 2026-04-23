//
//  AboutCityView.swift
//  travel-nomads-app
//
//  Created by Natalia Kiriachek on 21/04/2026.
//

import SwiftUI


@MainActor
@Observable
class ForexViewModel {
    var forex: Forex?
    var isLoading = false
    var errorMessage: String?
    
    private let service = ForexAPIService()
    
    func fetchRates() async {
            isLoading = true
            defer { isLoading = false }

            do {
                forex = try await service.fetchForexAPI(currency: "USD")
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load currency rates: \(error.localizedDescription)"
            forex = nil
        }
    }
    var eurToGbp: Double? {
            guard let rates = forex?.rates,
                  let eurRate = rates["EUR"],
                  let gbpRate = rates["GBP"] else {
                return nil
            }
            return gbpRate / eurRate
        }
    }

//MARK: About City View
struct AboutCityView: View {
    let city: GeoLocationModel
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var weatherVM = WeatherViewModel()
    @State private var wikiVM = WikipediaViewModel()
    @State private var forexVM = ForexViewModel()
    
    private let targetCurrency = "EUR"
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                headerImageView
                
                timeAndCurrencyView
                
                weatherDetailsView
                
                // Description from Wiki
                if let extract = wikiVM.cityInfo?.extract {
                    Text(extract)
                        .font(.body)
                        .padding(.horizontal)
                } else if wikiVM.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                Color.clear.frame(height: 20)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle("About \(city.locationName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body)
                }
            }
        }
        .task {
            await weatherVM.fetchWeather(for: city.locationName)
            await wikiVM.fetchCityInfo(for: city.locationName)
            await forexVM.fetchRates()
        }
    }
    // MARK: - City Image
    private var headerImageView: some View {
        Group {
            if let urlStr = city.thumbnailURLString ?? wikiVM.cityInfo?.thumbnail?.source,
               let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.blue.opacity(0.3)
                }
                .frame(height: 220)
                .clipped()
            } else {
                Color.blue.opacity(0.3)
                    .frame(height: 220)
            }
        }
        .frame(height: 220)
    }
    
    // MARK: - Time and Currency
    @ViewBuilder
    private var timeAndCurrencyView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Local time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text(localTimeString)
                        .font(.subheadline)
                }
            }
            
            Divider()
                .frame(height: 20)
            // Currency
            VStack(alignment: .leading, spacing: 4) {
                Text("Exchange rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let rate = forexVM.eurToGbp {
                    HStack(spacing: 6) {
                        Image(systemName: "eurosign.circle")
                            .foregroundColor(.green)
                        Text("€1 = £\(rate, specifier: "%.2f")")
                            .font(.subheadline)
                    }
                } else if forexVM.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Unavailable")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
        .padding(.horizontal)
    }
    
    private var localTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        // В будущем можно определить часовой пояс по координатам
        return formatter.string(from: Date())
    }
    
    // MARK: - Секция с погодой
    @ViewBuilder
    private var weatherDetailsView: some View {
        if let weather = weatherVM.weather {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if let firstWeather = weather.weather.first {
                        Image(systemName: weatherIcon(for: firstWeather.icon))
                            .foregroundColor(.orange)
                    } else {
                        Image(systemName: "thermometer.sun")
                            .foregroundColor(.orange)
                    }
                    Text("Temperature")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(weather.main.temp))°C")
                        .font(.title3)
                        .bold()
                }
                
                Divider()
                
                HStack(spacing: 20) {
                    Label("Feels like \(Int(weather.main.feelsLike))°C", systemImage: "thermometer.medium")
                    Label("Humidity: \(weather.main.humidity)%", systemImage: "humidity")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                if let wind = weather.wind {
                    Label("Wind: \(Int(wind.speed)) m/s", systemImage: "wind")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
            )
            .padding(.horizontal)
        } else if weatherVM.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding()
        }
    }
   
    private func weatherIcon(for code: String) -> String {
        switch code {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.stars.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "smoke.fill"
        case "09d", "09n": return "cloud.rain.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "snow"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "questionmark"
        }
    }
}

    
#Preview {
    NavigationStack {
        AboutCityView(city: GeoLocationModel(
            locationName: "Paris",
            latitude: 48.8566,
            longitude: 2.3522
        ))
    }
}
