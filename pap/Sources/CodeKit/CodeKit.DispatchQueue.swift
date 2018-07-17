//
// Created by BLACKGENE on 13/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension DispatchQueue {
    public class var currentLabel: String {
        return String(validatingUTF8: __dispatch_queue_get_label(nil)) ?? "anonymous"
    }

    //INFO: compare with Label. Not DispatchQueue instance. DispatchQueue.current != DispatchQueue.main (always)
    public class var current:DispatchQueue {
        return DispatchQueue(label: self.currentLabel)
    }

    public class func mainAsyncIfNot(execute:@escaping () -> Void){
        if currentLabel==DispatchQueue.main.label{
            execute()
        }else{
            DispatchQueue.main.async(execute: execute)
        }
    }

    public class func mainAsyncAfter(qos: DispatchQoS.QoSClass = .default, execute:@escaping () -> Void){
        DispatchQueue.global(qos: qos).async{
            DispatchQueue.main.async(execute:execute)
        }
    }
}


public protocol Signalable {
    //INFO: A stack containing labels of each DispatchQueue, thread safe.
    // e.g. Creating DispatchQueue:  DispatchQueue(label: {queueStack label})
    // e.g. A foreground queue when AsyncSignal firstly began: queueStack[0]
    var queueStack:[String] {get}
}

public protocol AsyncSignalable: Signalable {
    var began:Bool { get }
    func begin()

    @discardableResult
    func end() -> Self
}

public protocol AsyncWaitSignalable: AsyncSignalable {
    func waitUntilEnd()
}

public protocol AsyncFinalSignalable {
    func done()

    @discardableResult
    func finally(_ queue:DispatchQueue?,_ completion: DispatchWorkItem) -> Self
}

//INFO: Avoid store AsyncSignal instance as soon as possible
public final class AsyncSignal{
    private let dispatchGroup:DispatchGroup = DispatchGroup()
    private let _offsetSyncQueue:DispatchQueue = DispatchQueue(label:"com.stells.internal__sync_queue_\(UUID().uuidString)")
    private(set) public var queueStack = [String]()
    private var offset:Int = 0
}

extension AsyncSignal: AsyncWaitSignalable {

    public var began:Bool {
        return offset>0
    }

    private func setOffset(_ increment:Bool, _current:String=DispatchQueue.currentLabel) -> Bool{
        return _offsetSyncQueue.sync {
            assert(offset>=0,"All state of offset must be >= 0")
            let decre = !increment && offset>0
            let incre = increment && offset>=0
            let executed = incre || decre
            if executed{
                offset += increment ? 1 : -1

                _offsetSyncQueue.async(flags: .barrier){
                    if increment{
                        self.queueStack.append(_current)
                    }else{
                        let _ = self.queueStack.popLast()
                    }
                }
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
    public func waitUntilEnd(timeout:DispatchTime?=nil) -> DispatchTimeoutResult?{
        guard self.began else {
            assert(false,"[!] self.began==false, \(#function) was synchronously called before calling begin(), or end() was called in same queue. Call begin() before, remove unnecessary end() at same block, or call end() in async block of other queue.")
            return nil
        }

        #if DEBUG
        if Thread.isMainThread{
            print("[!] WARNING: \(#function) called in the main queue - at \(String(describing: type(of: self)))")
        }
        #endif

        if let timeout = timeout {
            return dispatchGroup.wait(timeout: timeout)

        } else {
            dispatchGroup.wait()
            return nil
        }
    }

    public func waitUntilEnd() {
        self.waitUntilEnd(timeout:nil)
    }
}

extension AsyncSignal: AsyncFinalSignalable{
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

