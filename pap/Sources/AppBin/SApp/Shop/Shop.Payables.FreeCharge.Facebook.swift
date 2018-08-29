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

class FBSharePayment:NSObject, Payable, PropertyWatchable, FBSDKSharingDelegate{

    @objc dynamic
    private var status:Int = FBSharePaymentStatus.initial.rawValue

    override required init() {
        super.init()
    }

    static var action:PayableAction{
        return PayableAction(title: "Share".localized)
    }

    static var isEnable: Bool {
        return autoreleasepool {
            return FBSDKShareDialog().canShow()
        }
    }

    private let FB_APP_ID = "443161082811578"
    private let FB_APP_OG_ACTION_TYPE = "pap:fbsharepayment"
    private let FB_APP_OG_TYPE = "pap:share"

    //https://findmyfbid.com/
    private let FB_PAGE_ID = "616758765335887"

    //TODO: retain permmission : https://developers.facebook.com/apps/443161082811578/dashboard/

    func makeOGPhotoContent() -> FBSDKSharingContent {
        //TODO: fetch from remote.
        let photo = FBSDKSharePhoto(image: R.image.shopSAppIcon()!, userGenerated: false)!

        let og = FBSDKShareOpenGraphObject(properties: [
            "og:type": FB_APP_OG_TYPE,
            "og:title": papStrings.nameTitle,
            "og:url": papStrings.download.url,
            "og:caption": papStrings.tagline,
            "og:description": papStrings.share.messageFirst,
            "fb:app_id": FB_APP_ID,
            "article:author": papStrings.name,
            "article:publisher": papStrings.name,
            "fb:explicitly_shared": "true"
        ])
        
        let ogAction = FBSDKShareOpenGraphAction()
        ogAction.actionType = FB_APP_OG_ACTION_TYPE
        ogAction.setArray([photo], forKey: "image")
        ogAction.setObject(og, forKey: FB_APP_OG_TYPE)
//        ogAction.setPhoto(photo, forKey: FBAPP_OG_TYPE)
        
        let ogContent = FBSDKShareOpenGraphContent()
        ogContent.action = ogAction
        ogContent.previewPropertyName = FB_APP_OG_TYPE
        
        return ogContent
    }
    
    func makeShareContent() -> FBSDKSharingContent{

        //photo
//        let content = FBSDKShareMediaContent()
//        //TODO: fetch from remote.
//        content.media = [
//            FBSDKSharePhoto(image: R.image.fbSharePaymentShareTitle()!, userGenerated: true)
//        ]

    //link
        let content = FBSDKShareLinkContent()
        content.quote = papStrings.share.messageFirst

        //Common
        content.contentURL = "https://get.apps.photo".asURL
        content.peopleIDs = [FB_PAGE_ID]
        content.pageID = FB_PAGE_ID
        content.hashtag = FBSDKHashtag(string: "#GetPhotoApps")

        return content
    }
    
    func tryShare() -> Bool{
        if let vc = UIViewController.presentable{
//            FBSDKShareDialog.show(from: vc, with: makeOGPhotoContent(), delegate: self)
            FBSDKShareDialog.show(from: vc, with: makeShareContent(), delegate: self)
            return true
        }
        return false
    }
    
    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {

        var paid = false
        asyncSignal.begin()

        DispatchQueue.main.async {
            
            if self.tryShare(){
                self.watch(\.status) { (o,_) in
                    paid = o.status == FBSharePaymentStatus.succeed.rawValue
                    asyncSignal.end()
                }
            }else{
                asyncSignal.end()
            }
        }

        asyncSignal.waitUntilEnd()
        return paid
    }


    func sharer(_ sharer: FBSDKSharing!, didCompleteWithResults results: [AnyHashable : Any]!) {
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
