//
//  WindChart.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 29.09.2022.
//

import SwiftUI
import Charts
import Framer

struct AnimatableWindChart: View, Animatable {

    let points: [CGPoint]
    init(data: WeaterDataCollection) {
        let points = data.map { point in
            let index = data.firstIndex(of: point)!
            return CGPoint(x: CGFloat(index), y: CGFloat(point.wind ?? 0))
        }
        self.points = points
    }

    var body: some View {
        Chart {
            let _ = Self._printChanges()
            ForEach(points, id: \.x) { data in
                let x = Double(data.x)
                let y = Double(data.y)
                LineMark(x: .value("inedx", x),
                         y: .value("widn", y))
                .interpolationMethod(.catmullRom)
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
        .chartYScale(domain: 0...20)
        .frame(height: 100)
    }

}

struct WindChart: View {

    let data: WeaterDataCollection

    
    var body: some View {
        Chart {
            let _ = Self._printChanges()
            ForEach(data) {
                let index = data.firstIndex(of: $0)!
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
        .chartYScale(domain: 0...20)
        .frame(height: 100)
    }

}

struct WindChart_Previews: PreviewProvider {
    static var previews: some View {
        WindChart(data: Slice(base: Tape(WeatherData.sample), bounds: 0..<6))
    }
}

public extension ShapeStyle where Self == Color {
    static var debug: Color {
#if DEBUG
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
#else
        return Color(.clear)
#endif
    }
}
