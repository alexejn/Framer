//
//  File.swift
//  
//
//  Created by Alexey Nenastev on 13.09.2022.
//

import Foundation

@dynamicMemberLookup
public struct CollectionComparators<Element> {

    private var analysis: [String : Element?] = [:]

    public typealias Comparator = (Element, Element) -> Bool

    let comparators: [String: Comparator]

    public subscript(dynamicMember member: String) -> Element? {
        return analysis[member, default: nil]
    }

    public mutating func set(collection: [Element]) {
        for (k,v) in comparators {
            analysis[k] = collection.min(by: v)
        }
    }

    public init(comparators: [String: Comparator]) {
        self.comparators = comparators
    }
}

@dynamicMemberLookup
public struct CollectionReducers<Element, Result> {

    private var analysis: [String : Result] = [:]

    public typealias Reducer = (Result, Element) -> Result

    let reducers: [String: (initial: Result, Reducer)]

    public subscript(dynamicMember member: String) -> Result {
        if let result = analysis[member] {
            return result
        } else {
            return reducers[member]!.initial
        }
    }

    public mutating func set(collection: [Element]) {
        for (k,v) in reducers {
            analysis[k] = collection.reduce(v.initial, v.1)
        }
    }

    public init(reducers: [String: (initial: Result, Reducer)]) {
        self.reducers = reducers
    }
}
