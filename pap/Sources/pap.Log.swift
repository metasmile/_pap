//
// Created by BLACKGENE on 06.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Firebase
import PropertyKit

//INFO: It is recommended that inserted into only UI actions.

struct papLog: Loggable {
    private static var kOption:String{ return #function }
    private static var kValue:String{ return #function }

    //common
    static func appSelected(){ log() }
    static func cancelWhileSelecting(){ log() }
    static func cancelWhilePerforming(){ log() }
    static func performFromUser(){ log() }
    static func performWhenPhotoLibraryDidChanged(){ log() }
    static func allTasksAreFinished(){ log() }

    struct charge: Loggable {
        private static var kChargeIdentifier:String{ return #function }

        static func opened(){ log() }
        static func cancelled(){ log() }
        static func openedInWelcomeTutorial(){ log() }
        static func openedInAllPaid(){ log() }
        static func openedInNeedToPay(){ log() }
        static func paid(charge:Charge){
            log(parameters: [
                kChargeIdentifier:String(describing: charge.identifier)
            ])
        }
        static func unpaid(charge:Charge){
            log(parameters: [
                kChargeIdentifier:String(describing: charge.identifier)
            ])
        }

        static func userHasShownInAppPromptRating(){ log() }

        static func restoredStorePayables(){ log() }

        struct scp: Loggable {
            static func activationStarted(){ log() }
            static func activationTimeout(){ log() }

            static func triedToAccess(){ log() }
            static func cancelledToAccess(){ log() }

            static func accessDenied(recordName:String?){ log(parameters:["recordName": recordName ?? "nil"]) }
            static func accessGranted(recordName:String?){ log(parameters:["recordName": recordName ?? "nil"]) }
            static func accessError(){ log() }
        }
    }

    struct app: Loggable {
        // app common
        static func launch(with option: AppLaunchOptions?){
            if let option = option, let identifierToReturn = option.identifierToReturn {
                log(parameters:["identifierToReturn":identifierToReturn])
            }else{
                log()
            }
        }

        static func minimizeAppDockDrawer(){ log() }
        static func maximizeAppDockDrawer(){ log() }

        static func userCalledCameraInApp(){ log() }

        static func userEnablesASB(){ log() }
        static func userDisablesASB(){ log() }

        struct defaults: Loggable {}
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


private struct LoggableVar {
    static var latestDate = [String:Date]()
}

extension Loggable {
    static func log(_ functionName:String=#function, parameters:[String:Any]?=nil){
        let identifier = createIdentifier(withFunction: functionName)

        let logginDate = Date()
        if let latest = LoggableVar.latestDate[identifier], logginDate.timeIntervalSince(latest) <= 1.0 {
            return
        }
        LoggableVar.latestDate[identifier] = logginDate

        DispatchQueue.global(qos: .background).async {
            guard let app = AppCenter.default.current else{
                return
            }

            var paramToCommit = [
                "appIdentifier": app.info.identifier
            ] as [String:Any]

            if let parameters = parameters{
                for o in parameters{
                    paramToCommit[o.key] = o.value
                }
            }

            let identifier = createIdentifier(withFunction: functionName)
            print("[i] Logged: ",identifier, parameters ?? "")
#if !DEBUG
            Analytics.logEvent(identifier, parameters: parameters)
#endif
        }
    }
}