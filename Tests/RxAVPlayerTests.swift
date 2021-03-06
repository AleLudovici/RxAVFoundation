//
//  RxAVPlayerTests.swift
//  RxAVPlayerTests
//
//  Created by Patrick Mick on 3/30/16.
//  Copyright © 2016 YayNext. All rights reserved.
//

import XCTest
@testable import RxAVFoundation
import AVFoundation
import RxSwift
import RxCocoa

class RxAVPlayerRateTests: XCTestCase {
    let player = AVPlayer()
    var capturedRate: Float?

    func testObserving_ShouldReturnTheDefaultRateOfZero() {
        player.rx.rate
            .subscribe(onNext: { self.capturedRate = $0 })
            .dispose()
        
        XCTAssertEqual(capturedRate, 0)
    }
    
    func testObservingAPlayerWithARateOfOne_ShouldReturnOne() {
        let sut = player.rx.rate.subscribe(onNext: { self.capturedRate = $0 })
        player.rate = 1
        sut.dispose()
        
        XCTAssertEqual(capturedRate, 1)
    }
}

class RxAVPlayerStatusTests: XCTestCase {
    func testObservingStatus_ShouldReturnTheDefaultUnknown() {
        let player = AVPlayer()
        var capturedStatus: AVPlayerStatus?
        player.rx.status
            .subscribe(onNext: { capturedStatus = $0 })
            .dispose()
        
        XCTAssertEqual(capturedStatus, .unknown)
    }
    
    func testObservingStatus_WhenItChangesToReadyToPlay_ShouldUpdateTheObserver() {
        // Makes it so that we can update the readonly property
        class MockPlayer: AVPlayer {
            var changeableStatus: AVPlayerStatus = .unknown {
                willSet { self.willChangeValue(forKey: "status") }
                didSet { self.didChangeValue(forKey: "status") }
            }
            fileprivate override var status: AVPlayerStatus { return changeableStatus }
        }
        
        let player = MockPlayer()
        var capturedStatus: AVPlayerStatus?
        let sut = player.rx.status.subscribe(onNext: { capturedStatus = $0 })
        player.changeableStatus = .readyToPlay
        sut.dispose()
        
        XCTAssertEqual(capturedStatus, .readyToPlay)
    }
}

class RxAVPlayerErrorTests: XCTestCase {
    func testObservingStatus_ShouldReturnTheDefaultUnknown() {
        let player = AVPlayer()
        var capturedError: NSError?
        player.rx.error
            .subscribe(onNext: { capturedError = $0 })
            .dispose()
        
        XCTAssertNil(capturedError)
    }
    
    func testObservingStatus_WhenItChangesToReadyToPlay_ShouldUpdateTheObserver() {
        // Makes it so that we can update the readonly property
        class MockPlayer: AVPlayer {
            var changeableError: NSError? = nil {
                willSet { self.willChangeValue(forKey: "error") }
                didSet { self.didChangeValue(forKey: "error") }
            }
            fileprivate override var error: Error? { return changeableError }
        }
        
        let player = MockPlayer()
        var capturedError: NSError?
        let sut = player.rx.error.subscribe(onNext: { capturedError = $0 })
        player.changeableError = NSError.test
        sut.dispose()
        
        XCTAssertEqual(capturedError, NSError.test)
    }
}

class RxAVPlayerPeriodicTimeObserverTests: XCTestCase {
    func testPediodicTimeObserver_AddsAnObserverToTheAVPlayer() {
        class MockPlayer: AVPlayer {
            var interval: CMTime!
            
            fileprivate override func addPeriodicTimeObserver(forInterval interval: CMTime, queue: DispatchQueue?, using block: @escaping (CMTime) -> Void) -> Any {
                self.interval = interval
                return ""
            }
            
            fileprivate override func removeTimeObserver(_ observer: Any) { }
        }
        
        let player = MockPlayer()
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(1))
        player.rx.periodicTimeObserver(interval: interval)
            .subscribe(onNext: { time in })
            .dispose()
        
