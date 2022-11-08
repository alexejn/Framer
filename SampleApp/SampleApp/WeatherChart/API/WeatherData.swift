//
//  WeatherData.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 04.09.2022.
//

import Foundation 
import Charts

struct WeatherData: Identifiable, Equatable, Hashable {
     
    var id: Date { datetime }
    
    let datetime: Date 
    let temp: Double
    let tempmax: Double
    let tempmin: Double
    let wind: Double?
    let snow: Double?
    let precipitation: Double?
    
}


extension WeatherData {
    static var sample: [WeatherData] {
        let today = Date.now
        let day: Double = 60 * 60 * 24
        let weekAgo = today.addingTimeInterval(-10 * day )
        let frameRange =  weekAgo...today
        let bins = DateBins(timeInterval: day, range: frameRange)
        let data = bins.thresholds.map { WeatherData(datetime: $0,
                                                     temp: .random(in: 0...50),
                                                     tempmax: .random(in: 25...30),
                                                     tempmin: .random(in: 20...25),
                                                     wind: .random(in: 0...17),
                                                     snow: .random(in: 0...17),
                                                     precipitation: .random(in: 0...30)) }
        return data
    }
}
