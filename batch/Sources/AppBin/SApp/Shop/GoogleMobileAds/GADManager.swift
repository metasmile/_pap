/*
WARNING:
Should use timer queue while use independent UIViewController - lazy safe area layout problem.

viewDidLoad
-> DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
    _ = GADManager.shared.showInterestial(self)
}
*/

import Foundation
import UIKit
import GoogleMobileAds

enum ViewTag : Int{
    case adContainer
    case adBanner
}

public protocol GADManagerBannerDelegate{
    func adViewDidReceiveAd()
    func adViewDidFailToReceiveAd()
    func adViewWillPresentScreen()
    func adViewWillDismissScreen()
    func adViewDidDismissScreen()
    func adViewWillLeaveApplication()
}

public protocol GADManagerInterestialDelegate{
    func interestialDidReceiveAd()
    func interestialDidFailToReceiveAd(error:GADRequestError)
    func interestialWillPresentScreen()
    func interestialWillDismissScreen()
    func interestialDidDismissScreen()
    func interestialWillLeaveApplication()
}

public protocol GADManagerRewardDelegate{
    func rewardAdGiveRewardToUser(type:String, amount: NSDecimalNumber)
    func rewardAdFailedToLoad()
    func rewardAdDidReceive(rewardViewController: UIViewController?)
    func rewardAdDidOpen()
    func rewardAdDidStartPlaying()
    func rewardAdDidClose()
    func rewardAdWillLeaveApplication()
}

//default implementation GADManagerBannerDelegate
public extension GADManagerBannerDelegate {
    func adViewDidReceiveAd() {}
    func adViewDidFailToReceiveAd() {}
    func adViewWillPresentScreen() {}
    func adViewWillDismissScreen() {}
    func adViewDidDismissScreen() {}
    func adViewWillLeaveApplication() {}
}

//default implementation GADManagerInterestialDelegate
public extension GADManagerInterestialDelegate {
    func interestialDidReceiveAd() {}
    func interestialDidFailToReceiveAd(error:GADRequestError) {}
    func interestialWillPresentScreen() {}
    func interestialWillDismissScreen() {}
    func interestialDidDismissScreen() {}
    func interestialWillLeaveApplication() {}
}

//default implementation GADManagerRewardDelegate
public extension GADManagerRewardDelegate{
    func rewardAdGiveRewardToUser(type:String, amount: NSDecimalNumber) {}
    func rewardAdFailedToLoad() {}
    func rewardAdDidReceive(rewardViewController: UIViewController?) {
        if GADRewardBasedVideoAd.sharedInstance().isReady == true {
            if let rewardViewController = rewardViewController {
                GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: rewardViewController)
            }
        }
    }
    func rewardAdDidOpen() {}
    func rewardAdDidStartPlaying() {}
    func rewardAdDidClose() {}
    func rewardAdWillLeaveApplication() {}
}

public final class GADManager: NSObject {
    public var ADS_DISABLED = false
    public var delegateBanner: GADManagerBannerDelegate?
    public var delegateInterestial: GADManagerInterestialDelegate?
    public var delegateReward: GADManagerRewardDelegate?
    
    private var viewController:UIViewController?
    private var bannerViewContainer:UIView?
    private var rewardViewController:UIViewController?
    
    private var interestial:GADInterstitial?
    private var testDevices:[String] = [""]
    private var adsInterstialDict = [String : GADInterstitial]()
    
    let borderSizeBetweenBannerAndContent:CGFloat = 5
    
    
    public override init() {
        super.init()
    }
    
    public func configureWithApp(_ id : String){
        GADMobileAds.sharedInstance().start { (status) in
            
        }
    }
    
    public func setTestDevics(testDevices: [String]){
#if DEBUG
        self.testDevices = testDevices
        self.testDevices += [kGADSimulatorID as! String ] //all simulator
#endif
    }

    private func getGADRequest() -> GADRequest{
        let request = GADRequest()
#if DEBUG
        if self.testDevices.count > 0{
            request.testDevices = self.testDevices
        }
#endif
        return request
    }
    
    private func createAndLoadBannerAd(unitId:String, rootViewController:UIViewController) -> GADBannerView? {
        let bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        bannerView.tag = ViewTag.adBanner.rawValue
        bannerView.adUnitID = unitId
        bannerView.delegate = self
        bannerView.rootViewController = rootViewController
        bannerView.load(getGADRequest())
        return bannerView
    }
    
    private func adBannerPositionUpdate(){
        guard ADS_DISABLED == false else {
            return
        }
        
        if let bannerViewContainer = self.bannerViewContainer{
            if let adBanner = bannerViewContainer.viewWithTag(ViewTag.adBanner.rawValue) {
                
                adBanner.frame = CGRect(x: 0, y: borderSizeBetweenBannerAndContent, width: adBanner.frame.size.width, height: adBanner.frame.size.height)
                //adBanner.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
                adBanner.translatesAutoresizingMaskIntoConstraints = false
                bannerViewContainer.addConstraints(
                    [NSLayoutConstraint(item: adBanner,
                                        attribute: .firstBaseline,
                                        relatedBy: .equal,
                                        toItem: bannerViewContainer,
                                        attribute: .top,
                                        multiplier: 1,
                                        constant: borderSizeBetweenBannerAndContent),
                     NSLayoutConstraint(item: adBanner,
                                        attribute: .centerX,
                                        relatedBy: .equal,
                                        toItem: bannerViewContainer,
                                        attribute: .centerX,
                                        multiplier: 1,
                                        constant: 0)
                    ])
            }
        }
    }
    
    public func adBannerHide(){
        if let bannerViewContainer = self.bannerViewContainer{
            bannerViewContainer.isHidden = true
        }
    }
    
