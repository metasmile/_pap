//
// Created by BLACKGENE on 8/9/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

struct PayOfInitialTutorial:Payable{
    //Actually will not be used.
    private(set) static var label: String = "Welcome Free Use Pass"

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        return Defaults.shared.shortVersionDescription == .first
    }
}


struct SecretCodeInPermanentPayment:VerifiablePayable, PreparablePayable {
    private(set) static var label: String = "Hush. This is secret code for you."

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        return false
    }

    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        let d = Defaults.shared.shortVersionDescription
        return d == .first || d == .normal
    }

    private static var WatcherId:String {
        return #function+String(describing: SecretCodeInPermanentPayment.self)
    }

    static func prepare(_ asyncSignal: AsyncWaitSignalable) {
        AppCenter.default.watch(\.currentIdentifier, id:WatcherId){

        }
    }
}

struct SecretCodeInVersionPayment:VerifiablePayable{
    private(set) static var label: String = "Hush. This is secret code for you."

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        return false
    }

    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        let d = Defaults.shared.shortVersionDescription
        return d == .first || d == .normal
    }
}
