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
 
    let interval: TimeInterval = .day // 1 день
    var hasMoreRight: Bool = true
    var hasMoreLeft: Bool = true
    
    func shouldLoadLeft(remainsToEnd: Int, frameLength: Int) -> Bool {
        hasMoreLeft && remainsToEnd <= 0
    }
     
    func shouldLoadRight(remainsToEnd: Int, frameLength: Int) -> Bool {
        hasMoreRight && remainsToEnd <= 0
    }
    
    func load(frameRange: inout Range<Int>) async throws -> [WeatherData] {
        let periodEnd = Calendar.current.date(byAdding: .init(day: 10), to: .now)!
        let periodStart = Calendar.current.date(byAdding: .init(day: -10), to: .now)!
        print("load \(frameRange)")
        do {
            let result = try await MeteostatWeatherApi().load(period: periodStart...periodEnd)
            let todayIndex = result.firstIndex { data in
                Calendar.current.compare(data.datetime, to: .now, toGranularity: .day) == .orderedSame
            }

            if let todayIndex {
                frameRange = (todayIndex-1)..<todayIndex+9
            } else {
                frameRange = result.indices
            }

            return result
        } catch {
            throw error
        }
    }
    
    func loadLeft(lastLeft: WeatherData, frameLenght: Int) async throws -> [WeatherData] {
        
        let periodEnd = Calendar.current.date(byAdding: .init(day: -1), to: lastLeft.datetime)!
        let periodStart = Calendar.current.date(byAdding: .init(day: -frameLenght), to: periodEnd)!
        
        do {
            print("loadLeft \(periodStart...periodEnd)")
            return try await MeteostatWeatherApi().load(period: periodStart...periodEnd)
        } catch {
            hasMoreLeft = false
            throw error
        }
    }
     
    func loadRight(lastRight: WeatherData, frameLenght: Int) async throws -> [WeatherData] {
        let periodStart = Calendar.current.date(byAdding: .init(day: 1), to: lastRight.datetime)!
        let periodEnd = Calendar.current.date(byAdding: .init(day: frameLenght), to: periodStart)!
        
        do {
            print("loadRight \(periodStart...periodEnd)")
            let data = try await MeteostatWeatherApi().load(period: periodStart...periodEnd)
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
        return Calendar.current.compare(requested, to: last.datetime, toGranularity: .day) != .orderedDescending
    }
}