    public func adBannerShow(){
        guard ADS_DISABLED == false else {
            return
        }
        
        if let bannerViewContainer = self.bannerViewContainer {
            bannerViewContainer.isHidden = false
        }
    }
    
    public func adBannerRemovePermanently(){
        if let bannerViewContainer = self.bannerViewContainer {
            bannerViewContainer.removeFromSuperview()
        }
    }
    
    public func createBannerAdInContainerView(viewController:UIViewController, unitId:String) {
        guard ADS_DISABLED == false else {
            return
        }
        
        self.viewController = viewController
        
        if let bannerViewContainer = self.bannerViewContainer {
            bannerViewContainer.removeFromSuperview()
            self.bannerViewContainer = nil
        }
        
        let safeAreaGap:CGFloat =    getSafeAreaGap(viewController)
        let viewHeight:CGFloat  =    UIDevice.current.userInterfaceIdiom == .pad ? 90 + borderSizeBetweenBannerAndContent : 50.0 + borderSizeBetweenBannerAndContent //iPhone or iPad banner height + 5 pixel gap
        
        let adContainerview     =   UIView(frame: CGRect.zero)
        adContainerview.tag     =   ViewTag.adContainer.rawValue
        adContainerview.frame   =   CGRect(x: 0,
                                           y: viewController.view.frame.size.height - viewHeight - safeAreaGap,
                                           width: viewController.view.frame.size.width,
                                           height: viewController.view.frame.size.height)
        adContainerview.backgroundColor = UIColor.black
        adContainerview.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin, .flexibleRightMargin, .flexibleWidth]
        
        self.bannerViewContainer = adContainerview
        viewController.view.addSubview(adContainerview)
        viewController.view.bringSubviewToFront(adContainerview)
        
        let bannerView = createAndLoadBannerAd(unitId: unitId, rootViewController: viewController)
        adContainerview.addSubview(bannerView!)
        adBannerPositionUpdate()
    }
    
    public func getSafeAreaGap(_ viewController: UIViewController) -> CGFloat {
        if #available(iOS 11.0, *) {
            return viewController.view.safeAreaInsets.bottom
        }
        
        return 0.0
    }
    
    // MARK:- Interestial
    public func createAndLoadInterstitial(_ adUnit: String){
        interestial = GADInterstitial(adUnitID: adUnit)
        interestial?.delegate = self
        interestial?.load(getGADRequest())
    }
    
    public func showInterestial(_ viewController: UIViewController) -> Bool{
        if let interestial = self.interestial{
            if interestial.isReady {
                interestial.present(fromRootViewController: viewController)
                return true
            }
            else {
                
            }
        }
        return false
    }
    
    // MARK:- Reward Video Ads
    public func loadAndShowRewardAd(_ adUnit: String, viewController: UIViewController){
        self.rewardViewController = viewController
        GADRewardBasedVideoAd.sharedInstance().delegate = self
        GADRewardBasedVideoAd.sharedInstance().load(GADRequest(), withAdUnitID: adUnit)
    }
}

// MARK:- GADBannerViewDelegate
extension GADManager: GADBannerViewDelegate {
    /// Tells the delegate an ad request loaded an ad.
    public func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        
        delegateBanner?.adViewDidReceiveAd()
    }
    
    /// Tells the delegate an ad request failed.
    public func adView(_ bannerView: GADBannerView,
                       didFailToReceiveAdWithError error: GADRequestError) {
        
        delegateBanner?.adViewDidFailToReceiveAd()
    }
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    public func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        
        delegateBanner?.adViewWillPresentScreen()
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    public func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        
        delegateBanner?.adViewWillDismissScreen()
    }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    public func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        
        delegateBanner?.adViewDidDismissScreen()
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    public func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        
        delegateBanner?.adViewWillLeaveApplication()
    }
}

// MARK:- GADInterstitialDelegate
extension GADManager: GADInterstitialDelegate {
    /// Tells the delegate an ad request succeeded.
    public func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        
        delegateInterestial?.interestialDidReceiveAd()
    }
    
    /// Tells the delegate an ad request failed.
    public func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        
        delegateInterestial?.interestialDidFailToReceiveAd(error:error)
    }
    
    /// Tells the delegate that an interstitial will be presented.
    public func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        
        delegateInterestial?.interestialWillPresentScreen()
    }
    
    /// Tells the delegate the interstitial is to be animated off the screen.
    public func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        
        delegateInterestial?.interestialWillDismissScreen()
    }
    
    /// Tells the delegate the interstitial had been animated off the screen.
    public func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        
        delegateInterestial?.interestialDidDismissScreen()
    }
    
    /// Tells the delegate that a user click will open another app
    /// (such as the App Store), backgrounding the current app.
    public func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        
    }
}

// MARK:- GADRewardBasedVideoAdDelegate
extension GADManager: GADRewardBasedVideoAdDelegate {
    public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd,
                            didRewardUserWith reward: GADAdReward) {
        
        delegateReward?.rewardAdGiveRewardToUser(type: reward.type, amount: reward.amount)
    }
    
    public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd,
                            didFailToLoadWithError error: Error) {
        
        delegateReward?.rewardAdFailedToLoad()
    }
    
    public func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd:GADRewardBasedVideoAd) {
        
        delegateReward?.rewardAdDidReceive(rewardViewController: self.rewardViewController)
    }
    
    public func rewardBasedVideoAdDidOpen(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        
        delegateReward?.rewardAdDidOpen()
    }
    
    public func rewardBasedVideoAdDidStartPlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        
        delegateReward?.rewardAdDidStartPlaying()
    }
    
    public func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        
        delegateReward?.rewardAdDidClose()
    }
    
    public func rewardBasedVideoAdWillLeaveApplication(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        
        delegateReward?.rewardAdWillLeaveApplication()
    }

}
