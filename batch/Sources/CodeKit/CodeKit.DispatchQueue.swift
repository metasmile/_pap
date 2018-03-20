//
// Created by BLACKGENE on 13/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol Signalable {}

public protocol AsyncSignalable: Signalable {
    var began:Bool { get }
    func begin()

    @discardableResult
    func end() -> Self
}

public protocol AsyncManualSignalable: AsyncSignalable {
    func stopUntilEnd()
}

public protocol AsyncControllableSignable {
    func done()

    @discardableResult
    func finally(_ queue:DispatchQueue?,_ completion: DispatchWorkItem) -> Self
}

public final class AsyncSignal {
    internal let dispatchGroup:DispatchGroup = DispatchGroup()
    private let _offsetSyncQueue:DispatchQueue = DispatchQueue(label:"com.stells.internal__sync_queue_\(UUID().uuidString)")
    private var offset:Int = 0
}

extension AsyncSignal: AsyncManualSignalable, AsyncControllableSignable {

    public var began:Bool {
        return offset>0
    }

    private func setOffset(_ increment:Bool) -> Bool{
        return _offsetSyncQueue.sync(flags: .barrier) {
            assert(offset>=0,"All state of offset must be >= 0")
            let decre = !increment && offset>0
            let incre = increment && offset>=0
            let executed = incre || decre
            if executed{
                offset += increment ? 1 : -1
            }
            return executed
        }
    }

    public func begin(){
        if setOffset(true) {
            dispatchGroup.enter()
        }
    }

    @discardableResult
    public func end() -> Self{
        if setOffset(false) {
            dispatchGroup.leave()
        }
        return self
    }

    @discardableResult
    public func stopUntilEnd(timeout:DispatchTime?=nil, function:String=#function) -> DispatchTimeoutResult?{
        guard self.began else {
            print("[!] self.began==false, \(function) was called before begin(), or, after end() in same queue.")
            return nil
        }

        guard let timeout = timeout else {
            dispatchGroup.wait()
            return nil
        }

        return dispatchGroup.wait(timeout: timeout)
    }

    public func stopUntilEnd() {
        self.stopUntilEnd(timeout:nil)
    }

    public func done() {
        while end().began { }
    }

    @discardableResult
    public func finally(_ queue:DispatchQueue?,_ completion: DispatchWorkItem) -> Self{
        let targetQueue = queue ?? DispatchQueue.main
        if self.began {
            dispatchGroup.notify(queue: targetQueue, work: completion)
        }else{
            targetQueue.async(execute: completion)
        }
        return self
    }
}