        XCTAssertEqual(player.interval, interval)
    }
    
    func testPeriodicTimeObserver_NotifiesObserversWhenItsBlockIsCalled() {
        class MockPlayer: AVPlayer {
            fileprivate override func addPeriodicTimeObserver(forInterval interval: CMTime, queue: DispatchQueue?, using block: @escaping (CMTime) -> Void) -> Any {
                block(CMTime(seconds: 2, preferredTimescale: CMTimeScale(1)))
                return ""
            }
            
            fileprivate override func removeTimeObserver(_ observer: Any) { }
        }
        
        let player = MockPlayer()
        var capturedTime: CMTime!
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(1))
        player.rx.periodicTimeObserver(interval: interval)
            .subscribe(onNext: { time in capturedTime = time })
            .dispose()
        
        let time = CMTime(seconds: 2, preferredTimescale: CMTimeScale(1))
        
        XCTAssertEqual(capturedTime, time)
    }
    
    func testPeriodicTimeObserver_ShouldRemoveTheTimeObserverWhenDisposed() {
        class MockPlayer: AVPlayer {
            var capturedRemove: String!
            
            fileprivate override func addPeriodicTimeObserver(forInterval interval: CMTime, queue: DispatchQueue?, using block: @escaping (CMTime) -> Void) -> Any {
                return "test"
            }
            
            fileprivate override func removeTimeObserver(_ observer: Any) {
                capturedRemove = observer as! String
            }
        }
        
        let player = MockPlayer()
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(1))
        player.rx.periodicTimeObserver(interval: interval)
            .subscribe(onNext: { time in })
            .dispose()
        
        XCTAssertEqual("test", player.capturedRemove)
    }
}

class RxAVPlayerPeriodicBoundaryObserverTests: XCTestCase {
    func testBoundaryTimeObserver_AddsAnObserverToTheAVPlayer() {
        class MockPlayer: AVPlayer {
            var times: [CMTime]!
            
            fileprivate override func addBoundaryTimeObserver(forTimes times: [NSValue], queue: DispatchQueue?, using block: @escaping () -> Void) -> Any {
                self.times = times.map { $0.timeValue }
                return ""
            }
            
            fileprivate override func removeTimeObserver(_ observer: Any) { }
        }
        
        let player = MockPlayer()
        let time = CMTime(seconds: 1, preferredTimescale: CMTimeScale(1))
        player.rx.boundaryTimeObserver(times: [time])
            .subscribe(onNext: { })
            .dispose()
        
        XCTAssertEqual(player.times.first, time)
    }
    
    func testBoundaryTimeObserver_NotifiesObserversWhenItsBlockIsCalled() {
        class MockPlayer: AVPlayer {
            fileprivate override func addBoundaryTimeObserver(forTimes times: [NSValue], queue: DispatchQueue?, using block: @escaping () -> Void) -> Any {
                block()
                return ""
            }
            
            fileprivate override func removeTimeObserver(_ observer: Any) { }
        }
        
        let player = MockPlayer()
        let time = CMTime(seconds: 1, preferredTimescale: CMTimeScale(1))
        var closureCalled = false
        player.rx.boundaryTimeObserver(times: [time])
            .subscribe(onNext: { closureCalled = true })
            .dispose()
        
        XCTAssertTrue(closureCalled)
    }
    
    func testBoundaryTimeObserver_ShouldRemoveTheTimeObserverWhenDisposed() {
        class MockPlayer: AVPlayer {
            var capturedRemove: String!
            
            fileprivate override func addBoundaryTimeObserver(forTimes times: [NSValue], queue: DispatchQueue?, using block: @escaping () -> Void) -> Any {
                return "test"
            }
            
            fileprivate override func removeTimeObserver(_ observer: Any) {
                capturedRemove = observer as! String
            }
        }
        
        let player = MockPlayer()
        let time = CMTime(seconds: 1, preferredTimescale: CMTimeScale(1))
        player.rx.boundaryTimeObserver(times: [time])
            .subscribe(onNext: { })
            .dispose()
        
        XCTAssertEqual("test", player.capturedRemove)
    }
}
