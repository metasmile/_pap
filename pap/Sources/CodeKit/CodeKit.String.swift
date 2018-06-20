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

    public func urls() -> [URL] {
        var urls : [URL] = []

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return urls
        }
        for match in detector.matches(in: self, options: [], range: NSMakeRange(0, self.count)){
            if let url = match.url {
                urls.append(url)
            }
        }
        return urls
    }

    public func emailAddresses() -> [String] {
        var emailAddresses = [String]()
        for url in self.urls() {
            if let component = URLComponents(url: url, resolvingAgainstBaseURL: false){
                if component.scheme == "mailto"{
                    emailAddresses.append(component.path)
                }
            }
        }
        return emailAddresses
    }
}
