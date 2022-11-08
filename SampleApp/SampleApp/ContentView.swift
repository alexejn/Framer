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
                    WeatherView(vm: WeatherViewModel())
                    .padding(.top, 20)
                }
                Spacer()
            }
        }.onAppear {  

        }
        
    }
}
 
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
       ContentView()
    }
}
