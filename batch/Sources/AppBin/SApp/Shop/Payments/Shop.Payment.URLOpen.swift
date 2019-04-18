//
// Created by BLACKGENE on 2018-09-24.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

struct URLOpenPayment<T: URLOpenType>: Payable {

    static var action:PayableAction{
        return PayableAction(title: T.label ?? "Visit".localized)
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        guard let webUrl = T.webUrl else{
            return false
        }

        var paid = false

        //Phase 1 : local url with scheme
        if let localUrl = T.localUrl{
            asyncSignal.begin()

            DispatchQueue.mainAsyncIfNot {
                UIApplication.shared.open(localUrl, options: [:]) { b in
                    paid = b
                    asyncSignal.end()
                }
            }

            asyncSignal.waitUntilEnd()

            if paid{
                return paid
            }
        }

        //Phase 2 : remote url
        asyncSignal.begin()

        var presented = false

        DispatchQueue.mainAsyncIfNot {
            UIApplication.openSafari(with: webUrl, didPresent: {
                presented = true

            }, didLoad:{ loaded in
                paid = presented && loaded

            }, didDismiss: {
                asyncSignal.end()
            })
        }

        asyncSignal.waitUntilEnd()
        return paid
    }
}
