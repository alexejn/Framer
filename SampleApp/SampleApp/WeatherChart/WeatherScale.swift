//
//  WeatherScale.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 28.09.2022.
//

import Foundation

enum WeatherScale: String {
    case daily
    case hourly
    case monthly
}

extension WeatherScale {
    var component: Calendar.Component {
        switch self {
            case .daily: return .day
            case .hourly: return .hour
            case .monthly: return .month
        }
    }
}
