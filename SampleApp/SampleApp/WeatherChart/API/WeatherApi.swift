//
//  WeatherApi.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 29.09.2022.
//

import Foundation

protocol WeatherApi {
    var info: WeatherProviderInfo { get }
    func load(period: ClosedRange<Date>, scale: WeatherScale) async throws  -> [WeatherData]
}

struct WeatherProviderInfo {
    let region: String
    let provider: String
}
