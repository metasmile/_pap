//
// Created by BLACKGENE on 14.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public struct AppLaunchOptionsKey: Hashable, Equatable, RawRepresentable {
    public typealias RawValue = Int
    public private(set) var rawValue: RawValue
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

public struct AppLaunchOptions {
    var options:[AppLaunchOptionsKey:Any]?
    init(options:[AppLaunchOptionsKey:Any]?=nil){
        self.options = options
    }
    var identifierToReturn:String?
}

protocol LaunchableApp :App {
    // didResign called after an other app assigned to AppManager.current, OR discard Self instance if needed when App.info.policy.lifeCycle.instance == .availability
    // use this for a situation for example it should remove temp resources in current running cycle.
    func didResign(current:App.Type?)

    func didLaunch(previous:App.Type?, withOption: AppLaunchOptions?)
}
