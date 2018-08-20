//
// Created by BLACKGENE on 8/9/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit
import Armchair

struct WelcomeTutorialPayment:Payable{
    //Actually will not be used.
    private(set) static var label: String = "Welcome Free Use Pass"

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        return Defaults.shared.shortVersionDescription == .first
    }
}


private extension VerifiablePayable{
    func verifyForAvailableOnlyThisVersion() -> Bool? {
        let d = Defaults.shared.shortVersionDescription
        if d == .new || d == .skippedNew{ // if new version arrived clear
            return false
        }
        return true
    }
}

struct InAppStoreRatingPayment:VerifiablePayable{

    static var label:String{
        return "Rate It".localized
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

struct InAppPromptRatingPayment:VerifiablePayable{

    static var label:String{
        return "Rate It".localized
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        var paid = false
        asyncSignal.begin()

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
