//
//  File.swift
//  
//
//  Created by Alexey Nenastev on 13.09.2022.
//

import Foundation
import SwiftUI


public actor FramerActor<Element>: ObservableObject {

    public private(set) var frameRange: Range<Int> {
         didSet {
            guard !isEmpty else { return }

            if Range.isMovedLeft(old: oldValue, new: frameRange) {
                loadLeftIfNeed()
            }
            if Range.isMovedRight(old: oldValue, new: frameRange) {
                loadRightIfNeed()
            }
        }
    }

    @Published @MainActor public private(set) var frameSlice: Slice<Tape<Element>>
    @Published @MainActor public private(set) var leftState: State = .inited
    @Published @MainActor public private(set) var rightState: State = .inited
    @Published @MainActor public private(set) var state: State = .inited

    public private(set) var tape: Tape<Element>

    public var isEmpty: Bool { tape.isEmpty }

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

    @MainActor @discardableResult
    private func doWithStateUpdate(_ task: Task<Void, Error>, stateKey: ReferenceWritableKeyPath<FramerActor<Element>, State>) async -> Bool {
        self[keyPath: stateKey] = .loading
        do {
            try await task.value
            self[keyPath: stateKey] = .loaded
            return true
        } catch {
            if error is CancellationError {
                self[keyPath: stateKey] = .canceled
            } else {
                self[keyPath: stateKey] = .error(error)
            }
            return false
        }
    }

    @MainActor
    private func updateSliceIfNeed(force: Bool = false) async {
        let newSlice = await tape[safe: frameRange]

        guard frameSlice.indices != newSlice.indices || force else { return }
        self.frameSlice = newSlice
    }

    @MainActor
    public func setFrameRange(_ range: Range<Int>) async {
        let current = await frameRange
        guard current != range else { return }
        await set(frameRange: range)
        await updateSliceIfNeed()
    }

    public func load() async {
        leftLoadTask?.cancel()
        rightLoadTask?.cancel()
        loadTask?.cancel()

        let loadTask = Task { try await reloadTape() }
        self.loadTask = loadTask
        let _ = await doWithStateUpdate(loadTask, stateKey: \.state)
        self.loadTask = nil
    }

    private func set(frameRange: Range<Int>) async {
        self.frameRange = frameRange
    }

    private func loadRightIfNeed()  {
        guard rightLoadTask.isNilOrCanceled else { return }

        let remainsToRightEnd = tape.endIndex - frameRange.upperBound
        guard delegate.shouldLoadRight(remainsToEnd: remainsToRightEnd, frameLength: frameRange.distance) else { return }

        let rightLoadTask = Task { try await loadRightAndAddToTape() }
        self.rightLoadTask = rightLoadTask
        Task {
            let isSuccess = await doWithStateUpdate(rightLoadTask, stateKey: \.rightState)
            self.rightLoadTask = nil
            if isSuccess {
                loadRightIfNeed()
            }
        }
    }

    private func loadLeftIfNeed() {
        guard leftLoadTask.isNilOrCanceled else { return }

        let remainsToLeftEnd = frameRange.lowerBound - tape.startIndex
        guard delegate.shouldLoadLeft(remainsToEnd: remainsToLeftEnd, frameLength: frameRange.distance) else { return }

        let leftLoadTask = Task { try await loadLeftAndAddToTape() }
        self.leftLoadTask = leftLoadTask
        Task {
            let isSuccess = await doWithStateUpdate(leftLoadTask, stateKey: \.leftState)
            self.leftLoadTask = nil
            if isSuccess {
                loadLeftIfNeed()
            }
        }
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
}

