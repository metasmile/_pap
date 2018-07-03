//
//  CodeKit.String.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 10. 31..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit

extension String: Error {}

extension String {
    public var asBundlePath: String{
        return Bundle.main.bundleURL.appendingPathComponent(self).path
    }

    public var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    public func localizedFormatted(_ arguments: CVarArg...) -> String {
        return withVaList(arguments) {
            return NSString(format: self.localized, arguments: $0) as String
        }
    }

    public func replace(_ with:String, _ replacement:String) -> String{
        return self.replacingOccurrences(of: with, with: replacement)
    }

    public func remove(_ with:String) -> String{
        return replace(with, "")
    }

    public func trim() -> String{
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func encodeAsURLQuery() -> String{
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
}
