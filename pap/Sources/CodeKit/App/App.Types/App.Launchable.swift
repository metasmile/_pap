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

public struct AppLaunchOption {
    var options:[AppLaunchOptionsKey:Any?]?
    init(options:[AppLaunchOptionsKey:Any?]?=nil){
        self.options = options
    }
    var identifierToReturn:String?
}

protocol LaunchableApp where Self:App {
    //INFO: Optional - other apps can read this option if app is providing.
    static var launchOption: AppLaunchOption? {get}

    func willLaunch(current:App.Type?, withOption: AppLaunchOption?)
    func didLaunch(previous:App.Type?, withOption: AppLaunchOption?)
}
