//
//  File.swift
//  
//
//  Created by Alexey Nenastev on 04.09.2022.
//

import Foundation

public protocol FramerDelegate<Element> {
    associatedtype Element
    
    func loadLeft(lastLeft: Element, frameLenght: Int) async throws -> [Element]
    func loadRight(lastRight: Element, frameLenght: Int) async throws -> [Element]
     
    func shouldLoadLeft(remainsToEnd: Int, frameLength: Int) -> Bool
    func shouldLoadRight(remainsToEnd: Int, frameLength: Int) -> Bool
    
    func load(frameRange: inout Range<Int>) async throws -> [Element]
}

public extension FramerDelegate {
     
    func shouldLoadLeft(remainsToEnd: Int, frameLength: Int) -> Bool { false }
    func shouldLoadRight(remainsToEnd: Int, frameLength: Int) -> Bool { false }
     
    func loadLeft(lastLeft: Element, frameLenght: Int) async throws -> [Element] { [] }
    func loadRight(lastRight: Element, frameLenght: Int) async throws -> [Element] { [] }
    
    func load(frameRange: inout Range<Int>) async throws -> [Element] { [] }
}
