//
// Created by BLACKGENE on 2018-09-24.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class MailContactPayment<Type: MailContactType>: NSObject, Payable, MFMailComposeViewControllerDelegate {

    static var action:PayableAction{
        return PayableAction(title: "Write".localized)
    }

    private var mailComposerCompletionBlock: ((_ sent: Bool) -> Void)?

    required override init() {}

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        return self.send(to: Type.attributes.addresses, subject: Type.attributes.subject, asyncSignal)
    }

    @discardableResult
    private func send(to recipients: [String], subject:String, _ asyncSignal: AsyncWaitSignalable) -> Bool {
        guard MFMailComposeViewController.canSendMail() else { return false }

        var paid = false
        asyncSignal.begin()

        DispatchQueue.main.async {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(recipients)
            mailComposer.setSubject(subject)
            mailComposer.popoverPresentationController?.sourceView = UIViewController.presentable?.view

            self.mailComposerCompletionBlock = { sent in
                paid = sent
                asyncSignal.end()
            }
            UIViewController.present(mailComposer, animated: true, completion: nil)
        }

        asyncSignal.waitUntilEnd()
        return paid
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        mailComposerCompletionBlock?(result == .sent)
        mailComposerCompletionBlock = nil

        controller.dismiss(animated: true, completion: nil)
    }
}
