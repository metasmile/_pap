//
// Created by BLACKGENE on 9/7/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

private struct _UIApplication {
    static var keyWindowInScenes: UIWindow?
}

extension UIApplication{
    func openSettings(completionHandler completion: ((Bool) -> Void)? = nil){
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: completion)
    }

    var keyWindowInScenes: UIWindow? {
        let keyWindow = _UIApplication.keyWindowInScenes
        if keyWindow == nil {
            _UIApplication.keyWindowInScenes = UIApplication.shared.windows.first { $0.isKeyWindow }
        }
        return _UIApplication.keyWindowInScenes
    }
}
