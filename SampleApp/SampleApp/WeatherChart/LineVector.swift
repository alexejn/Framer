//
//  LineVector.swift
//  SampleApp
//
//  Created by Alexey Nenastev on 30.09.2022.
//

import Foundation
import enum Accelerate.vDSP
import SwiftUI
import OSLog

struct AnimatableVector: VectorArithmetic {
    var values: [Float]
    var indicies: [Int]

    static var zero = AnimatableVector(values: [0.0], indicies: [0])

    static func + (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        let count = min(lhs.values.count, rhs.values.count)
        return AnimatableVector(
            values: vDSP.add(
                lhs.values[0..<count],
                rhs.values[0..<count]
            ),
            indicies: lhs.indicies
        )
    }

    static func += (lhs: inout AnimatableVector, rhs: AnimatableVector) {
        let count = min(lhs.values.count, rhs.values.count)
        vDSP.add(
            lhs.values[0..<count],
            rhs.values[0..<count],
            result: &lhs.values[0..<count]
        )
    }

    static func - (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        let count = min(lhs.values.count, rhs.values.count)
        return AnimatableVector(
            values: vDSP.subtract(
                lhs.values[0..<count],
                rhs.values[0..<count]
            ),
            indicies: lhs.indicies
        )
    }

    static func -= (lhs: inout AnimatableVector, rhs: AnimatableVector) {
        let count = min(lhs.values.count, rhs.values.count)
        vDSP.subtract(
            lhs.values[0..<count],
            rhs.values[0..<count],
            result: &lhs.values[0..<count]
        )
    }

    mutating func scale(by rhs: Double) {
        vDSP.multiply(
            Float(rhs),
            values,
            result: &values
        )
    }

    var magnitudeSquared: Double {
        Double(
            vDSP.sum(
                vDSP.multiply(values, values)
            )
        )
    }

    var count: Int {
        values.count
    }

    subscript(_ i: Int) -> Float {
        get {
            values[i]
        } set {
            values[i] = newValue
        }
    }
}


struct LineGraphVector: VectorArithmetic {
    var points: [CGPoint.AnimatableData]

    static func + (lhs: LineGraphVector, rhs: LineGraphVector) -> LineGraphVector {
        print("+ \(lhs) \(rhs)")
        return .zero
//        return add(lhs: lhs, rhs: rhs, +)
    }

    static func - (lhs: LineGraphVector, rhs: LineGraphVector) -> LineGraphVector {
        print("- \(lhs) \(rhs)")
        return .zero
//        return add(lhs: lhs, rhs: rhs, -)
    }

//    static func add(lhs: LineGraphVector, rhs: LineGraphVector, _ sign: (CGFloat, CGFloat) -> CGFloat) -> LineGraphVector {
//
//        let maxPoints = max(lhs.points.count, rhs.points.count)
//        let leftIndices = lhs.points.indices
//        let rightIndices = rhs.points.indices
//
//        var newPoints: [CGPoint.AnimatableData] = []
//        (0 ..< maxPoints).forEach { index in
//            if leftIndices.contains(index) && rightIndices.contains(index) {
//                // Merge points
//                let lhsPoint = lhs.points[index]
//                let rhsPoint = rhs.points[index]
//                newPoints.append(
//                    .init(
//                        sign(lhsPoint.first, rhsPoint.first),
//                        sign(lhsPoint.second, rhsPoint.second)
//                    )
//                )
//            } else if rightIndices.contains(index), let lastLeftPoint = lhs.points.last {
//                // Right side has more points, collapse to last left point
//                let rightPoint = rhs.points[index]
//                newPoints.append(
//                    .init(
//                        sign(lastLeftPoint.first, rightPoint.first),
//                        sign(lastLeftPoint.second, rightPoint.second)
//                    )
//                )
//            } else if leftIndices.contains(index), let lastPoint = newPoints.last {
//                // Left side has more points, collapse to last known point
//                let leftPoint = lhs.points[index]
//                newPoints.append(
//                    .init(
//                        sign(lastPoint.first, leftPoint.first),
//                        sign(lastPoint.second, leftPoint.second)
//                    )
//                )
//            }
//        }
//
//        return .init(points: newPoints)
//    }

    mutating func scale(by rhs: Double) {
        debugPrint(points)
        points.indices.forEach { index in
            self.points[index].scale(by: rhs)
        }
        debugPrint(points)
    }

    var magnitudeSquared: Double {
        return 3
    }

    static var zero: LineGraphVector {
        return .init(points: [])
    }
}
