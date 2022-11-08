//
//  SwiftUIView.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 29.09.2022.
//

import SwiftUI

struct SwiftUIView: View {
    @StateObject private var evilObject = EvilStateObject()

    var body: some View {
        let _ = Self._printChanges()
        Text("What could possibly go wrong?")
            .background(.debug)
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}

class EvilStateObject: ObservableObject {
    var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { _ in
            if Int.random(in: 1...5) == 1 {
                self.objectWillChange.send()
            }
        }
    }
}


