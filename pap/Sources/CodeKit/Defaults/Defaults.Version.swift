//
// Created by BLACKGENE on 23.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

protocol VersionDefaults:DefaultsProperty{
    var shortVersionDistance:Int? {get}
    var latestShortVersion:String? {set get}
    var latestVersion:String? {set get}
}

extension Defaults: VersionDefaults {

    //INFO: if shortVersionDistance == nil, user using first version or newly installed again.
    //INFO: if shortVersionDistance == 0, user is using latest version
    //INFO: if shortVersionDistance > 0, user installed new version in current runtime
    //INFO: if shortVersionDistance > 1, user skipped recent version in current runtime
    //INFO: if shortVersionDistance < 0, sucks, user is using some illegal version in current runtime
    public enum ShortVersionDescription:Int{
        case first
        case normal
        case new
        case skippedNew
        case reversed
        case unhandled
    }

    public var shortVersionDescription: ShortVersionDescription{
        if let distance = shortVersionDistance{
            if distance==0{
                return .normal
            }
            else if distance>1{
                return .skippedNew
            }
            else if distance>0{
                return .new
            }
            else if distance<0{
                return .reversed
            }
            assert(false,"this distance \(distance) can be unhandled")
            return .unhandled
        }
        return .first
    }

    private(set) public var shortVersionDistance:Int?{
        set{ set(newValue) }
        get{ return get() }
    }

    public var latestShortVersion:String?{
        set{
            if let latest = latestShortVersion, let new = newValue{
                self.shortVersionDistance = SemanticVersion.distance(old: latest, new: new)
            }
            set(newValue)
        }
        get{ return get() }
    }

    public var latestVersion:String?{
        set{ set(newValue) }
        get{ return get() }
    }
}