//
// Created by BLACKGENE on 15/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit


extension Defaults{
    public var appBundleIdentifier: String? { set(newValue){ set(newValue ?? "", for: Key<String>(#function)) } get{ return get(for: Key<String>(#function)) } }
}


