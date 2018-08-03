//
// Created by BLACKGENE on 8/3/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol Loggable {
    static func log(_ name:String, parameters:[String:Any]?)
}

extension Loggable{
    static func createIdentifier(with name: String=#function) -> String {
        return "\(String(reflecting: self)).\(name)"
    }

    static func createIdentifier(withFunction name: String=#function) -> String {
        return "\(String(reflecting: self)).\(name.replaceIfMatched(withPattern: "\\(.*$", replace: ""))"
    }
}