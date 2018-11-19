//
// Created by BLACKGENE on 10.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension UIAlertAction {

    var accessoryImage: UIImage? {
        get {
            if self.responds(to: Selector(Constants.imageKey)) {
                return self.value(forKey: Constants.imageKey) as? UIImage
            }
            return nil
        }
        set {
            if self.responds(to: Selector(Constants.imageKey)) {
                self.setValue(newValue, forKey: Constants.imageKey)
            }
        }
    }

    private struct Constants {
        static var imageKey = "image"
    }
}

