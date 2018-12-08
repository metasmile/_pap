//
// Created by BLACKGENE on 2018-12-06.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension UIScrollView {
    func scrollsToBottom(animated: Bool) {
        if self.contentSize.height < self.bounds.size.height { return }
        let bottomOffset = CGPoint(x: 0, y: self.contentSize.height - self.bounds.size.height)
        self.setContentOffset(bottomOffset, animated: animated)
    }
}
