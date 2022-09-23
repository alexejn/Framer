//
//  WeatherChart.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 04.09.2022.
//

import SwiftUI
import Charts
import Framer

struct WeatherRangeMark: ChartContent {
    let index: Int
    let tempmin: Double
    let tempmax: Double
    
    var body: some ChartContent {
        Plot {
            BarMark(
                x: .value("index", Double(index)),
                yStart: .value("Min", tempmin),
                yEnd: .value("Max", tempmax),
                width: .automatic
            )
        }
    }
}

struct WeatherChart: View {
    
    @ObservedObject var model: WeatherChartModel
    @ObservedObject var controller: FramerActor<WeatherData>
     
    @State var oldXRange: ClosedRange<Double>?
    
    init(model: WeatherChartModel) {
        self.model = model
        self.controller = model.controller
    }

    let gradient = LinearGradient(colors: [.red, .orange, .yellow, .teal, .blue, .indigo],
                                  startPoint: .top,
                                  endPoint: .bottom)
    
    private var gradientedPlot: some ChartContent {
        RectangleMark(
            xStart: .value("hour", model.xRange.lowerBound),
            xEnd: .value("hour", model.xRange.upperBound),
            yStart: .value("min", model.yRange.lowerBound),
            yEnd: .value("max", model.yRange.upperBound)
        )
        .foregroundStyle(gradient)
    }
    
    private func annotation(_ temp: Double) -> some View {
        Text("\(Int(temp))")
            .foregroundColor(.black)
            .font(.caption)
    }
    
    private func xAxisMarks() -> some AxisContent {
        AxisMarks(values: .automatic(desiredCount: 10)) { value in
            if let (date, format, preception, snow) = model.getAxisMarkConfig(value: value) {
                
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    VStack(alignment: .leading) {
                        if let p = preception, p > 0 {
                            Image(systemName: "cloud.rain.fill")
                        } else if let p = snow, p > 0 {
                            Image(systemName: "cloud.snow.fill")
                        } else {
                            Image(systemName: "sun.max.fill")
                        }
                        Text(date, format: .dateTime.weekday(.short))
                        Text(date, format: format)
                    }
                    .foregroundColor(Calendar.current.compare(date, to: .now, toGranularity: .day) == .orderedSame ? .red : .gray)
                }
            }
        }
    }
    
    private func yAxisMarks() -> some AxisContent {
        AxisMarks(preset: .inset, values:  .automatic(desiredCount: 6)) { value in
            if let temp = value.as(Double.self) {
                
                AxisGridLine(stroke: Int(temp) == 0 ? StrokeStyle(lineWidth: 1, dash: [10, 10]): nil ).foregroundStyle( Int(temp) == 0 ? .indigo : .gray)
                AxisTick()
                AxisValueLabel("\(Int(temp))°C")
                    .foregroundStyle( Int(temp) == 0 ? .indigo : .gray ) 
            }
        }
    }
    
    var windChart: some View {
        Chart {
            ForEach(controller.frameSlice) {
                let index = controller.frameSlice.firstIndex(of: $0)!
                let element = $0
                LineMark(x: .value("inedx", Double(index)) ,
                         y: .value("widn", element.wind ?? 0))
                .foregroundStyle(.red)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 10)) { value in
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(preset: .inset, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let wind = value.as(Double.self) {
                        Text("\(Int(wind)) km/h")
                    }
                }
            }
        }
        .overlay(alignment: .topLeading, content: {
            Text("Wind km/h")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(4)
        }) 
        .chartXScale(domain: model.xRange)
        .chartYScale(domain: 0...20)
        .chartOverlay { chartProxy in
            GeometryReader { geometryProxy in
                scroll(chartProxy: chartProxy, geometryProxy: geometryProxy)
            }
        }
        .frame(height: 100)
    }
 
    var temperatureChart: some View {
        Chart { 
            gradientedPlot
                .mask {
                    ForEach(controller.frameSlice) {
                        let index = controller.frameSlice.firstIndex(of: $0)!
                        let element = $0
                        WeatherRangeMark(index: index,
                                         tempmin: element.tempmin,
                                         tempmax: element.tempmax)
                        .opacity(element.datetime > .now ? 0.5 : 1)
                    }
                }

            
            ForEach(controller.frameSlice) {
                let index = controller.frameSlice.firstIndex(of: $0)!
                let element = $0
                 
                WeatherRangeMark(index: index,
                                 tempmin: element.tempmin,
                                 tempmax: element.tempmax)
                .opacity(0)
                .annotation(position: .top) { annotation(element.tempmax)  }
                .annotation(position: .bottom)  { annotation(element.tempmin) }
                 
            }
        }
        .overlay(alignment: .topLeading, content: {
            VStack(alignment: .leading) {
                Text("Temperature °C") 
                Group {
                    Text("Min: \(model.minT)°C")
                    Text("Max: \(model.maxT)°C")
                }.opacity(0.7)
            }
            .padding(4)
            .font(.footnote)
            .foregroundColor(.gray)
        })
        .chartYScale(domain: model.yRange) 
        .chartXScale(domain: model.xRange)
        .chartOverlay { chartProxy in
            GeometryReader { geometryProxy in
                scroll(chartProxy: chartProxy, geometryProxy: geometryProxy)

            }
        }
        .overlay(alignment: .center) {
            if case .loading = controller.state {
                ProgressView()
            }
        }
        .overlay(alignment: .leading) {
            if case .loading = controller.leftState {
                ProgressView().padding()
            }

        }
        .overlay(alignment: .trailing) {
            if case .loading = controller.rightState {
                ProgressView().padding()
            }
        }
        .chartXAxis(content: xAxisMarks)
        .chartYAxis(content: yAxisMarks)
        .frame(height: 300)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            temperatureChart
            windChart
        }
        .task {
            let isEmpty = await model.controller.isEmpty
            if isEmpty { await model.refresh() }
        }
        .navigationTitle("Moscow")
    }
    
    
    
    private func scroll(chartProxy: ChartProxy, geometryProxy: GeometryProxy) -> some View {
        Rectangle().fill(.clear).contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if oldXRange == nil { oldXRange = model.xRange }
                        let k = value.translation.width / geometryProxy[chartProxy.plotAreaFrame].width
                        model.xRange = oldXRange!.offset(distancePercents: -k)
                    }
                    .onEnded { _ in
                        oldXRange = nil
                        Task {
                            await model.refreshYRange()
                        } 
                    }
            )
    }
}

struct WeatherChart_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            Section {
                WeatherChart(model: WeatherChartModel(tape: Tape(WeatherData.sample)))
            }
            Spacer()
        }
    }
}

