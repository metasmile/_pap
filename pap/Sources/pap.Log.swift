//
// Created by BLACKGENE on 06.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Firebase

struct papLog:Analyzable{

    struct charge:Analyzable {
        static func opened(){
            log()
        }

        static func cancelled(){
            log()
        }

        static func paid(type:ChargeType){
            log(parameters: ["chargeType":String(describing: type)])
        }

        static func unpaid(type:ChargeType){
            log(parameters: ["chargeType":String(describing: type)])
        }
    }

    struct event:Analyzable {
        static func appSelected(){
            log()
        }

        static func cancelWhileSelecting(){
            log()
        }

        static func cancelWhilePerforming(){
            log()
        }

        static func performFromUser(){
            log()
        }

        static func performWhenPhotoLibraryDidChanged(){
            log()
        }

        static func allTasksAreFinished(){
            log()
        }
    }

    struct error {
        static func recordedError(_ e:Error, parameters:[String:Any]?=nil){
            var paramToCommit = [
                "errorDescription": e.localizedDescription
            ] as [String:Any]

            if let parameters = parameters{
                for o in parameters{
                    paramToCommit[o.key] = o.value
                }
            }

            log(parameters: paramToCommit)
        }
    }
}

fileprivate protocol Analyzable{
    static func log(_ name:String, parameters:[String:Any]?)
}

extension Analyzable{

    fileprivate static func _log(_ identifier: String, parameters: [String : Any]?){
#if !DEBUG
        Analytics.logEvent(identifier, parameters: parameters)
#endif
    }

    fileprivate static func log(_ localName:String=#function, parameters:[String:Any]?=nil){
        let SP = "."
        let localName = localName.replaceIfMatched(withPattern: "\\(.*$", replace: "")
        let identifier = "\(String(describing: self))\(SP)\(localName)"
        
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
            _log(identifier, parameters: paramToCommit)
        }
    }
}