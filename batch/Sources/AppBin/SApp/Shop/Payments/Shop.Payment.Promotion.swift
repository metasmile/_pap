//
// Created by BLACKGENE on 8/9/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

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

struct InAppStoreRatingPayment:VerifiablePayable,PreparablePayable{
    static func prepare(_ asyncSignal: AsyncWaitSignalable) {
    }

    static var action:PayableAction{
        return PayableAction(title: "Rate It".localized)
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        return true
    }

    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        return verifyForAvailableOnlyThisVersion()
    }
}

struct InAppPromptRatingPayment:VerifiablePayable, PreparablePayable{
    static func prepare(_ asyncSignal: AsyncWaitSignalable) {
    }

    static var action:PayableAction{
        return PayableAction(title: "Rate It".localized)
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        papLog.charge.userHasShownInAppPromptRating()

        return true
    }

    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        return verifyForAvailableOnlyThisVersion()
    }
}
