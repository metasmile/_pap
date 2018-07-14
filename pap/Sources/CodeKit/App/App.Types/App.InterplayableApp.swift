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
    var data:[AppInterplayOptionsKey:Any]?
}

protocol InterplayableApp where Self:App {
    //INFO: Optional - other apps can read this option if app is providing.
    var interactionOption: AppInterplayOption? {get}

    func willSelect(current:App.Type?)
    func didSelect(previous:App.Type?)
}

extension InterplayableApp{
    var interactionOption: AppInterplayOption? {
        return nil
    }
}


