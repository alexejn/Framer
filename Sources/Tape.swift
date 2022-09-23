//
//  BidirectionalArray.swift
//  BCS
//
//  Created by Alexey Nenastev on 26.08.2022.
//

import Foundation
 
public struct Tape<Element> {
   
    var internalArray: [Element]
    var zeroIndexOffset: Int
    
    public init(_ collection: [Element] = []) {
        internalArray = collection
        zeroIndexOffset = collection.startIndex
    }
    
    mutating func append(atLeft: [Element]) {
        internalArray = atLeft + internalArray
        zeroIndexOffset += atLeft.count
    }
    
    mutating func append(atRight: [Element]) {
        internalArray.append(contentsOf: atRight)
    }
    
    mutating func append(side: TapeSide,  elements: [Element]) {
        switch side {
        case .left: append(atLeft: elements)
        case .right: append(atRight: elements)
        }
    }
      
    var left: Element? { internalArray.first }
    var right: Element? { internalArray.last }
 
    func safeRange(range: Range<Int>) -> Range<Int> {
         indices.clamped(by: range)
    }
     
    public subscript(safe bounds: Range<Int>) -> Slice<Tape<Element>> {
        return self[safeRange(range: bounds)]
    }
    
    func printDebug() {
        print("\(self) s: \(startIndex) e: \(endIndex) c: \(count)")
    }
    
    var array: [Element] { Array(self) }
}

extension Tape: Equatable where Element: Equatable {}

extension Tape: Collection {
    public var startIndex: Int { internalArray.startIndex - zeroIndexOffset }
    public var endIndex: Int { internalArray.endIndex - zeroIndexOffset }
    
    public subscript(position: Int) -> Element {
        precondition((startIndex ..< endIndex).contains(position), "out of bounds")
        return internalArray[position + zeroIndexOffset]
    }
    
    public func index(after i: Int) -> Int {
        i+1
    }
}

extension Tape: BidirectionalCollection {
    public func index(before i: Int) -> Int {
        i-1
    }
}

extension Tape: RandomAccessCollection {}

extension Tape: CustomStringConvertible {
    public var description: String { internalArray.description }
}

enum TapeSide {
    case left
    case right
}
