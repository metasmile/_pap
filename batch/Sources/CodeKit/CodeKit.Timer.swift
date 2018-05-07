//
// Created by BLACKGENE on 26/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


private struct Timers {
    fileprivate static var timers = [String:Timer]()
}

extension Timer{

    @available(iOS 10.0, *)
    @discardableResult
    open class func scheduledTimer(identifier:String, withTimeInterval interval: TimeInterval, repeats: Bool=false, block: @escaping (Timer) -> Swift.Void) -> Timer{
        let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats, block: block)

        getScheduledTimer(identifier:identifier)?.invalidate()

        Timers.timers[identifier] = t
        return t
    }

    @available(iOS 10.0, *)
    @discardableResult
    open class func getScheduledTimer(identifier:String) -> Timer?{
        return Timers.timers[identifier]
    }
}