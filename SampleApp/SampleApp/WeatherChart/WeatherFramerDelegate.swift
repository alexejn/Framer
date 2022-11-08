//
//  WeatherTapeControllerDelegate.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 04.09.2022.
//

import Foundation
import Framer
import Charts

final class WeatherFramerDelegate: FramerDelegate {

    let api: WeatherApi = .mock
    var hasMoreRight: Bool = true
    var hasMoreLeft: Bool = true
    var scale: WeatherScale

    init(scale: WeatherScale) {
        self.scale = scale
    }

    
    func shouldLoadLeft(remainsToEnd: Int, frameLength: Int) -> Bool {
        hasMoreLeft && remainsToEnd <= 0
    }
     
    func shouldLoadRight(remainsToEnd: Int, frameLength: Int) -> Bool {
        hasMoreRight && remainsToEnd <= 0
    }
    
    func load(frameRange: inout Range<Int>) async throws -> [WeatherData] {
        print("load \(frameRange)")
        let initLoadPeriod = scale.initLoadPeriod
        do {
            let result = try await api.load(period: initLoadPeriod, scale: scale)
            let todayIndex = result.firstIndex { data in
                Calendar.current.compare(data.datetime, to: .now, toGranularity: scale.component) == .orderedSame
            }

            frameRange = result.indices.offset(low: 1, up: -1)

            return result
        } catch {
            throw error
        }
    }
    
    func loadLeft(lastLeft: WeatherData, frameLenght: Int) async throws -> [WeatherData] {
        
        let periodEnd = Calendar.current.date(byAdding: scale.component, value: -1, to: lastLeft.datetime)!
        let periodStart = Calendar.current.date(byAdding: scale.component, value: -frameLenght, to: periodEnd)!
        
        do {
            print("loadLeft \(periodStart...periodEnd)")
            return try await api.load(period: periodStart...periodEnd, scale: scale)
        } catch {
            hasMoreLeft = false
            throw error
        }
    }
     
    func loadRight(lastRight: WeatherData, frameLenght: Int) async throws -> [WeatherData] {
        let periodStart = Calendar.current.date(byAdding: scale.component, value: 1, to: lastRight.datetime)!
        let periodEnd = Calendar.current.date(byAdding: scale.component, value: frameLenght, to: periodStart)!

        do {
            print("loadRight \(periodStart...periodEnd)")
            let data = try await api.load(period: periodStart...periodEnd, scale: scale)
            self.hasMoreRight = hasMoreRight(requested: periodEnd, data: data)
            return data
        } catch {
            hasMoreRight = false
            throw error
        }
    }
    
    func hasMoreRight(requested: Date, data: [WeatherData]) -> Bool {
        if data.isEmpty { return false }
        let last = data.last!
        return Calendar.current.compare(requested, to: last.datetime, toGranularity: scale.component) != .orderedDescending
    }
}

fileprivate extension WeatherScale {
    var initLoadPeriod: ClosedRange<Date> {
        var start: Date!
        var end: Date!

        switch self {
        case .hourly:
            end = Calendar.current.date(byAdding: .hour, value: 6, to: .now)!
            start = Calendar.current.date(byAdding: .hour, value: -4, to: .now)!
        case .daily:
            end = Calendar.current.date(byAdding: .day, value: 10, to: .now)!
            start = Calendar.current.date(byAdding: .day, value: -10, to: .now)!
        case .monthly:
            end = Calendar.current.date(byAdding: .month, value: 2, to: .now)!
            start = Calendar.current.date(byAdding: .month, value: -16, to: .now)!
        }

        return start...end
    }
}
