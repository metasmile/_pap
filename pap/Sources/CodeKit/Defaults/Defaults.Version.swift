//
// Created by BLACKGENE on 23.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol VersionDefaults:PropertyDefaults{
    func initVersionInfo()

    //INFO: if shortVersionDistance == nil, user using first version or newly installed again.
    //INFO: if shortVersionDistance == 0, user is using latest version
    //INFO: if shortVersionDistance > 0, user installed new version in current runtime
    //INFO: if shortVersionDistance > 1, user skipped recent version in current runtime
    //INFO: if shortVersionDistance < 0, sucks, user is using some illegal version in current runtime
    var shortVersionDistance:Int? {get}

    var latestVersion:String? {get}
    var latestShortVersion:String? {get}
    var shortVersionDescription: VersionDescription {get}
    var shortVersionDescriptionLatestDates:[VersionDescription:Date] {get}
    var shortVersionDescriptionLatestTouchedDates:[VersionDescription:Date] {get}
}

extension Defaults: VersionDefaults {

    func initVersionInfo(){
        let preDescription = self.shortVersionDescription

        self.latestShortVersion = Bundle.main.shortVersionString
        self.latestVersion = Bundle.main.version

        let currentDescription = self.shortVersionDescription

        self.shortVersionDescriptionLatestTouchedDates[currentDescription] = Date()
        if currentDescription == .first || preDescription != currentDescription {
            self.shortVersionDescriptionLatestDates[currentDescription] = Date()
        }
    }

    //INFO: It is recommended to use for only init-time procedure. shortVersionDescription will be maintained in current runtime.
    var shortVersionDescription: VersionDescription {
        if let distance = shortVersionDistance{
            if distance==0{
                return .normal
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

    var shortVersionDescriptionLatestDates:[VersionDescription:Date]{
        set{ set(newValue) }
        get{ return get(or:[VersionDescription:Date]()) }
    }

    var shortVersionDescriptionLatestTouchedDates:[VersionDescription:Date]{
        set{ set(newValue) }
        get{ return get(or:[VersionDescription:Date]()) }
    }

    private(set) var shortVersionDistance:Int?{
        set{ set(newValue) }
        get{ return get() }
    }

    private(set) var latestShortVersion:String?{
        set{
            if let latest = latestShortVersion, let new = newValue{
                self.shortVersionDistance = SemanticVersion.distance(old: latest, new: new)
            }
            set(newValue)
        }
        get{ return get() }
    }

    private(set) var latestVersion:String?{
        set{ set(newValue) }
        get{ return get() }
    }
}