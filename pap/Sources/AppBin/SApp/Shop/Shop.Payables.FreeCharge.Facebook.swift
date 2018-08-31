//
// Created by BLACKGENE on 8/29/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import PropertyKit

//It is recommended not use fbsdk in other scope
import FBSDKShareKit
import FBSDKCoreKit

private enum FBSharePaymentStatus:Int{
    case initial
    case failed
    case cancelled
    case succeed
}

private enum FBSharePublicKeys:String{
    case pageId = "616758765335887"
    case appId = "443161082811578"

    case ogType = "pap:share"
    case ogActionType = "pap:fbsharepayment"
}


private protocol FBShareTypeDownloadUrlDefaults:PropertyDefaults{
    var shouldDisableInNormalVersion:Bool{set get}
}
extension Defaults:FBShareTypeDownloadUrlDefaults{
    var shouldDisableInNormalVersion:Bool{ set{ set(newValue) } get{ return get(or:false) } }
}

class FBSDKSharingDelegatePrototype:NSObject, FBSDKSharingDelegate, PropertyWatchable{
    @objc dynamic
    fileprivate var status: Int = FBSharePaymentStatus.initial.rawValue

    override required init() {
        super.init()
    }

    func sharer(_ sharer: FBSDKSharing!, didCompleteWithResults results: [AnyHashable: Any]!) {
        print(results)
        status = FBSharePaymentStatus.succeed.rawValue
    }

    func sharer(_ sharer: FBSDKSharing!, didFailWithError error: Error!) {
        print(error)
        status = FBSharePaymentStatus.failed.rawValue
    }

    func sharerDidCancel(_ sharer: FBSDKSharing!) {
        print(#function, sharer)
        status = FBSharePaymentStatus.cancelled.rawValue
    }
}

class FBShareTypeDownloadUrlPayment: FBSDKSharingDelegatePrototype, PreparablePayable {

    private static let defaults: Defaults = Defaults(suiteName: String(describing: FBShareTypeDownloadUrlPayment.self))

    class func prepare(_ asyncSignal: AsyncWaitSignalable) {
        if Defaults.shared.shortVersionDescription != .normal {
            defaults.shouldDisableInNormalVersion = false
        }
    }

    static var action: PayableAction {
        return PayableAction(title: "Share".localized)
    }

    static var isEnable: Bool {
        return autoreleasepool {
            if Defaults.shared.shortVersionDescription == .normal {
                return defaults.shouldDisableInNormalVersion == false
            }
            return FBSDKShareDialog().canShow()
        }
    }

    fileprivate static func makeShareContent() -> FBSDKSharingContent {

        //photo
//        let content = FBSDKShareMediaContent()
//        //TODO: fetch from remote.
//        content.media = [SLComposeViewController
//            FBSDKSharePhoto(image: R.image.fbSharePaymentShareTitle()!, userGenerated: true)
//        ]


        //link
        let content = FBSDKShareLinkContent()
        content.quote = papStrings.share.messageFirst

        //Common
        content.contentURL = "https://get.apps.photo".asURL
        content.peopleIDs = [FBSharePublicKeys.pageId.rawValue]
        content.pageID = FBSharePublicKeys.pageId.rawValue
        content.hashtag = FBSDKHashtag(string: "#GetPhotoApps")

        return content
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {

        var paid = false
        asyncSignal.begin()

        DispatchQueue.main.async {

            if let vc = UIViewController.presentable {
                FBSDKShareDialog.show(from: vc, with: type(of: self).makeShareContent(), delegate: self)

                super.watch(\.status) { (o, _) in
                    paid = o.status == FBSharePaymentStatus.succeed.rawValue
                    asyncSignal.end()
                }
            }else{
                asyncSignal.end()
            }
        }

        asyncSignal.waitUntilEnd()

        type(of: self).defaults.shouldDisableInNormalVersion = paid

        return paid
    }
}

class FBShareTypeDownloadMessagerPayment: FBSDKSharingDelegatePrototype, Payable{

    static var action:PayableAction{
        return PayableAction(title: "Share".localized)
    }

    static var isEnable: Bool {
        return autoreleasepool {
            return FBSDKMessageDialog().canShow()
        }
    }

    static func makeShareContent() -> FBSDKSharingContent{
        return FBShareTypeDownloadUrlPayment.makeShareContent()

//        let actionButton = FBSDKShareMessengerURLActionButton()
//        actionButton.title = "Free Download".localized
//        actionButton.url = papStrings.download.url.asURL
//        actionButton.fallbackURL = URLOpenTypeSocialPage.webUrl
//
//        let content = FBSDKShareMessengerGenericTemplateContent()
//
        //FIXME: unable to share error
//        let e = FBSDKShareMessengerGenericTemplateElement()
//        e.title = papStrings.nameTitle
//        e.subtitle = papStrings.tagline
//        e.imageURL = "https://postfoc.us/assets/images/title_og_1605.png".asURL
//        e.defaultAction = actionButton
//
//        content.element = e
//
//        //Common
//        content.contentURL = papStrings.download.url.asURL
//        content.peopleIDs = [FBSharePublicKeys.pageId.rawValue]
//        content.pageID = FBSharePublicKeys.pageId.rawValue
//        content.hashtag = FBSDKHashtag(string: "#GetPhotoApps")

//        return content
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {

        var paid = false
        asyncSignal.begin()

        DispatchQueue.main.async {

            FBSDKMessageDialog.show(with: type(of: self).makeShareContent(), delegate: self)
            super.watch(\.status) { (o,_) in
                paid = o.status == FBSharePaymentStatus.succeed.rawValue
                asyncSignal.end()
            }
        }

        asyncSignal.waitUntilEnd()

        return paid
    }
}
