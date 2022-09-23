//
//  File.swift
//  
//
//  Created by Alexey Nenastev on 04.09.2022.
//

import Foundation

extension Range where Bound == Int {
    var distance: Int { upperBound - lowerBound  }
    
    var closed: ClosedRange<Bound>? {
        guard lowerBound < upperBound else { return nil }
        return lowerBound...(upperBound - 1)
    }
    
    func clamped(by limits: Range<Int>) -> Self {
        if lowerBound > limits.upperBound { return lowerBound..<lowerBound }
        if upperBound < limits.lowerBound { return upperBound..<upperBound }
        return clamped(to: limits)
    }
    
    static func isMovedLeft(old: Range<Int>, new: Range<Int>) -> Bool {
        old.lowerBound > new.lowerBound
    }
    
    static func isMovedRight(old: Range<Int>, new: Range<Int>) -> Bool {
        old.upperBound < new.upperBound
    }
    
    var array: [Int] { Array(self) }
}
 
extension ClosedRange where Bound == Int {
    var distance: Int { upperBound - lowerBound  }
}
