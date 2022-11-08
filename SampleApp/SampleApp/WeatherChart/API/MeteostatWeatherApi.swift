//
//  MeteostatWeatherApi.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 29.09.2022.
//

import Foundation

final class MeteostatWeatherApi: WeatherApi {

    let xRapidAPIKey = "e8d23099c7mshbbf5b845065b073p1775aajsnb16b52485bd0"
                     //"8cede6d95bmsh1282c5181af9084p10a0d8jsn77986609b3cf"
    let station = "27612" // Moscow

    let info = WeatherProviderInfo(region: "Moscow", provider: "https://meteostat.net")

    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        return dateFormatter
    }()

    func load(period: ClosedRange<Date>, scale: WeatherScale) async throws  -> [WeatherData] {

        var url = URL(string: "https://meteostat.p.rapidapi.com/stations/\(scale)")!
        let start = dateFormatter.string(from: period.lowerBound)
        let end = dateFormatter.string(from: period.upperBound)
        url.append(queryItems: [
            URLQueryItem(name: "station", value: "27612"),
            URLQueryItem(name: "start", value: start),
            URLQueryItem(name: "end", value: end)
        ])

        var request = URLRequest(url: url)
        request.setValue("meteostat.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(xRapidAPIKey, forHTTPHeaderField: "x-rapidapi-key")

        let (data, response) = try await URLSession.shared.data(for: request)

        do {
            switch scale {
            case .daily : return try decode(data: data, Daily.self)
            case .hourly : return try decode(data: data, Hourly.self)
            case .monthly : return try decode(data: data, Monthly.self)
            }
        } catch {
            if let resp = response as? HTTPURLResponse {
                print("Response: \(resp)")
            }
            if let json = String(data: data, encoding: .utf8)  {
                print("Data: \(json)")
            }
            print("Error: \(error)")
            throw error
        }

    }

    fileprivate func decode<T: WetherResponseRow>(data: Data,
                                                  _ type: T.Type) throws -> [WeatherData] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(T.dateFormatter)
        let result = try decoder.decode(Response<T>.self, from: data)
        return result.data.compactMap { $0.weatherData }
    }
}

fileprivate protocol WetherResponseRow: Decodable {
    var weatherData: WeatherData? { get }
    static var dateFormatter: DateFormatter { get }
}

fileprivate struct Response<Row: WetherResponseRow>: Decodable {
    var data: [Row]
    var weatherData: [WeatherData] { data.compactMap { $0.weatherData }}
}

fileprivate typealias Monthly = Daily

fileprivate struct Daily: WetherResponseRow {
    let date: Date
    let tmin: Double?
    let tmax: Double?
    let tavg: Double?
    let wspd: Double?
    let prcp: Double?
    let snow: Double?

    var weatherData: WeatherData? {
        guard   let tmin = tmin,
                let tmax = tmax,
                let tavg = tavg else { return nil }
        return WeatherData(datetime: date,
                           temp: tavg,
                           tempmax: tmax,
                           tempmin: tmin,
                           wind: wspd,
                           snow: snow,
                           precipitation: prcp )
    }

    static let dateFormatter: DateFormatter  = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        return dateFormatter
    }()
}

fileprivate struct Hourly: WetherResponseRow {
    let time: Date
    let temp: Double?
    let wspd: Double?
    let prcp: Double?
    let snow: Double?

    var weatherData: WeatherData? {
        guard   let temp = temp else { return nil }
        return WeatherData(datetime: time,
                           temp: temp,
                           tempmax: temp,
                           tempmin: temp,
                           wind: wspd,
                           snow: snow,
                           precipitation: prcp )
    }

    static let dateFormatter: DateFormatter  = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        return dateFormatter
    }()
}

extension WeatherApi where Self == MeteostatWeatherApi {
    static var meteostat: WeatherApi { MeteostatWeatherApi() }
}
