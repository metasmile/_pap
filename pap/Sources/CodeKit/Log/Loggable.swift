//
// Created by BLACKGENE on 8/3/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol Loggable {
    static func log(_ name:String, parameters:[String:Any]?)
}

extension Loggable{
    static var splitter:String{
        return "."
    }

    //custom
    static func logFilePrivate(_file:String=#file, _function:String=#function, value:Any){
        log(self.createIdentifier(withFile: _file), parameters: [_function.loggableFunctionName:value])
    }

    static func createIdentifier(with name: String=#function) -> String {
        return "\(String(reflecting: self))\(splitter)\(name)"
    }

    static func createIdentifier(withFunction name: String=#function) -> String {
        return "\(String(reflecting: self))\(splitter)\(name.loggableFunctionName)"
    }

    static func createIdentifier(withFile name: String=#file) -> String {
        return URL(string: name)?.deletingPathExtension().lastPathComponent.remove(splitter) ?? String(reflecting: self)
    }
}

extension String{
    var loggableFunctionName:String{
        return self.replaceIfMatched(withPattern: "\\(.*$", replace: "")
    }
}