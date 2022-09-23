//
//  File.swift
//  
//
//  Created by Alexey Nenastev on 04.09.2022.
//

import Foundation
import SwiftUI

extension Optional where Wrapped == Task<Void, Error> {
    var isNilOrCanceled: Bool {
        switch self {
        case .some(let task): return task.isCancelled
        case .none: return true
        }
    }
}

@MainActor
public final class Framer<Element>: ObservableObject {

    public var frameRange: Range<Int> {
        didSet {
            guard frameRange != oldValue else { return }

            updateSliceIfNeed()

            guard !tape.isEmpty else { return }

            if Range.isMovedLeft(old: oldValue, new: frameRange) {
                startLeftLoadingIfNeed()
            }
            if Range.isMovedRight(old: oldValue, new: frameRange) {
                startRightLoadingIfNeed()
            }
        }
    }

    @Published @MainActor public private(set) var frameSlice: Slice<Tape<Element>>
    @Published @MainActor public private(set) var leftState: State = .inited
    @Published @MainActor public private(set) var rightState: State = .inited
    @Published @MainActor public private(set) var state: State = .inited

    public private(set) var tape: Tape<Element>

    private let delegate: any FramerDelegate<Element>

    private var leftLoadTask: Task<Void, Error>?
    private var rightLoadTask: Task<Void, Error>?
    private var loadTask: Task<Void, Error>?

    public enum State {
        case loading
        case error(Error)
        case inited
        case canceled
        case loaded

        var isloading: Bool {
            if case .loading = self { return true }
            return false
        }
    }

    public init(tape: Tape<Element>, delegate: any FramerDelegate<Element>, frameRange: Range<Int>? = nil) {
        self.tape = tape
        let range = frameRange ?? tape.indices
        self.frameRange = range
        self._frameSlice = Published(initialValue: tape[safe: range])
        self.delegate = delegate
    }

    @MainActor
    public func load() async {
        guard !state.isloading else { return }
        state = .loading
        frameSlice = tape[safe: frameRange]

        do {
            var frameRange = self.frameRange
            let loaded = try await delegate.load(frameRange: &frameRange)
            tape = Tape(loaded)
            self.frameRange = frameRange
            state = .loaded
        } catch {
            if error is CancellationError {
                state = .canceled
            } else {
                state = .error(error)
            }
        }
    }

    @MainActor
    private func startLeftLoadingIfNeed() {
        guard !state.isloading && !leftState.isloading else { return }

        let remainsToLeftEnd = frameRange.lowerBound - tape.startIndex

        guard delegate.shouldLoadLeft(remainsToEnd: remainsToLeftEnd, frameLength: frameRange.distance) else { return }

        Task {  await loadLeft() }
    }

    @MainActor
    private func startRightLoadingIfNeed() {
        guard !state.isloading && !rightState.isloading else { return }

        let remainsToRightEnd = tape.endIndex - frameRange.upperBound
        guard delegate.shouldLoadRight(remainsToEnd: remainsToRightEnd, frameLength: frameRange.distance) else { return }

        Task {  await loadRight() }
    }

    @MainActor
    private func loadLeft() async {
        guard let left = tape.left else { return }

        leftState = .loading
        do {
            let loaded = try await delegate.loadLeft(lastLeft: left, frameLenght: frameRange.distance)
            tape.append(atLeft: loaded)
            updateSliceIfNeed()
            leftState = .loaded
            startLeftLoadingIfNeed()
        } catch {
            if error is CancellationError {
                leftState = .canceled
            } else {
                leftState = .error(error)
            }
        }
    }

    private func doWithStateUpdate(_ task:  @escaping () async throws -> Void, stateKey: ReferenceWritableKeyPath<Framer<Element>, State>) async {

        self[keyPath: stateKey] = .loading

        do {
            try await task()
            self[keyPath: stateKey] = .loaded
        } catch {
            if error is CancellationError {
                self[keyPath: stateKey] = .canceled
            } else {
                self[keyPath: stateKey] = .error(error)
            }
        }
    }

    private func loadLeftIfNeed() async {
        guard leftLoadTask.isNilOrCanceled else { return }

        let remainsToLeftEnd = frameRange.lowerBound - tape.startIndex
        guard delegate.shouldLoadLeft(remainsToEnd: remainsToLeftEnd, frameLength: frameRange.distance) else { return }


        await doWithStateUpdate(loadLeftAndAddToTape, stateKey: \.leftState)
    }

    private func loadLeftAndAddToTape() async throws {
        guard let left = tape.left else { return }
        let loaded = try await delegate.loadLeft(lastLeft: left, frameLenght: frameRange.distance)
        guard !Task.isCancelled else { return }
        tape.append(atLeft: loaded)
    }

    private func loadRightAndAddToTape() async throws {
        guard let right = tape.right else { return }
        let loaded = try await delegate.loadRight(lastRight: right, frameLenght: frameRange.distance)
        guard !Task.isCancelled else { return }
        tape.append(atRight: loaded)
    }

    private func reloadTape() async throws {
        var frameRange = self.frameRange
        let loaded = try await delegate.load(frameRange: &frameRange)
        guard !Task.isCancelled else { return }
        tape = Tape(loaded)
        self.frameRange = frameRange
    }

    @MainActor
    private func loadRight() async {
        guard let right = tape.right else { return }

        rightState = .loading
        do {
            let loaded = try await delegate.loadRight(lastRight: right, frameLenght: frameRange.distance)
            tape.append(atRight: loaded)
            updateSliceIfNeed()
            rightState = .loaded
            startRightLoadingIfNeed()
        } catch {
            if error is CancellationError {
                rightState = .canceled
            } else {
                rightState = .error(error)
            }
        }
    }

    @MainActor
    private func updateSliceIfNeed(force: Bool = false) {
        let newSlice = tape[safe: frameRange]
        guard frameSlice.indices != newSlice.indices || force else { return }
        self.frameSlice = newSlice
    }

}

public extension Framer {
     
    convenience init(tape: Tape<Element>,  delegate: any FramerDelegate<Element>, frameRange: PartialRangeUpTo<Int>) {
        self.init(tape: tape, delegate: delegate, frameRange: frameRange.relative(to: tape))
    }
     
    convenience init(tape: Tape<Element>,  delegate: any FramerDelegate<Element>, frameRange: PartialRangeFrom<Int>) {
        self.init(tape: tape, delegate: delegate, frameRange: frameRange.relative(to: tape))
    }
    
}
