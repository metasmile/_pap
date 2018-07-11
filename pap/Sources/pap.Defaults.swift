//
// Created by BLACKGENE on 15/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

extension Defaults: DefaultsProperty {
    public var appIdentifier: String? {
        set{ set(newValue) } get{ return get() }
    }

    public var appDockContentLayoutState: Int {
        set{ set(newValue) } get{ return get(or:AppDockContentLayoutState.neutralized.rawValue) }
    }

    // private
    fileprivate var appCount:[String:Double]{ // [identifier: performed count]
        set{ set(newValue) } get{ return get(or:[String:Double]()) }
    }
}

public struct papCount {
    struct app {
        static var numberOfCounted:Int{
            return Defaults.shared.appCount.keys.count
        }

        static func countToPerform(app:App.Type){
            if app.info.phase != .release{
                return
            }

            let id = app.info.identifier
            var counting = Defaults.shared.appCount
            if let count = counting[id]{
                counting[id] = count+1
            }else{
                counting[id] = 1
            }
            Defaults.shared.appCount = counting
        }

        static func countToPerform(){
            if let app = AppCenter.default.current{
                countToPerform(app:app)
            }
        }

        static func countPerformed(app:App.Type) -> Double{
            return Defaults.shared.appCount[app.info.identifier] ?? 0
        }
    }
}
