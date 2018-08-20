//
// Created by BLACKGENE on 8/8/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

struct FreeAppPayment<T:App>: VerifiablePayable{
    static var label: String{
        return "Get Free Use".localized
    }
    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        return true
    }
    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        return true
    }
}

struct SocialSharePayment:Payable{

    static var label:String{
        return "Share".localized
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {

        var paid = false
        asyncSignal.begin()

        DispatchQueue.main.async {
            let shareActivity = UIActivityViewController(activityItems: [papStrings.share.messageFirst], applicationActivities: nil)
            shareActivity.excludedActivityTypes = [.copyToPasteboard, .addToReadingList, .addToReminder, .addToNote, .addToiCloudDrive]
            shareActivity.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                paid = completed
                asyncSignal.end()
            }
            shareActivity.popoverPresentationController?.sourceView = UIViewController.root?.view
            UIViewController.root?.present(shareActivity, animated: true, completion: nil)
        }
        asyncSignal.waitUntilEnd()
        return paid
    }
}

extension UIActivityType {
    static let addToReminder = UIActivityType("com.apple.reminders.RemindersEditorExtension")
    static let addToNote = UIActivityType("com.apple.mobilenotes.SharingExtension")
    static let addToiCloudDrive = UIActivityType("com.apple.CloudDocsUI.AddToiCloudDrive") //TODO: not work excluding this
}


class FeedbackPayment: NSObject, Payable, MFMailComposeViewControllerDelegate {

    static var label:String{
        return "Write".localized
    }

    private var mailComposerCompletionBlock: ((_ sent: Bool) -> Void)?

    required override init() {}

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        guard MFMailComposeViewController.canSendMail() else { return false }

        var paid = false
        asyncSignal.begin()

        DispatchQueue.main.async {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients([papStrings.feedback.email])
            mailComposer.setSubject("👋 " + "My Feedback on %@".localizedFormatted(papStrings.name))
            mailComposer.popoverPresentationController?.sourceView = UIViewController.root?.view

            self.mailComposerCompletionBlock = { sent in
                paid = sent
                asyncSignal.end()
            }
            UIViewController.root?.present(mailComposer, animated: true, completion: nil)
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


