//
//  CodeKit.String.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 10. 31..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit

extension String {
    var asBundlePath: String{
        return Bundle.main.bundleURL.appendingPathComponent(self).path
    }

    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localizedFormatted(_ arguments: CVarArg...) -> String {
        return withVaList(arguments) {
            return NSString(format: self.localized, arguments: $0) as String
        }
    }
}
