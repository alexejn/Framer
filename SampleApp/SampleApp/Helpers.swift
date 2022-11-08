//
//  Helpers.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 06.09.2022.
//

import Foundation

extension Int: Identifiable {
    public var id: Int { self }
}

extension Double {
    func ceil(to val: Double ) -> Double {
        let divideByTen = self / val
        let multiByTen = (Foundation.ceil(divideByTen) * val)
        return multiByTen
    }
    
    func floor(to val: Double) -> Double {
        let divideByTen = self / val
        let multiByTen = (Foundation.floor(divideByTen) * val)
        return multiByTen
    }
}

extension Slice where Index == Int {
    subscript(safe index: Int) -> Element? {
        guard self.startIndex <= index && index < self.endIndex else { return nil}
        return self[index]
    }
}

extension Double {
    var int: Int { Int(self) }
}

extension Optional  {
    func val(or: String) -> String {
        guard let val = self else { return or }
        return "\(val)"
    }

    func value<T>(of: KeyPath<Wrapped, T>, or: String) -> String {
        guard let val = self else { return or }
        return "\(val[keyPath: of])"
    }
}

extension Range where Bound == Int {
    var distance: Int { upperBound - lowerBound }

    var double: Range<Double> { Double(lowerBound)..<Double(upperBound) }

    var closed: ClosedRange<Int> {
        guard lowerBound < upperBound else { return lowerBound...lowerBound }
        return lowerBound...(upperBound - 1)
    }
    
    func offset(low: Int, up: Int) -> Self {
        lowerBound+low..<upperBound+up
    }
}

extension ClosedRange where Bound == Int {
    var double: ClosedRange<Double> { Double(lowerBound)...Double(upperBound) }
    
    var distance: Int { upperBound - lowerBound }
    
    var range: Range<Int> { lowerBound..<(upperBound+1) }
    
    func offset(low: Int, up: Int) -> Self {
        lowerBound+low...upperBound+up
    }
}
 
extension ClosedRange where Bound == Double {
    var distance: Double { upperBound - lowerBound }
    
    var int: ClosedRange<Int> { Int(lowerBound)...Int(upperBound) }

    var intWideRounding: ClosedRange<Int> { Int(floor(lowerBound))...Int(ceil(upperBound)) }

    func offset(_ val: Double) -> Self {
        lowerBound+val...upperBound+val
    }
    
    func offset(distancePercents: Double) -> Self {
        offset(distance * distancePercents)
    }
    
    func zoom(_ zoom: Double) -> Self {
        let offset = ((distance * zoom) - distance) / 2
        return lowerBound-offset...upperBound+offset
    }
}

