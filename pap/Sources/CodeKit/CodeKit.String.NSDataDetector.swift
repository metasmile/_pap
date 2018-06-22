//
// Created by BLACKGENE on 22.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension String{

    public func detectAll(types:NSTextCheckingTypes, options:NSRegularExpression.MatchingOptions=[], range:NSRange?=nil) -> [NSTextCheckingResult] {
        guard let detector = try? NSDataDetector(types: types) else {
            return [NSTextCheckingResult]()
        }
        return detector.matches(in: self, options: options, range: range ?? NSMakeRange(0, self.count))
    }

    public func urls() -> [URL] {
        return self.detectAll(types: NSTextCheckingResult.CheckingType.link.rawValue).compactMap { result -> URL? in
            return result.url
        }
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