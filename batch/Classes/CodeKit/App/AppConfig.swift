//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

public protocol ConfigurableApp {

    //TODO: how to handle views - when app lifecycle finished
    //TODO: how to input configView's parameter/config
    var configView:UIView? { get }

    //TODO: find better way to avoid notification object type restriction
    var configNotificator:NotificationCenter { get }
}

public struct ConfigurableAppNotification {
    static let didChange = Notification.Name("\(ConfigurableAppNotification.self).didChange")

    struct UserInfo {
        enum Key {
            static let configValue = "configValue"
        }
    }
}
