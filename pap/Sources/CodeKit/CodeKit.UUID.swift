//
// Created by BLACKGENE on 15/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension UUID{
    public func uuidFilePrivateConstString(_ _file:String=#file, _ _function:String=#function, _ _line:Int=#line) -> String{
        let className = _file.asURL?.deletingPathExtension().lastPathComponent ?? "CodeKitString"
        return "\(className)-\(_function)-\(String(_line))"
    }
}