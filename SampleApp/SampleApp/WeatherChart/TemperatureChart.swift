//
//  TemperatureChart.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 29.09.2022.
//

import SwiftUI
import Framer
import Charts


struct TemperatureChart: View, Animatable {
    @Binding var kind: Kind
    let data: WeaterDataCollection
    let yRange: ClosedRange<Double>
    let weatherScale: WeatherScale
 
    private var minT: String {
        guard let temp = data.min(by: { $0.tempmin < $1.tempmin })?.tempmin else { return "-"}
        return "\(Int(temp))°C"
    }

    private var maxT: String {
        guard let temp = data.max(by: { $0.tempmax > $1.tempmax })?.tempmax else { return "-"}
        return "\(Int(temp))°C"
    }

    enum Kind: String {
        case bar
        case line
        case area
    }

    @ChartContentBuilder
    private func buildMark(kind: Kind, element: WeaterDataCollection.Element) -> some ChartContent {

        let index = data.firstIndex(of: element)!
        switch kind {
        case .line:
                LineMark(x: .value("", index),
                         y: .value("", element.temp))

                PointMark(x: .value("", index),
                          y: .value("", element.temp))
                .opacity(element.datetime > .now ? 0.5 : 1)
                .annotation { annotation(element.temp)  }

        case .bar:
                TemperatureRangeMark(index: index,
                                     tempmin: element.tempmin,
                                     tempmax: element.tempmax)
                .opacity(element.datetime > .now ? 0.5 : 1)
                .annotation(position: .top) { annotation(element.tempmax)  }
                .annotation(position: .bottom)  { annotation(element.tempmin)  }
        case .area:
                AreaMark(x: .value("", index),
                         yStart: .value("", element.tempmin),
                         yEnd: .value("", element.tempmax))
                .interpolationMethod(.cardinal)
        }
    }

    var body: some View {
        let _ = Self._printChanges()
        Chart {
            ForEach(data) {
                buildMark(kind: kind, element: $0)
            }
            .alignsMarkStylesWithPlotArea()
        }
        .foregroundStyle(gradient)
        .animation(.default, value: kind)
        .overlay(alignment: .topLeading, content: {

            VStack(alignment: .leading) {
                Text("Temperature °C")
                Group {
                    Text("Min: \(minT)")
                    Text("Max: \(maxT)")
                }.opacity(0.7)
            }
            .padding(4)
            .font(.footnote)
            .foregroundColor(.gray)
        })
//        .chartYScale(domain: .automatic)
        .chartXAxis(content: xAxisMarks)
        .chartYAxis(content: yAxisMarks)
        .frame(height: 300)
    }

    let gradient = LinearGradient(colors: [.red, .orange, .yellow, .teal, .blue, .indigo],
                                  startPoint: .top,
                                  endPoint: .bottom)

    private var gradientedPlot: some ChartContent {
        return RectangleMark(
            xStart: .value("hour", data.startIndex),
            xEnd: .value("hour", data.endIndex),
            yStart: .value("min", yRange.lowerBound),
            yEnd: .value("max", yRange.upperBound)
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
            if let params = getAxisMarkConfig(value: value) {
                AxisGridLine()
                    .foregroundStyle(params.isCurrent ? .red.opacity(0.5) : .gray)
                AxisTick()
                AxisValueLabel {
                    VStack(alignment: .leading) {
                        if let p = params.precipitation, p > 0 {
                            Image(systemName: "cloud.rain.fill")
                        } else if let p = params.snow, p > 0 {
                            Image(systemName: "cloud.snow.fill")
                        } else {
                            Image(systemName: "sun.max.fill")
                        }

                        Text(params.datetime, format: params.format1)
                        if let format2 = params.format2 {
                            Text(params.datetime, format: format2)
                        }
                    }
                    .foregroundStyle(params.isCurrent ? .red : .gray)
                }
            }
        }
    }

    private func yAxisMarks() -> some AxisContent {
        AxisMarks(preset: .inset, values:  .automatic(desiredCount: 6)) { value in
            if let temp = value.as(Double.self) {

                AxisGridLine(stroke: Int(temp) == 0 ? StrokeStyle(lineWidth: 1, dash: [2, 2]) : StrokeStyle(lineWidth: 0.5) )
                    .foregroundStyle( Int(temp) == 0 ? .indigo : Color.gray.opacity(0.6))
                AxisValueLabel("\(Int(temp))°C")
                    .foregroundStyle( Int(temp) == 0 ? .indigo : .gray )
            }
        }
    }

    private func getAxisMarkConfig(value: AxisValue) -> XAxisMarksParams? {
        guard let index = value.as(Int.self) else { return nil }
        let frameSafeRange = data.indices

        var datetime: Date? = nil
        var precipitation: Double? = nil
        var snow: Double? = nil
        if let element = data[safe: index] {
            datetime = element.datetime
            precipitation = element.precipitation
            snow = element.snow
        } else {
            let distanceFromLower = frameSafeRange.lowerBound - index
            if distanceFromLower > 0, let first = data.first?.datetime {
                datetime = Calendar.current.date(byAdding: weatherScale.component, value: -distanceFromLower, to: first)
            }
            let distanceFromUpper = index - frameSafeRange.upperBound + 1
            if distanceFromUpper > 0, let last = data.last?.datetime {
                datetime = Calendar.current.date(byAdding: weatherScale.component, value: distanceFromUpper, to: last)
            }
        }

        guard let datetime else { return nil }

        let isCurrent = Calendar.current.compare(datetime, to: .now, toGranularity: weatherScale.component) == .orderedSame

        return .init(datetime: datetime,
                     format1: weatherScale.format1(for: datetime),
                     format2: weatherScale.format2(for: datetime),
                     precipitation: precipitation,
                     snow: snow,
                     isCurrent: isCurrent)
    }
}

fileprivate struct XAxisMarksParams {
    let datetime: Date
    let format1: Date.FormatStyle
    let format2: Date.FormatStyle?
    let precipitation: Double?
    let snow: Double?
    let isCurrent: Bool
}

private struct TemperatureRangeMark: ChartContent {
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


fileprivate extension WeatherScale {
    func format1(for date: Date) -> Date.FormatStyle  {
        switch self {
        case .daily:
            return .dateTime.weekday(.short)
        case .monthly:
            return .dateTime.month()
        case .hourly:
            return .dateTime.hour()
        }
    }

    func format2(for date: Date) -> Date.FormatStyle?  {
        switch self {
        case .daily:
            let isFirstDayOfMonth = Calendar.current.date(date, matchesComponents: DateComponents(day: 1))
            return isFirstDayOfMonth ? .dateTime.month(.abbreviated).day() : .dateTime.day()
        case .hourly:
            let isFirstHourOfMDay = Calendar.current.date(date, matchesComponents: DateComponents(hour: 0))
            return isFirstHourOfMDay ? .dateTime.weekday(.short).day() : nil
        case .monthly:
            return  .dateTime.year()
        }
    }
}

struct TemperatureChart_Previews: PreviewProvider {
    static let model = WeatherViewModel(tape:  Tape(WeatherData.sample))

    static var previews: some View {
        TemperatureChart(kind: .constant(.line),
                         data: model.weatherData,
//                         xRange: model.xRange,
                         yRange: model.yRange,
                         weatherScale: model.weatherScale)
    }
}
