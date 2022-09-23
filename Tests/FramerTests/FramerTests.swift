import XCTest
import Foundation
import Combine
@testable import Framer


final class FramerActorTests: XCTestCase {

    func assertLeftLoadingCall(delegate: TestFramerDelegate, timeout: Double? = nil) {
        wait(for: [delegate.leftLoadExpectation], timeout: timeout ?? (delegate.delayOnLoadingSec + 0.01))
    }

    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

//    func
//
//    @MainActor
//    func testChangeSliceWhenChangeRange() throws {
//        let initValue = (0..<10).array
//        let tape = Tape(initValue)
//        let delegate = TestFramerDelegate()
//        let controller = FramerActor(tape: tape, delegate: delegate)
//        XCTAssertEqual(controller.frameSlice.array, initValue)
//        XCTAssertEqual(controller.frameRange, 0..<10)
//
//        controller.frameRange = 0..<5
//        XCTAssertEqual(controller.frameSlice.array, (0..<5).array)
//
//        controller.frameRange = -10..<10
//        XCTAssertEqual(controller.frameSlice.array, initValue)
//    }
}

final class FramerTests: XCTestCase {
     
    func assertLeftLoadingCall(delegate: TestFramerDelegate, timeout: Double? = nil) {
        wait(for: [delegate.leftLoadExpectation], timeout: timeout ?? (delegate.delayOnLoadingSec + 0.01))
    }
    
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = []
    }
    
    @MainActor
    func testChangeSliceWhenChangeRange() throws {
        let initValue = (0..<10).array
        let tape = Tape(initValue)
        let delegate = TestFramerDelegate()
        let controller = Framer(tape: tape, delegate: delegate)
        XCTAssertEqual(controller.frameSlice.array, initValue)
        XCTAssertEqual(controller.frameRange, 0..<10)
        
        controller.frameRange = 0..<5
        XCTAssertEqual(controller.frameSlice.array, (0..<5).array)
        
        controller.frameRange = -10..<10
        XCTAssertEqual(controller.frameSlice.array, initValue)
    }

    @MainActor
    func testLoadingWhenShould() throws {
        let initValue = (0..<10).array
        let tape = Tape(initValue)
        
        let delegate = TestFramerDelegate()
        delegate.delayOnLoadingSec = 0.1
        delegate.hasMoreRight = false // справа нет элементов
        delegate.hasMoreLeft = true // слева еще можно загружать
        delegate.loadLeftWhenRemainToLast = 0  // загружать начнем когда фрейм захватит последний элемент слева
        let controller = Framer(tape: tape, delegate: delegate, frameRange: 5...)
 
        delegate.leftLoadExpectation = .failIfCalled // загружаться ничего не должно!
        controller.frameRange.setted(leftTo: 3) //Двигаем фрейм
        controller.frameRange.setted(leftTo: 1) //Двигаем фрейм
        XCTAssertEqual(controller.tape.array, initValue) // тейп такой же как в начале
        assertLeftLoadingCall(delegate: delegate)
         
        delegate.leftLoadExpectation = .shouldCalled()
        controller.frameRange.setted(leftTo: 0) // Должен был произойти вызов загрузки
        assertLeftLoadingCall(delegate: delegate)
        
    }
    
    @MainActor
    func testCheckStateChainging() throws {
        let initValue = (0..<10).array
        let tape = Tape(initValue)

        let delegate = TestFramerDelegate()
        delegate.delayOnLoadingSec = 0.1
        delegate.hasMoreRight = false // справа нет элементов
        delegate.hasMoreLeft = true // слева еще можно загружать
        delegate.loadLeftWhenRemainToLast = 0  // загружать начнем когда фрейм захватит последний элемент слева
        let controller = Framer(tape: tape, delegate: delegate, frameRange: 5...)
 
        let stateInited1 = expectation(description: "State inited")
        let stateLoading1 = expectation(description: "State loading")
        let stateLoaded1 = expectation(description: "State loaded")
        
        controller.$leftState.sink(receiveValue: { value in
            print("LeftState \(value)")
            switch value {
            case  .loaded: stateLoaded1.fulfill()
            case  .inited: stateInited1.fulfill()
            case  .loading: stateLoading1.fulfill()
            default: XCTFail()
            }
            
        }).store(in: &cancellables)
        controller.frameRange.setted(leftTo: 0) // загрузка
        wait(for: [stateInited1, stateLoading1, stateLoaded1], timeout: 1, enforceOrder: true)
           
        /// Загрузка с ошибкой
        cancellables = []
        delegate.throwErrorWhenLoadLeft = LoadingError()
         
        let stateLoading2 = expectation(description: "State loading")
        let stateLoaded2 = expectation(description: "State loaded")
        let stateError2 = expectation(description: "State error")
        
        controller.$leftState.sink(receiveValue: { value in
            print("LeftState \(value)")
            switch value {
            case  .error(let error) where error is LoadingError: stateError2.fulfill()
            case  .loaded: stateLoaded2.fulfill()
            case  .loading: stateLoading2.fulfill()
            default: XCTFail()
            }
            
        }).store(in: &cancellables)
        controller.frameRange.setted(leftTo: -10) // загрузка
        wait(for: [stateLoaded2, stateLoading2, stateError2], timeout: 1, enforceOrder: true)
           
    }

    @MainActor
    func testTapeAppendLeftLoadedElements() throws {
        // Для простоты 10 элемнтов где значения совпадают с индексом
        let initValue = (0..<10).array
        let tape = Tape(initValue)
        
        let delegate = TestFramerDelegate()
        delegate.delayOnLoadingSec = 0.1
        delegate.hasMoreRight = false // справа нет элементов
        delegate.hasMoreLeft = true // слева еще можно загружать
        delegate.loadLeftWhenRemainToLast = 0  // загружать начнем когда фрейм захватит последний элемент слева
        let controller = Framer(tape: tape, delegate: delegate, frameRange: 5...)
 
        delegate.leftLoadExpectation = .shouldCalled()
        let stateLoaded = expectation(description: "State loaded")
        
        controller.$leftState.sink(receiveValue: { [unowned controller] value in
            print("LeftState \(value)")
            switch value {
            case    .loaded:
                stateLoaded.fulfill()
                XCTAssertEqual(controller.tape.array, (-5..<10).array) // в тейп добавилось еще 5 элементов
            default: break
            }
            
        }).store(in: &cancellables)
        controller.frameRange.setted(leftTo: 0)
        assertLeftLoadingCall(delegate: delegate) // Должен был произойти вызов загрузки
        wait(for: [stateLoaded], timeout: 1) 
    }
    @MainActor
    func testChangeSliceWhenLoadedRangedElements() throws {
        // Для простоты 10 элемнтов где значения совпадают с индексом
        let initValue = (0..<10).array
        let tape = Tape(initValue)
        
        let delegate = TestFramerDelegate()
        delegate.delayOnLoadingSec = 0.1
        delegate.hasMoreRight = false // справа нет элементов
        delegate.hasMoreLeft = true // слева еще можно загружать
        delegate.loadLeftWhenRemainToLast = 0  // загружать начнем когда фрейм захватит последний элемент слева
        
        let initRange = 5..<10
        let controller = Framer(tape: tape, delegate: delegate, frameRange: initRange)
 
        let changedSliceOnLoading = expectation(description: "State loaded")
        
        let newRange = -5..<3
        
        controller.$frameSlice.sink(receiveValue: { [unowned controller] value in
            print(controller.leftState)
            switch controller.leftState {
            case .inited where controller.frameRange == initRange:
                XCTAssertEqual(Array(value), initRange.array) // первоначальный слайс
            case .inited where controller.frameRange == newRange:
                XCTAssertEqual(Array(value), (0..<3).array)  // В этом слайсе есть только 0, 1, 2
            case .loading:
                XCTAssertEqual(Array(value), newRange.array) // слайс изменился - появились элементы для установленного frameRange
                changedSliceOnLoading.fulfill()
            default: break
            }
        }).store(in: &cancellables)
        controller.frameRange.setted(leftTo: newRange.lowerBound, rightTo: newRange.upperBound)
        wait(for: [changedSliceOnLoading], timeout: 1)
    }
    @MainActor
    func testNoLoadingCallWhileLoading() throws {
        // Для простоты 10 элемнтов где значения совпадают с индексом
        let initValue = (0..<10).sorted()
        let tape = Tape(initValue)
        
        let delegate = TestFramerDelegate()
        delegate.delayOnLoadingSec = 1
        delegate.hasMoreRight = false // справа нет элементов
        delegate.hasMoreLeft = true // слева еще можно загружать
        delegate.loadLeftWhenRemainToLast = 0  // загружать начнем когда фрейм захватит последний элемент слева
        
        let initRange = 5..<10
        let controller = Framer(tape: tape, delegate: delegate, frameRange: initRange)
 
        delegate.leftLoadExpectation = .shouldCalled()
        controller.frameRange.setted(leftTo: 0)
        assertLeftLoadingCall(delegate: delegate) // Должен был произойти вызов загрузки
        // Загрузка уже идет (1 сек) больше загрузок быть не должно при изменении фрейма
        delegate.leftLoadExpectation = .failIfCalled
        controller.frameRange.setted(leftTo: -1)
        assertLeftLoadingCall(delegate: delegate, timeout: 0.1)
        
        delegate.leftLoadExpectation = .failIfCalled
        controller.frameRange.setted(leftTo: -3)
        assertLeftLoadingCall(delegate: delegate, timeout: 0.1)
        
        delegate.leftLoadExpectation = .failIfCalled
        controller.frameRange.setted(leftTo: -10)
        assertLeftLoadingCall(delegate: delegate, timeout: 0.1)
         
    }
    
    @MainActor
    func testAutoStartLoadingIfNeedAfterLoading() throws {
        // Для простоты 10 элемнтов где значения совпадают с индексом
        let initValue = (0..<10).array
        let tape = Tape(initValue)
        
        let delegate = TestFramerDelegate()
        delegate.delayOnLoadingSec = 0.2
        delegate.hasMoreRight = false // справа нет элементов
        delegate.hasMoreLeft = true // слева еще можно загружать
        delegate.loadLeftWhenRemainToLast = 0  // загружать начнем когда фрейм захватит последний элемент слева
        
        let initRange = 5..<10
        let controller = Framer(tape: tape, delegate: delegate, frameRange: initRange)
 
        let inTheEndActualSlice = expectation(description: "Actual slice")
         
        controller.$frameSlice.sink(receiveValue: { [unowned controller] value in
            print("Slice change to: \(Array(value))")
            print("state:\(controller.leftState)")
            print("range:\(controller.frameRange)\n")
            
            
            /// Слайс всегда возвращает все данные какие есть в рамках установленного фрейма
            XCTAssertEqual(Array(value), Array(controller.tape[safe: controller.frameRange]))
            
            /// Последнее изменение слайса - это загрузили данные для финального фрейма
            if (-10..<initRange.upperBound).array == Array(value) {
                inTheEndActualSlice.fulfill()
            }
        }).store(in: &cancellables)
        
        let finalTapeContent = expectation(description: "Final tape content")
        
        controller.$leftState.sink(receiveValue: { [unowned controller] value in
            print("State changed to: \(value)\n")
             
            /// В финале в тейпе данный от трех загрузок
            if (-15..<initRange.upperBound).array == Array(controller.tape), case .loaded = value  {
                finalTapeContent.fulfill()
            }
        }).store(in: &cancellables)
        
        // последний элемент слева 0, прыгаем на -10, но загружает только по 5
        // и загружает когда от конца фрейма до ближайшего элемента еще delegate.loadLeftWhenRemainToLast элементов
        // должно быть три загрузки
        // -5...
        // -10...
        // -15... - потому что фрейм смотрит на последний элемент
        delegate.leftLoadExpectation = .shouldCalled(count: 3)
        controller.frameRange.setted(leftTo: -10)
        assertLeftLoadingCall(delegate: delegate, timeout: delegate.delayOnLoadingSec * 3 + 0.5)
        
        
        wait(for: [inTheEndActualSlice, finalTapeContent], timeout: 4)
    }
    
}
