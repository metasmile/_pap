//
// Created by BLACKGENE on 8/9/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import PropertyKit
import Armchair

struct WelcomeTutorialPayment:Payable{
    //Actually will not be used.
    static var action: PayableAction{
        return PayableAction(title: "Use".localized)
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        return Defaults.shared.shortVersionDescription == .first
    }
}

private extension VerifiablePayable{
    func verifyForAvailableOnlyThisVersion() -> Bool? {
        let d = Defaults.shared.shortVersionDescription
        if d == .new{ // if new version arrived clear
            return false
        }
        return true
    }
}

struct InAppStoreRatingPayment:VerifiablePayable{

    static var action:PayableAction{
        return PayableAction(title: "Rate It".localized)
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        var paid = false
        asyncSignal.begin()

        Armchair.onDidDismissModalView { b in
            paid = true
            asyncSignal.end()
            Armchair.onDidDismissModalView(nil)
        }
        DispatchQueue.main.async{
            Armchair.rateApp()
        }
        asyncSignal.waitUntilEnd()
        return paid
    }

    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        return verifyForAvailableOnlyThisVersion()
    }
}

struct InAppPromptRatingPayment:VerifiablePayable, PreparablePayable{
    static func prepare(_ asyncSignal: AsyncWaitSignalable) {

        DispatchQueue.main.async{
            Armchair.appID(batchStrings.appStoreId)
            Armchair.useStoreKitReviewPrompt( true)
            Armchair.resetAllCounters()
            Armchair.shouldIncrementUseCountClosure { () -> Bool in
                return false
            }
        }
    }

    static var action:PayableAction{
        return PayableAction(title: "Rate It".localized)
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        var paid = false
        asyncSignal.begin()

        batchLog.charge.userHasShownInAppPromptRating()

        DispatchQueue.main.async{
            Armchair.showPrompt { info in
                paid = true
                asyncSignal.end()
                return true
            }
        }
        asyncSignal.waitUntilEnd()
        return paid
    }

    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        return verifyForAvailableOnlyThisVersion()
    }
}
