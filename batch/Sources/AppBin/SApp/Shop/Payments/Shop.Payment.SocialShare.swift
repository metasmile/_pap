//
// Created by BLACKGENE on 8/8/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension UIActivity.ActivityType {
    static let addToReminder = UIActivity.ActivityType("com.apple.reminders.RemindersEditorExtension")
    static let addToNote = UIActivity.ActivityType("com.apple.mobilenotes.SharingExtension")
    static let addToiCloudDrive = UIActivity.ActivityType("com.apple.CloudDocsUI.AddToiCloudDrive") //TODO: not work excluding this
}

struct SocialSharePayment:Payable{
    static var action:PayableAction{
        return PayableAction(title: "Share".localized)
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {

        var paid = false
        asyncSignal.begin()

        UIActivityViewController.share(activityItems: [batchStrings.share.messageFirst], excludedActivityTypes:[.copyToPasteboard, .addToReadingList, .addToReminder, .addToNote, .addToiCloudDrive]) { activityType, completed, returnedItems, error in
            paid = completed
            asyncSignal.end()
        }
        asyncSignal.waitUntilEnd()
        return paid
    }
}
