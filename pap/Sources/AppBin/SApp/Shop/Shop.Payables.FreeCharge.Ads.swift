//
// Created by BLACKGENE on 8/21/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import GoogleMobileAds
import UIKit

private enum _AdsSystemInfo: String {
    /** REPLACE THE VALUES BY YOUR APP AND AD IDS **/
    case appId       = "ca-app-pub-3029312734389414~7736928915"

    case banner      = "ca-app-pub-3940256099942544/2934735716"
    case interestial = "ca-app-pub-3029312734389414/2463570879"
    case rewarded    = "ca-app-pub-3029312734389414/9160007015"
}

private extension _AdsSystemInfo {
    static var testDevices:[String] {
        return [
            //INFO: add here
            "670ee35cbfb960f94a7803d6e0e11f6e"
        ]
    }
}

protocol GADInterestialType {
    static var appId: String {get}
    static var unitId: String {get}
}

struct GADInterestialTypeTimeOfUses: GADInterestialType{
    private(set) static var appId: String = _AdsSystemInfo.appId.rawValue
    private(set) static var unitId: String = _AdsSystemInfo.interestial.rawValue
}

struct GADInterestialTypeBlockOfUses: GADInterestialType{
    private(set) static var appId: String = _AdsSystemInfo.appId.rawValue
    private(set) static var unitId: String = _AdsSystemInfo.interestial.rawValue
}

//https://developers.google.com/admob/ios/interstitial?hl=en-GB
final class GADInterestialAdsViewingPayment<Type: GADInterestialType>:NSObject, KeyPathWatchable, PreparablePayable, GADManagerInterestialDelegate{

    private let adManager: GADManager = GADManager()

    @objc dynamic
    private var didAdLoad = false
    private var didAdPresented = false

    @objc dynamic
    private var didUserShowAd = false

    required override init() {}

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

    func interestialDidFailToReceiveAd() {
        didAdLoad = false
    }

    func interestialWillPresentScreen() {
        didAdPresented = true
    }

    func interestialWillDismissScreen() {
        assert(didAdPresented, "didAdPresented == false, not yet presented")
        
    }

    func interestialDidDismissScreen() {
        assert(DispatchQueue.currentIsMain)
        didUserShowAd = didAdLoad && didAdPresented
    }

    func interestialWillLeaveApplication() {
        didUserShowAd = didAdLoad && didAdPresented
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        if NetworkReachabilityManager(host: "www.google.com")?.isReachable == false{
            return false
        }

        var paid = false
        asyncSignal.begin()

        DispatchQueue.main.async{
            self.adManager.configureWithApp(Type.appId)
//            self.adManager.setTestDevics(testDevices: AdIds.testDevices)

            //INFO: Banner
//            GADManager.shared.delegateBanner = self
//            GADManager.shared.createBannerAdInContainerView(viewController: self, unitId: AdIds.banner.rawValue)

            //INFO: rewarded
//            GADManager.shared.loadAndShowRewardAd(AdIds.rewarded.rawValue, viewController: self)
//            GADManager.shared.delegateReward = self

            // Load Ads
            self.watch(\.didAdLoad){
                // Present
                assert(DispatchQueue.currentIsMain)

                if let vc = UIViewController.presentable, self.adManager.showInterestial(vc){
                    // succeed
                }else{
                    // failed
                    paid = false
                    asyncSignal.end()
                }
            }

            self.watch(\.didUserShowAd){
                paid = self.didUserShowAd
                asyncSignal.end()
            }

            self.adManager.delegateInterestial = self
            self.adManager.createAndLoadInterstitial(Type.unitId)
        }

        asyncSignal.waitUntilEnd()

        return paid
    }
}


