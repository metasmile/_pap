//
//  StringExtension.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 10. 31..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit

extension String {
    var localizedString: String {
        return NSLocalizedString(self, comment: "")
    }
}
