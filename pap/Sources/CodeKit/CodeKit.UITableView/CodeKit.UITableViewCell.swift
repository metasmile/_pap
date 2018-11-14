//
// Created by BLACKGENE on 15.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension UITableViewCell {
    func enable(_ on: Bool) {
        self.isUserInteractionEnabled = on

        (self.accessoryView as? UIControl)?.isEnabled = on

        for view in contentView.subviews {
            view.isUserInteractionEnabled = on
            view.alpha = on ? 1 : 0.4
        }
    }
}