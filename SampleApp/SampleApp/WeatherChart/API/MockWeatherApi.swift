//
//  MockWeatherApi.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 29.09.2022.
//

import Charts
import Foundation

final class MockWeatherApi: WeatherApi {

    let info = WeatherProviderInfo(region: "Random", provider: "Mock")
    
    private func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }

    func load(period: ClosedRange<Date>, scale: WeatherScale) async throws  -> [WeatherData] {
        try await sleep(seconds: 0.02)

        let bins = DateBins(unit: scale.component, range: period)

        let tempMinLow = Double.random(in: -10...10)

        let data = bins.thresholds.map {

            let tempMin = Double.random(in: tempMinLow...10)
            let tempMax = Double.random(in: tempMin...tempMin+20)

            return WeatherData(datetime: $0,
                        temp: (tempMin+tempMax) / 2,
                        tempmax: tempMax,
                        tempmin: tempMin,
                        wind: .random(in: 0...17),
                        snow: .random(in: 0...17),
                        precipitation: .random(in: 0...30))
        }

        return data
    }
}

extension WeatherApi where Self == MockWeatherApi {
    static var mock: WeatherApi { MockWeatherApi() }
}
