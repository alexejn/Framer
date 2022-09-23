//
//  ContentView.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 04.09.2022.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        NavigationStack {
            VStack {
                Section {
                    WeatherChart(model: WeatherChartModel())
                }
                Spacer()
            } 
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
