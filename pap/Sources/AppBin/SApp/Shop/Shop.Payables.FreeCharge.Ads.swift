//
// Created by BLACKGENE on 8/21/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import GoogleMobileAds
import UIKit

private let AdMobAppID = "ca-app-pub-3029312734389414~7736928915"

//https://developers.google.com/admob/ios/interstitial?hl=en-GB
struct FullscreenAdsViewingPayment:PreparablePayable{
    private let RewardAdsUnitId = "ca-app-pub-3029312734389414/9160007015"
    private let InterstitialAdsUnitId = "ca-app-pub-3029312734389414/2463570879"

    static var isEnable: Bool{
        //TODO: detect whether possible to show ads / e.g. internet connection etc
        return true
    }

    static func prepare(_ asyncSignal: AsyncWaitSignalable) {
        asyncSignal.begin()
        DispatchQueue.main.async{
            //Use mainqueue only.
            GADMobileAds.configure(withApplicationID: AdMobAppID)
            asyncSignal.end()
        }
        asyncSignal.waitUntilEnd()
    }

    static var label: String {
        return "View".localized
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {

        var paid = false
        asyncSignal.begin()

        DispatchQueue.main.async{
            let v = GADInterstitialViewController()
            v.adsUnitID = self.InterstitialAdsUnitId
            v.watch(\.isShown) {
                paid = v.isShown
                asyncSignal.end()
            }

            UIViewController.root?.present(v, animated: true)
        }

        asyncSignal.waitUntilEnd()

        return paid
    }
}

private final class GADInterstitialViewController: UIViewController, KeyPathWatchable, GADInterstitialDelegate {

    @objc dynamic
    var isShown:Bool = false

    private var receivedAd = false

    var adsUnitID:String? {
        didSet {
            if let id = adsUnitID {
                self.interstitial = GADInterstitial(adUnitID: id)
            }else{
                self.interstitial = nil
            }
        }
    }

    private var interstitial: GADInterstitial?{
        didSet {
            let request = GADRequest()
            interstitial?.delegate = self
            interstitial?.load(request)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if interstitial?.isReady == true{
            interstitial?.present(fromRootViewController: self)
        }

    }

    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        receivedAd = true
    }

    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
    }

    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
    }

    func interstitialDidFail(toPresentScreen ad: GADInterstitial) {
    }

    func interstitialWillDismissScreen(_ ad: GADInterstitial) {

    }

    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        isShown = receivedAd
    }

    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
    }
}