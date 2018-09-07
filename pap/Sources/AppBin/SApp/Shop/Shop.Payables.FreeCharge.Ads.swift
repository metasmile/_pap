//
// Created by BLACKGENE on 8/21/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import GoogleMobileAds
import UIKit
import PropertyKit

//https://developers.google.com/admob/ios/interstitial?hl=en-GB
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

private protocol AdsDefaultsInfo:PropertyDefaults{
    var latestAdsShownDate: [String:Date]{get set} //ad unitId : Date
}

extension Defaults: AdsDefaultsInfo {
    fileprivate var latestAdsShownDate: [String:Date] {
        set{ set(newValue) } get{ return get(or:[String:Date]()) }
    }
}

protocol GADInterestialType {
    static var appId: String {get}
    static var unitId: String {get}
    static var interval: Double? {get}
    static func prepare(_ asyncSignal: AsyncWaitSignalable)
}

struct GADInterestialTypeTimeOfUses: GADInterestialType{
    private(set) static var appId: String = _AdsSystemInfo.appId.rawValue
    private(set) static var unitId: String = _AdsSystemInfo.interestial.rawValue
    private(set) static var interval: Double?

    static func prepare(_ asyncSignal: AsyncWaitSignalable) {}
}

struct GADInterestialTypeBlockOfUses: GADInterestialType{
    private(set) static var appId: String = _AdsSystemInfo.appId.rawValue
    private(set) static var unitId: String = _AdsSystemInfo.interestial.rawValue
    private(set) static var interval: Double? = papTimeInterval.ofGADInterestialTypeBlockOfUses

    static func prepare(_ asyncSignal: AsyncWaitSignalable) {
        if wasPaid(){
            prepareTrackingAds()
        }else{
            AppCenter.charge.bank.watch(\.savedChargeIdentifier){
                prepareTrackingAds()
            }
        }
    }

    private static var thisPayment:Payable.Type{
        return GADInterestialAdsViewingPayment<GADInterestialTypeBlockOfUses>.self
    }

    private static func wasPaid() -> Bool{
        return AppCenter.charge.isPaid(payable: thisPayment)
    }

    private static func prepareTrackingAds(){
        let watcherId = String(describing: self)+#function
        if wasPaid(){
            DispatchQueue.mainAsyncAfter(qos: .background) {
                AppCenter.default.watch(\.currentIdentifier, id:watcherId){ app, _ in
                    if wasPaid(), AppCenter.isPaidInCurrentContext == false, app.currentIdentifier != ShopApp.info.identifier{
                        AppCenter.charge.try(for: thisPayment)
                    }
                }
            }
        }else{
            AppCenter.default.unwatch(\.currentIdentifier, forIds:[watcherId])
        }
    }
}

class GADInterestialAdsViewingPayment<T: GADInterestialType>:NSObject, RelativePayable, PropertyWatchable, PreparablePayable, GADManagerInterestialDelegate{
    static var superPayables: HashSet<Payable.Type> {
        return self.defaultSuperPayables
    }

    private let adManager: GADManager = GADManager()

    @objc dynamic
    private var didAdLoad = false
    private var didAdPresented = false

    @objc dynamic
    private var didUserShowAd = false

    private var errorWhileLoadAd:GADRequestError?

    private lazy var dateKey = String(describing: type(of:self))
    
    required override init() {
        super.init()

        self.watch(\.didUserShowAd, id: T.unitId){
            if self.didUserShowAd{
                Defaults.shared.latestAdsShownDate[self.dateKey] = Date()
            }
        }
    }

    static var isEnable: Bool{
        if AppCenter.charge.isPaid(payable: self){
            return true
        }
        return NetworkReachabilityManager(host: "www.google.com")?.isReachable == true
    }

    static func prepare(_ asyncSignal: AsyncWaitSignalable) {
        T.prepare(asyncSignal)
    }

    static var action: PayableAction{
        return PayableAction(title: "See".localized)
    }

    func interestialDidReceiveAd() {
        didAdLoad = true
    }

    func interestialDidFailToReceiveAd(error:GADRequestError) {
        errorWhileLoadAd = error
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

        if let interval = T.interval, let latestShowenDate = Defaults.shared.latestAdsShownDate[dateKey]{
            if interval > Date().timeIntervalSince(latestShowenDate){
                return true
            }
        }

        if NetworkReachabilityManager(host: "www.google.com")?.isReachable == false{
            return false
        }

        var paid = false
        asyncSignal.begin()

        DispatchQueue.main.async{
            self.adManager.configureWithApp(T.appId)
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

                    //INFO: No fill Error
                    if let error = self.errorWhileLoadAd, error.domain.trimmed=="com.google.ads" && error.code == GADErrorCode.noFill.rawValue{
                        // alert -> end()
                        var actions = [UIAlertAction]()

                        //INFO: if current is not ShopApp, present Deactivate option.
                        if AppCenter.default.current != ShopApp.self{
                            let goShopAppAction = UIAlertAction(title: "Open %@".localizedFormatted(ShopApp.info.displayName), style: .default) { action in
                                asyncSignal.end()
                                AppCenter.default.openApp(identifier:ShopApp.info.identifier)
                            }
                            actions.append(goShopAppAction)
                        }

                        UIAlertController.alert("\("Please turn off following option, and reset advertising identifier in Settings. Then try again. ".localized)\n\n Settings > Privacy > Advertising > Limit Ad Tracking / 'Reset Advertising Identifier ...'"
                                , title: "An Error Occurred While Receiving Ads.".localized
                                , buttonTitle: "OK".localized
                                , actions: actions
                                , completion: { action in
                                    asyncSignal.end()
                                }
                        )

                    }else{

                        // end
                        asyncSignal.end()
                    }
                }
            }

            self.watch(\.didUserShowAd){
                paid = self.didUserShowAd
                asyncSignal.end()
            }

            self.adManager.delegateInterestial = self
            self.adManager.createAndLoadInterstitial(T.unitId)
        }

        asyncSignal.waitUntilEnd()

        return paid
    }
}


