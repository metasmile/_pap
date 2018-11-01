//
// Created by BLACKGENE on 28/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

public protocol AppConfigValuable {}

public protocol AppConfigAdoptableValuable: AppConfigValuable {
    func adoptValues(fromOther:AppConfigValuable)
}

public protocol AppConfigUIAttributeValuable: AppConfigValuable {
    var tintColor:UIColor? { set get }
}

public struct AppConfigUIAttribute: AppConfigUIAttributeValuable {
    public var tintColor: UIColor?
}

public protocol _ConfigurableApp{
    associatedtype T: AppConfigValuable

    var config: T? { get }
}

public protocol ConfigurableApp: App {
    static var defaultConfigValue: AppConfigValuable { get }

    func setConfigValues<T: AppConfigValuable>(_ config:T)
}

extension ConfigurableApp where Self:_ConfigurableApp, Self.T: AppConfigAdoptableValuable {
    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
    }
}
