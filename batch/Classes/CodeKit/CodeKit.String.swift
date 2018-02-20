//
//  CodeKit.String.swift
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
    
    func localizedFormattedString(_ arguments: CVarArg...) -> String {
        return withVaList(arguments) {
            return NSString(format: self.localizedString, arguments: $0) as String
        }
    }
}
