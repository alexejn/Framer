//
//  WeatherChartModel.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 04.09.2022.
//

import Framer
import Combine
import Charts
import Foundation
import SwiftUI

extension TimeInterval {
    static var day: Double { 60 * 60 * 24}
}


@MainActor
final class WeatherChartModel: ObservableObject  {
    
    let controller: FramerActor<WeatherData>
    let delegate: WeatherFramerDelegate
    private var cancellables: Set<AnyCancellable> = []
    
    @Published var xRange: ClosedRange<Double> {
        didSet {
            Task {
                await controller.setFrameRange(xRange.int.offset(low: -1, up: +1).range)
            }
        }
    }

    @Published var rangeAnalyzator = CollectionComparators<WeatherData>(comparators: ["minT": { $0.tempmin < $1.tempmin },
                                                                                      "maxT": { $0.tempmax > $1.tempmax }])

    @Published var yRange: ClosedRange<Double>  = -10...40
    @Published var info: RangeWeatherInfo? = nil

    var minT: String { rangeAnalyzator.minT.value(of: \.tempmin.int, or: "-") }
    var maxT: String { rangeAnalyzator.maxT.value(of: \.tempmax.int, or: "-") }

    struct RangeWeatherInfo {
        let minT: Double
        let maxT: Double
        let avgMinT: Double
        let avgMaxT: Double
    }

    init(tape: Tape<WeatherData> = Tape()) {
        let delegate = WeatherFramerDelegate()
        let initRange = tape.indices
        let controller = FramerActor(tape: tape, delegate: delegate, frameRange: initRange)
        
        self.delegate = delegate
        self.controller = controller
        self.xRange = initRange.closed.double


        Task {
            await self.controller.$frameSlice.sink { [weak self] slice in
                self?.rangeAnalyzator.set(collection: Array(slice))
            }.store(in: &cancellables)
        }
    }

    func refresh() async {
        await controller.load()
        let range = await controller.frameRange.closed.double
        setXRange(range)
        await refreshYRange()
    }

    func setXRange(_ range: ClosedRange<Double>) {
        guard range != xRange else { return }
        xRange = range
    }

    func setYRange(_ range: ClosedRange<Double>) {
        guard range != yRange else { return }
        yRange = range 
    }

    func refreshYRange() async {
        guard let first = controller.frameSlice.first else { return }

        var minT = first.tempmin
        var maxT = first.tempmax
        let count = Double(controller.frameSlice.count)
        var avgMin:Double = 0
        var avgMax:Double = 0

        for v in controller.frameSlice {
            minT =  min(v.tempmin, minT)
            maxT =  max(v.tempmax, maxT)
            avgMin += first.tempmin / count
            avgMax += first.tempmax / count
        }

        let newLow = minT.ceil(to: 5) - 10
        let newup = maxT.floor(to: 5) + 10
        let newRange = newLow...newup
        withAnimation {
            info = .init(minT: minT, maxT: maxT, avgMinT: avgMin, avgMaxT: avgMax)
            setYRange(newRange)
        }
    }

    func getAxisMarkConfig(value: AxisValue) -> (datetime: Date, format: Date.FormatStyle, precipitation: Double?, snow: Double?)? {
        guard let index = value.as(Int.self) else { return nil }
        let frameSafeRange = controller.frameSlice.indices
        
        var datetime: Date? = nil
        var precipitation: Double? = nil
        var snow: Double? = nil
        if let element = controller.frameSlice[safe: index] {
            datetime = element.datetime
            precipitation = element.precipitation
            snow = element.snow
        } else {
            let distanceFromLower = frameSafeRange.lowerBound - index
            if distanceFromLower > 0, let first = controller.frameSlice.first?.datetime {
                datetime = Calendar.current.date(byAdding: .init(day: -distanceFromLower), to: first)
            }
            let distanceFromUpper = index - frameSafeRange.upperBound + 1
            if distanceFromUpper > 0, let last = controller.frameSlice.last?.datetime {
                datetime = Calendar.current.date(byAdding: .init(day: distanceFromUpper ), to: last)
            }
        }
        
        guard let datetime else { return nil }
        
        let isFirstDayOfMonth = Calendar.current.date(datetime, matchesComponents: DateComponents(day: 1))
        _ = Calendar.current.date(datetime, matchesComponents: DateComponents(weekday: 1))
        
        let format: Date.FormatStyle = isFirstDayOfMonth ? .dateTime.month(.abbreviated) : .dateTime.day()
        return (datetime: datetime, format: format, precipitation: precipitation, snow: snow)
    }
}

