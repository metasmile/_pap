//
// Created by BLACKGENE on 8/21/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import GoogleMobileAds
import UIKit


private enum AdIds : String {
    /** REPLACE THE VALUES BY YOUR APP AND AD IDS **/
    case appId       = "ca-app-pub-3029312734389414~7736928915"

    case banner      = "ca-app-pub-3940256099942544/2934735716"
    case interestial = "ca-app-pub-3029312734389414/2463570879"
    case rewarded    = "ca-app-pub-3029312734389414/9160007015"
}

private extension AdIds{
    static var testDevices:[String] {
        return [
            //INFO: add here
            "670ee35cbfb960f94a7803d6e0e11f6e"
        ]
    }
}

//https://developers.google.com/admob/ios/interstitial?hl=en-GB
class FullscreenAdsViewingPayment:NSObject, KeyPathWatchable, PreparablePayable, AdManagerInterestialDelegate{

    private let adManager:AdManager = AdManager()

    @objc dynamic
    private var didAdLoad = false
    private var didAdPresented = false

    @objc dynamic
    private var didUserShowAd = false

    required override init() {

    }

    static var isEnable: Bool{
        if AppCenter.charge.isPaid(payable: self){
            return true
        }
        return NetworkReachabilityManager(host: "www.google.com")?.isReachable == true
    }

    static func prepare(_ asyncSignal: AsyncWaitSignalable) {

    }

    static var label: String {
        return "View".localized
    }

    func interestialDidReceiveAd() {
        didAdLoad = true
    }

    func interestialWillPresentScreen() {
        didAdPresented = true
    }

    func interestialWillDismissScreen() {
        assert(didAdPresented, "didAdPresented == false, not yet presented")
        didUserShowAd = didAdPresented
    }

    func interestialDidDismissScreen() {
        assert(DispatchQueue.currentIsMain)
    }

    func interestialWillLeaveApplication() {
        didUserShowAd = didAdPresented
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {

        var paid = false
        asyncSignal.begin()

        DispatchQueue.main.async{
            self.adManager.configureWithApp(AdIds.appId.rawValue)
//            self.adManager.setTestDevics(testDevices: AdIds.testDevices)

            //INFO: Banner
//            AdManager.shared.delegateBanner = self
//            AdManager.shared.createBannerAdInContainerView(viewController: self, unitId: AdIds.banner.rawValue)

            //INFO: rewarded
//            AdManager.shared.loadAndShowRewardAd(AdIds.rewarded.rawValue, viewController: self)
//            AdManager.shared.delegateReward = self

            // Load Ads
            self.watch(\.didAdLoad){
                // Present
                assert(DispatchQueue.currentIsMain)

                if let vc = UIViewController.root{
                    _ = self.adManager.showInterestial(vc)
                }
            }

            self.watch(\.didUserShowAd){
                paid = true
                asyncSignal.end()
            }

            self.adManager.delegateInterestial = self
            self.adManager.createAndLoadInterstitial(AdIds.interestial.rawValue)
        }

        asyncSignal.waitUntilEnd()

        return paid
    }
}


