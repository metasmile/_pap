//
// Created by BLACKGENE on 8/31/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import PropertyKit

private protocol SNSEngagementPaymentDefaults:PropertyDefaults{
    var latestPaidDate:Date?{set get}
}
extension Defaults:SNSEngagementPaymentDefaults{
    fileprivate var latestPaidDate:Date?{ set{ set(newValue) } get{ return get() } }
}

struct SNSEngagementPayment: RelativePayable {
    static var superPayables: HashSet<Payable.Type> {
        return self.defaultSuperPayables
    }

    static var isEnable: Bool {
        if let latestPaidDate = defaults.latestPaidDate{
            return Date().timeIntervalSince(latestPaidDate) > papTimeInterval.ofSNSEngagementPaymentLatestPaid
        }
        return true
    }

    private static var defaults: Defaults{
        return Defaults(suiteName: String(describing: self))
    }

    static var action:PayableAction{
        return PayableAction(title: URLOpenTypeSocialPage.label ?? "Visit".localized)
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {

        let urlType = URLOpenTypeSocialPage.self

        guard let webUrl = urlType.webUrl else{
            return false
        }

        var paid = false

        if let localUrl = urlType.localUrl, UIApplication.shared.canOpenURL(localUrl){
            asyncSignal.begin()

            UIApplication.shared.open(localUrl, options: [:]) { b in
                paid = b
                asyncSignal.end()
            }

        }else{

            asyncSignal.begin()

            var presented = false

            UIApplication.openSafari(with: webUrl, didPresent: {
                presented = true

            }, didLoad:{ loaded in
                paid = presented && loaded

            }, didDismiss: {
                asyncSignal.end()
            })
        }

        asyncSignal.waitUntilEnd()

        if paid{
            type(of: self).defaults.latestPaidDate = Date()
        }

        return paid
    }
}
