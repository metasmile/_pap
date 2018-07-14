//
// Created by BLACKGENE on 14.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public struct AppInterplayOptionsKey: Hashable, Equatable, RawRepresentable {
    public typealias RawValue = String
    public private(set) var rawValue: RawValue
    public init?(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

public struct AppInterplayOption {
    var data:[AppInterplayOptionsKey:Any]
    var returningAppIdentifier:String?
}

protocol InterplayableApp where Self:App {
    //INFO: Optional - other apps can read this option if app is providing.
    static var interplayOption: AppInterplayOption? {get}

    func willSelect(current:App.Type?, withOption:AppInterplayOption?)
    func didSelect(previous:App.Type?, withOption:AppInterplayOption?)
}
