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

 
typealias WeaterDataCollection = Slice<Tape<WeatherData>>


final class WeatherViewModel: ObservableObject  {
    
    private let controller: FramerActor<WeatherData>
    private let delegate: WeatherFramerDelegate
    private var cancellable: AnyCancellable?

    var providerInfo: WeatherProviderInfo { delegate.api.info }
    var weatherScale: WeatherScale
    @Published var xRange: ClosedRange<Double>  
    var oldXRange: ClosedRange<Double>?
    @Published private(set) var yRange: ClosedRange<Double>  = -10...40

    @Published private(set) var weatherData: Slice<Tape<WeatherData>> {
        didSet {
            print("\(weatherData.startIndex)..<\(weatherData.endIndex)")
//            print(weatherData)
        }
    }

    @Published private(set) var featureDataIsLoading: Bool = false
    @Published private(set) var pastDataIsLoading: Bool = false
    @Published private(set) var isLoading: Bool = false

    init(tape: Tape<WeatherData> = Tape(), weatherScale: WeatherScale = .daily) {
        let delegate = WeatherFramerDelegate(scale: weatherScale)
        let initRange = tape.indices
        let controller = FramerActor(tape: tape, delegate: delegate, frameRange: initRange)
        self.weatherData = controller.frameSlice 
        self.delegate = delegate
        self.controller = controller
        self.weatherScale = weatherScale
        self.xRange = controller.frameRange.closed.double

        controller.$state
            .map { $0.isloading }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        controller.$leftState
            .map { $0.isloading }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$pastDataIsLoading)

        controller.$rightState
            .map { $0.isloading }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$featureDataIsLoading)
    }

    func reload(with scale: WeatherScale) async {
        cancellable = nil
        delegate.scale = scale
        await controller.load()

        await MainActor.run {
            withAnimation {
                self.weatherData = controller.frameSlice
                self.weatherScale = scale
                self.xRange = controller.frameRange.closed.double
            }
        }

        cancellable = controller.$frameSlice
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .assign(to: \.weatherData, on: self)
    }

    func change(xRangeTo xRange: ClosedRange<Double>) {
        let frameRange = xRange.intWideRounding.range
        print("frameRange \(frameRange)")
        controller.setFrameRange(frameRange)
    }

 

//    func setYRange(_ range: ClosedRange<Double>) {
//        guard range != yRange else { return }
//        yRange = range
//    }

    func refreshYRange() {
        guard let first = weatherData.first else { return }

        var minT = first.tempmin
        var maxT = first.tempmax
        let count = Double(weatherData.count)
        var avgMin:Double = 0
        var avgMax:Double = 0

        for v in weatherData {
            minT =  min(v.tempmin, minT)
            maxT =  max(v.tempmax, maxT)
            avgMin += first.tempmin / count
            avgMax += first.tempmax / count
        }

        let newLow = minT.ceil(to: 5) - 10
        let newup = maxT.floor(to: 5) + 10
        let newRange = newLow...newup
        withAnimation {
//            setYRange(newRange)
        }
    }


}




