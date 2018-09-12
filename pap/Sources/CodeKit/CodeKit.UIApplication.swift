//
// Created by BLACKGENE on 9/7/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication{
    func openSettings(completionHandler completion: ((Bool) -> Void)? = nil){
        UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: completion)
    }
}