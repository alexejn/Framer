//
//  File.swift
//  
//
//  Created by Alexey Nenastev on 04.09.2022.
//
import XCTest
import Foundation
import Framer

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

extension Range<Int> {
    func moveTo(left: Int = 0, right: Int = 0) -> Range<Int> {
        (self.lowerBound - left + right)..<(self.upperBound - left + right)
    }
    
    mutating func movedTo(left: Int = 0, right: Int = 0){
        self = moveTo(left: left, right: right)
    }
     
    func set(leftTo: Int? = nil, rightTo: Int? = nil) -> Range<Int> {
        (leftTo ?? self.lowerBound)..<(rightTo ?? self.upperBound)
    }
    
    mutating func setted(leftTo: Int? = nil, rightTo: Int? = nil){
        self = set(leftTo: leftTo, rightTo: rightTo)
    } 
}

extension FramerActor {

    @MainActor
    func setRange(leftTo: Int? = nil, rightTo: Int? = nil) async {
        var frameRange = await self.frameRange
        frameRange.setted(leftTo: leftTo, rightTo: leftTo)
        await self.setFrameRange(frameRange)
    }
}

extension Slice {
    var array: [Element] { Array(self) }
}

extension XCTestExpectation {
    
    static var failIfCalled: XCTestExpectation {
        let x =  XCTestExpectation()
        x.isInverted = true
        return x
    }
    
    static func shouldCalled(count: Int = 1) -> XCTestExpectation {
        let x =  XCTestExpectation()
        x.expectedFulfillmentCount = count
        return x
    }
}
