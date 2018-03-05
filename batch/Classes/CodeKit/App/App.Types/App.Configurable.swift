//
// Created by BLACKGENE on 28/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

public protocol ConfigurableAppValuable: NSObjectProtocol {}

public protocol AppConfigViewAttrributes:ConfigurableAppValuable{
    var tintColor:UIColor? { get }
}

protocol _ConfigurableApp{
    associatedtype T:ConfigurableAppValuable
    var config: T? { set get }

    init(config: T?)
}

public protocol ConfigurableApp: App, NSObjectProtocol {
    //TODO: how to handle views - when app lifecycle finished
    //TODO: how to input configView's parameter/config
    var configView:UIView? { get }
}
