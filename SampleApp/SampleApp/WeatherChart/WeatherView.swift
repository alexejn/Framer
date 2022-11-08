//
//  WeatherChart.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 04.09.2022.
//

import SwiftUI
import Charts
import Framer

struct WeatherView: View {
    
    @StateObject var model: WeatherViewModel

    @State var temperatureChartKind: TemperatureChart.Kind = .line
    @State var weatherScale: WeatherScale 

    init(vm: WeatherViewModel) {
        self._model = StateObject(wrappedValue: vm)
        self.weatherScale = vm.weatherScale
    }

    var body: some View { 
        VStack(alignment: .leading, spacing: 0) {
            TemperatureChart(kind: $temperatureChartKind,
                             data: model.weatherData,
                             yRange: model.yRange,
                             weatherScale: model.weatherScale)
                .overlay(alignment: .center) {
                    if model.isLoading  {
                        ProgressView()
                    }
                }
                .overlay(alignment: .leading) {
                    if model.pastDataIsLoading {
                        ProgressView().padding()
                    }

                }
                .overlay(alignment: .trailing) {
                    if model.featureDataIsLoading {
                        ProgressView().padding()
                    }
                }

            AnimatableWindChart(data: model.weatherData)
            Text(model.providerInfo.provider)
                .font(.subheadline).padding()
            
            Spacer()
        }
//        .drawingGroup()
        .chartXScale(domain: model.xRange)
        .chartOverlay { chartProxy in
            GeometryReader { geometryProxy in
                scroll(chartProxy: chartProxy, geometryProxy: geometryProxy)
            }
        }
        .disabled(model.isLoading)
        .navigationTitle(model.providerInfo.region)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    reload(with: weatherScale)
                } label: {
                    Image(systemName: "goforward")
                }
            }

            ToolbarItem(placement: .principal) {
                Picker("", selection: $weatherScale) {
                    Text(WeatherScale.hourly.rawValue.capitalized)
                        .tag(WeatherScale.hourly)
                    Text(WeatherScale.daily.rawValue.capitalized)
                        .tag(WeatherScale.daily)
                    Text(WeatherScale.monthly.rawValue.capitalized)
                        .tag(WeatherScale.monthly)
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Picker("", selection: $temperatureChartKind) {
                    Text(TemperatureChart.Kind.line.rawValue.capitalized)
                        .tag(TemperatureChart.Kind.line)
                    if weatherScale != .hourly  {
                        Text(TemperatureChart.Kind.bar.rawValue.capitalized)
                        .tag(TemperatureChart.Kind.bar)
                    }
                    Text(TemperatureChart.Kind.area.rawValue.capitalized)
                    .tag(TemperatureChart.Kind.area)
                }
                .animation(.default, value: weatherScale)
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .onChange(of: weatherScale, perform: { newValue in
            if weatherScale == .hourly {
                temperatureChartKind = .line
            }
            reload(with: newValue)
        })
        .task { 
            if model.weatherData.isEmpty {
                reload(with: weatherScale)
            }
        }
    }

    func reload(with scale: WeatherScale) {
        Task { @MainActor in
            await model.reload(with: scale)
        }
    }

    private func scroll(chartProxy: ChartProxy, geometryProxy: GeometryProxy) -> some View {
        Rectangle().fill(.clear).contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if model.oldXRange == nil { model.oldXRange =  model.xRange }
                        let k = value.translation.width / geometryProxy[chartProxy.plotAreaFrame].width
                        model.xRange = model.oldXRange!.offset(distancePercents: -k)
                        model.change(xRangeTo: model.xRange)
                    }
                    .onEnded { _ in
                        model.oldXRange = nil
                    }
            )
    }
}

struct WeatherChart_Previews: PreviewProvider { 
    static var previews: some View {
        NavigationStack {
            VStack {
                Section {
                    WeatherView(vm: WeatherViewModel(tape: Tape(WeatherData.sample)))
                }.padding(.top, 20)
                Spacer()
            }
        }
    }
}

