//
// Created by BLACKGENE on 8/21/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import GoogleMobileAds
import UIKit

private let AdMobAppID = "ca-app-pub-3029312734389414~7736928915"

#if DEBUG
private let Test_Banner = "ca-app-pub-3940256099942544/2934735716"
private let Test_Interstitial = "ca-app-pub-3940256099942544/4411468910"
private let Test_InterstitialVideo = "ca-app-pub-3940256099942544/5135589807"
private let Test_RewardedVideo = "ca-app-pub-3940256099942544/1712485313"
private let Test_NativeAdvanced = "ca-app-pub-3940256099942544/3986624511"
private let Test_NativeAdvancedVideo = "ca-app-pub-3940256099942544/2521693316"
#endif

//https://developers.google.com/admob/ios/interstitial?hl=en-GB
struct FullscreenAdsViewingPayment:PreparablePayable{
    private let RewardAdsUnitId = "ca-app-pub-3029312734389414/9160007015"

#if DEBUG
    private let InterstitialAdsUnitId = Test_Interstitial
#else
    private let InterstitialAdsUnitId = "ca-app-pub-3029312734389414/2463570879"
#endif

    static var isEnable: Bool{
        //TODO: detect whether possible to show ads / e.g. internet connection etc
        return true
    }

    static func prepare(_ asyncSignal: AsyncWaitSignalable) {
        DispatchQueue.main.async{
            //Use mainqueue only.
            GADMobileAds.configure(withApplicationID: AdMobAppID)
        }
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
            v.watch(\.isReady) {

                if v.isReady{
                    v.watch(\.wasAdShown) {
                        paid = v.wasAdShown
                        asyncSignal.end()
                    }
                    UIViewController.root?.present(v, animated: true)

                }else{
                    //failed to load ads, -> payment failed. -> exit
                    paid = false
                    asyncSignal.end()
                }
            }
        }

        asyncSignal.waitUntilEnd()

        return paid
    }
}

private final class GADInterstitialViewController: UIViewController, KeyPathWatchable, GADInterstitialDelegate {

    @objc dynamic
    var isReady:Bool = false

    @objc dynamic
    var wasAdShown:Bool = false

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
#if DEBUG
            request.testDevices = ["670ee35cbfb960f94a7803d6e0e11f6e"]
#endif
            interstitial?.delegate = self
            interstitial?.load(request)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(interstitial?.isReady == true, "interstitial ads not ready")
        if interstitial?.isReady == true{
            interstitial?.present(fromRootViewController: self)
        }
    }

    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        assert(DispatchQueue.currentIsMain)
        isReady = true
        print(#function)
    }

    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print(#function, error)
        isReady = false
    }

    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        print(#function)
    }

    func interstitialDidFail(toPresentScreen ad: GADInterstitial) {
        print(#function)
        wasAdShown = false
    }

    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        print(#function)
    }

    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        print(#function)
        wasAdShown = isReady
    }

    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        print(#function)
        wasAdShown = isReady
    }
}