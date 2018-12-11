//
// Created by BLACKGENE on 05/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

//https://github.com/beltex/SystemKit/blob/master/SystemKit/System.swift
//https://forums.developer.apple.com/thread/64665#184837

import Foundation

public extension ProcessInfo{

    private func mach_task_self() -> task_t {
        return mach_task_self_
    }

    @available(iOS 2.0, *)
    public var physicalUsingMemory:UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info) / MemoryLayout<integer_t>.size)
        let kerr = withUnsafeMutablePointer(to: &info) { infoPtr in
            return infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { (machPtr: UnsafeMutablePointer<integer_t>) in
                return task_info(
                        mach_task_self(),
                        task_flavor_t(MACH_TASK_BASIC_INFO),
                        machPtr,
                        &count
                )
            }
        }

        guard kerr == KERN_SUCCESS else {
            return 0
        }
        return info.resident_size
    }

    @available(iOS 2.0, *)
    public var physicalRemainingMemory: UInt64 {
        return physicalMemory - physicalUsingMemory
    }
}

public func measure(_ title: String="measured at \(#function) - \(codefile()).swift#\(#line)", _ block: () -> ()) {
    #if DEBUG
    measure(title) { completion in
        block()
        completion()
    }
#else
    block()
#endif
}

public func measure(_ title: String, _ block: (() -> ()) -> ()) {
#if DEBUG
    let startTime = mach_absolute_time()
    block {
        let endTime = mach_absolute_time()
        let timeElapsed = (machToSeconds * Double(endTime - startTime))
        print("\(title) :: \(timeElapsed)s")
    }
#else
    block {}
#endif
}

public func codefile(_ _file:String=#file) -> String{
    return URL(fileURLWithPath: _file).deletingPathExtension().lastPathComponent
}

private var machToSeconds: Double {
    var timebase: mach_timebase_info_data_t = mach_timebase_info_data_t()
    mach_timebase_info(&timebase)
    return Double(timebase.numer) / Double(timebase.denom) * 1e-9
}