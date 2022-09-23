//
//  File.swift
//  
//
//  Created by Alexey Nenastev on 04.09.2022.
//

import Foundation
import XCTest
@testable import Framer

struct LoadingError: Error {}
 
final class TestFramerDelegate: FramerDelegate {
    
    var loadLeftWhenRemainToLast = 2
    var loadRightWhenRemainToLast = 2
    
    var delayOnLoadingSec: Double = 0.5
    
    var leftLoadExpectation = XCTestExpectation()
    var rightLoadExpectation = XCTestExpectation()
    
    var throwErrorWhenLoadLeft: Error?
    var throwErrorWhenLoadRight: Error?
    
    //MARK: TapeControllerDelegate
    
    var hasMoreLeft: Bool = true
    var hasMoreRight: Bool = false
    
    func shouldLoadLeft(remainsToEnd: Int, frameLength: Int) -> Bool {
        guard hasMoreLeft else { return false }
        return remainsToEnd <= loadLeftWhenRemainToLast
    }
    
    func shouldLoadRight(remainsToEnd: Int, frameLength: Int) -> Bool {
        guard hasMoreRight else { return false }
        return remainsToEnd <= loadRightWhenRemainToLast
    }
    
    func loadLeft(lastLeft: Int, frameLenght: Int) async throws -> [Int] {
        leftLoadExpectation.expectationDescription = "Вызов loadLeft lastLeft: \(lastLeft) frameLength: \(frameLenght)"
        leftLoadExpectation.fulfill()
        try? await Task.sleep(seconds: delayOnLoadingSec)
        if let throwErrorWhenLoadLeft { throw throwErrorWhenLoadLeft }
        return (lastLeft-5..<lastLeft).map { $0 }
    }
    
    func loadRight(lastRight: Int, frameLenght: Int) async throws -> [Int] {
        rightLoadExpectation.expectationDescription = "Вызов loadRight lastLeft: \(lastRight) frameLength: \(frameLenght)"
        rightLoadExpectation.fulfill()
        try? await Task.sleep(seconds: delayOnLoadingSec)
        if let throwErrorWhenLoadRight { throw throwErrorWhenLoadRight }
        return (lastRight+1...lastRight+6).map { $0 }
    }
}
