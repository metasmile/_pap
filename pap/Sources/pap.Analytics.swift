//
// Created by BLACKGENE on 06.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Firebase

public struct papLog{
    public struct event {
        public static func appSelected(){
            Analytics.logWithCurrentApp()
        }

        public static func cancelWhileSelecting(){
            Analytics.logWithCurrentApp()
        }

        public static func cancelWhilePerforming(){
            Analytics.logWithCurrentApp()
        }

        public static func performFromUser(){
            Analytics.logWithCurrentApp()
        }

        public static func performWhenPhotoLibraryDidChanged(){
            Analytics.logWithCurrentApp()
        }

        public static func allTasksAreFinished(){
            Analytics.logWithCurrentApp()
        }
    }

    public struct error {
        public static func recordedError(_ e:Error, parameters:[String:Any]?=nil){
            var paramToCommit = [
                "errorDescription": e.localizedDescription
            ] as [String:Any]

            if let parameters = parameters{
                for o in parameters{
                    paramToCommit[o.key] = o.value
                }
            }

            Analytics.logWithCurrentApp(parameters: paramToCommit)
        }
    }
}

fileprivate extension Analytics{
    fileprivate class func _logEvent(_ name: String, parameters: [String : Any]?){
#if !DEBUG
        self.logEvent(name, parameters: parameters)
#endif
    }

    fileprivate static func logWithCurrentApp(_ name:String=#function, parameters:[String:Any]?=nil){
        let name = name.replace(")","_").replace("(","_")

        DispatchQueue.global(qos: .background).async {
            guard let app = AppCenter.default.current else{
                return
            }

            var paramToCommit = [
                "appidentifier": app.info.identifier
            ] as [String:Any]

            if let parameters = parameters{
                for o in parameters{
                    paramToCommit[o.key] = o.value
                }
            }
            self._logEvent(name, parameters: paramToCommit)
        }
    }
}
