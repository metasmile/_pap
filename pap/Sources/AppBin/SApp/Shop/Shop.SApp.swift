//
// Crea?ted by B?LACKGEN?E on 8/8/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import FirebaseMLVision
import PropertyKit
import Contacts
import ContactsUI
import EventKit
import EventKitUI
import UIKit
import SafariServices
import StoreKit

extension AppLaunchOptionsKey {
    //value type: App.Type
    static let ShopAppCallerAppType = AppLaunchOptionsKey(rawValue:#file.hashValue)
}

public class ShopApp: NSObject
        , PropertyWatchable
        , SApp
        , AppDockApp
        , LaunchableApp
        , ManagerConfigurableApp {

    public private(set) lazy var content: AppDockContent? = ShopAppDockContent()

    fileprivate lazy var contentImageCache:NSCache = NSCache<NSString, UIImage>()

    public static let info = AppInfo(
            identifier: "com.stells.pap.shop"
            , version: "1.0"
            , phase: .release
            , appType: ShopApp.self
            , displayName: "Shop"
            , description: nil
            , keywords: nil
            , iconBundleName: R.image.shopSAppIcon.name
            , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: .default)
            , minOSVersion: nil
    )

    public required override init() {

    }

    static func didConfigure(with manager: AppManager) {

    }

    func didResign(current: App.Type?) {

    }

    func reloadProductItems(){
        (content as? ShopAppDockContent)?.reloadData()
    }

    func indicateProductItem(for payable:Payable.Type, indicating:Bool){
        (content as? ShopAppDockContent)?.indicateCell(for:payable, indicating:indicating)
    }

    var sourceAppType:App.Type?

    fileprivate var launchedOption: AppLaunchOptions?

    func didLaunch(previous: App.Type?, withOption: AppLaunchOptions?) {
        launchedOption = withOption
        sourceAppType = launchedOption?.options?[.ShopAppCallerAppType] as? App.Type
    }

    public private(set) static var fixedContentLayout: Bool = true
}

/*
    Utilities
*/
extension ShopApp{

    //CRITICAL: filtering visibility
    fileprivate func loadDefaultPayGroups() -> [PayGroup] {
        var mutableDefaultCollection = PayGroup.Default

        //INFO: get source app info
        let localOwnedExisted:Bool
        if let sourceChargeableApp = AppCenter.default.currentInstanceAs(ShopApp.self)?.sourceAppType as? ChargeableApp.Type {
            if let localCharges = sourceChargeableApp.localCharges.nilEmpty{
                
                localOwnedExisted = localCharges.contains(where:{ $0.reward.isLocalOwned })

                //POLICY: .LocalCharge is disabled now but it will be separated with "Global" .PaidCharge
                for (i, payGroup) in mutableDefaultCollection.enumerated() where payGroup.key == .PaidCharge{
                    var mutablePayGroup = payGroup
                    var items = payGroup.items
                    items.append(contentsOf:localCharges.map ({
                            let pay = PayItem(payable: $0.payment)
                            pay.rewardIconImageStyle.beRound = true
                            pay.rewardIconImageStyle.useTintColor = false
                            return pay
                        })
                    )
                    mutablePayGroup.items = items
                    mutableDefaultCollection[i] = mutablePayGroup
                    break
                }

                mutableDefaultCollection.sort { dictionary1, dictionary2 in return dictionary1.key.rawValue < dictionary2.key.rawValue }
            }else{
                localOwnedExisted = false
            }

        }else{
            localOwnedExisted = false
        }

        //INFO: Apply dictionary deps
        var removingIndexes = [Int]()
        let paidChargesByPaymentIDs = AppCenter.charge.getChargesPaid().dictionary { $0.payment.identifier }
        let paidPayableIDs = Set(paidChargesByPaymentIDs.keys)

        let paidOwnedExisted = paidChargesByPaymentIDs.values.contains(where:{ $0.reward.isOwned })

        for (i, payGroup) in mutableDefaultCollection.enumerated() {

            var mutablePayDict = payGroup

            //Check invisibility
            mutablePayDict.items = mutablePayDict.items.filter { item -> Bool in
                //Check whether payment has unregistered charge
                guard let charge = item.charge else {
                    return false
                }

                //Check Restore Visibility
                if !item.payable.isEnable{
                    return false
                }

                //POLICY: Check if isOwned has existed, but item is isLocalOwned will be hidden.
                if charge.reward.isLocalOwned {
                    if paidOwnedExisted{
                        return false
                    }
                }

                //POLICY: Check if isLocalOwned has existed, but an item is not isLocalOwned(==free charge reward) will be hidden.
                if charge.reward.isLocalOwned == false && charge.reward.isOwned == false {
                    if localOwnedExisted{
                        return false
                    }
                }

                //Check availability
                if (item.availability.contains(.paid) && item.availability.contains(.unpaid)) == false{
                    let paid = paidPayableIDs.contains(item.payable.identifier)
                    if false == (item.availability.contains(.paid) && paid || item.availability.contains(.unpaid) && !paid){
                        return false
                    }
                }

                //Check super payable
                if let superPayables = (item.payable as? RelativePayable.Type)?.superPayables{
                    if Set(superPayables.map({ $0.element.identifier })).intersection(paidPayableIDs).count > 0{
                        return false
                    }
                }
                
                return true
            }

            if mutablePayDict.items.count == 0{
                //remove if not
                removingIndexes.append(i)
            }else{
                //apply result
                mutableDefaultCollection[i] = mutablePayDict
            }
        }
        
        return mutableDefaultCollection.filter {
            if let index = mutableDefaultCollection.index(of: $0), removingIndexes.contains(index) {
                return false
            }
            return true
        }
    }

    /*
        SKProduct Info fetch
    */
    fileprivate func getStorePayablesNotFetched() -> [StorePayable.Type]{
        return getStorePayables().filter { $0.storeProduct == nil }
    }

    fileprivate func getStorePayables() -> [StorePayable.Type]{
        let targetCollection = loadDefaultPayGroups()

        return targetCollection.compactMap { dictionary -> [StorePayable.Type]? in
            return dictionary.items.compactMap({
                return $0.payable as? StorePayable.Type
            })
        }.reduce([],+)
    }

    fileprivate var currentFetchedProducts:Set<SKProduct> {
        return Set(self.getStorePayables().compactMap({ $0.storeProduct }))
    }

    fileprivate func fetchStoreProductsInfo(completion:((StoreKitPayableCenter.StoreProductFetchResult) -> ())?=nil) {
        let payablesNeedToFetch = self.getStorePayablesNotFetched()

        guard payablesNeedToFetch.count > 0 else {
            //INFO: Already all products are fetched
            completion?((products: currentFetchedProducts, invalidProductIDs:Set<String>()))
            return
        }

        DispatchQueue.global().async{
            let signal = AsyncSignal()

            if let result = StoreKitPayableCenter.fetch(for: payablesNeedToFetch, signal){
                completion?(result)
            }else{
                print("[!] WARNING: \(String(describing: StoreKitPayableCenter.self)) fetching was failed.")
            }
        }
    }
}


private protocol Section{
    var label:String{get}
    var detailedLabel:String?{get}
    var itemsOfSection:[Any]{get}
}

private extension Array where Element== PayGroup {
    func getDictionary(by key: PayGroup.Key) -> PayGroup?{
        return self.first { $0.key == key }
    }
}

private struct PayGroup:Hashable, Equatable, Section {
    enum Key: Int, Codable {
        case SystemOwned
        case PaidCharge
//        case LocalCharge
        case FreeCharge
//        case Promotion
    }

    var isPaidAll:Bool{
        let payables = self.items.map{ $0.payable }
        return payables.count == payables.filter { AppCenter.charge.isPaid(payable: $0) }.count
    }

    static let Default: [PayGroup] = [
        PayGroup(
            key: .SystemOwned
            , label: "Purchase Management".localized
            , items: [
                PayItem(payable:RestorePurchasesSystemPayment.self, availability: [.unpaid])
            ]
        ),

        PayGroup(
                key: .PaidCharge
                , label: "%@ Membership".localizedFormatted(papStrings.name)
                , detailedLabel: "Prices Are Including Every New Apps and Updates.".localized
                , items: [
                    PayItem(payable:AllTimeAllAppsPayment.self)
                    , PayItem(payable:YearlyAllAppsPayment.self)
                    , PayItem(payable:MonthlyAllAppsPayment.self)
                    , PayItem(payable:OneMonthAllAppsPayment.self)
                    , PayItem(payable:SixMonthsAllAppsPayment.self)
                    , PayItem(payable: PermanentVIPProgramPayment.self)
                ]
        )

        , PayGroup(
                key: .FreeCharge
                , label: "Main Apps License".localized
                , detailedLabel: "Engage Now And Repeatedly Recharge Main Apps License.".localized
                , items: [
                    PayItem(payable: WelcomeTutorialPayment.self, availability: [.paid]),
                    PayItem(payable: GADInterestialAdsViewingPayment<GADInterestialTypeBlockOfUses>.self, cellType:.switcher),
//                    PayItem(payable: YouAppProgramPayment.self),
                    PayItem(payable: GADInterestialAdsViewingPayment<GADInterestialTypeTimeOfUses>.self),
                    PayItem(payable: FBShareTypeDownloadUrlPayment.self),
                    PayItem(payable: FBShareTypeDownloadMessagerPayment.self),
                    PayItem(payable: SNSEngagementPayment.self)
                ]
        )
    ]

    let key:Key
    let label:String
    var items:[PayItem]
    var detailedLabel:String?

    var itemsOfSection: [Any] {
        return items
    }

    init(key:Key, label:String, detailedLabel:String?=nil, items:[PayItem]){
        self.key = key
        self.label = label
        self.items = items
        self.detailedLabel = detailedLabel
    }

    var hashValue: Int{
        return key.rawValue
    }

    static func == (lhs: PayGroup, rhs: PayGroup) -> Bool{
        return lhs.hashValue == rhs.hashValue
    }
}

private extension ChargeableImage{
    static func create(for charge:Charge?, tintColor:UIColor, appearance:ChargeableButtonAppearance) -> UIImage{
        let image = ChargeableImage(balance: charge?.priceAmount.value ?? 0, fillMode: .fill, tintColor: tintColor, appearanceDelegate: appearance)
        return image.withAlignmentRectInsets(UIEdgeInsets(top: -6, left: -6, bottom: -6, right: -6))
    }
}

private class PayItem: Hashable, Equatable {
    enum CellType {
        case button
        case switcher
    }

    var cellInfo:(cellClass:UITableViewCell.Type, id:String){
        switch self.cellType{
        case .button:
            return (cellClass:UITableViewButtonCell.self, id:String(describing: self.payable)+String(describing:UITableViewButtonCell.self))
        case .switcher:
            return (cellClass:UITableViewSwitchSubtitleCell.self, id:String(describing: self.payable)+String(describing:UITableViewSwitchSubtitleCell.self))
        }
    }

    struct PayItemImageStyle {
        var useTintColor: Bool = true
        var beRound: Bool = false
    }

    fileprivate struct PayItemAvailability: SequenceOptionSet {
        static let paid = PayItemAvailability(rawValue: 1 << 0)
        static let unpaid = PayItemAvailability(rawValue: 1 << 1)

        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    let availability: PayItemAvailability

    let charge:Charge?

    let payable:Payable.Type

    var chargeIconImage: ImageSourceable? {
        return charge?.describable.iconImage
    }

    func getRewardIconImage(tintColor:UIColor) -> ImageSourceable? {

        let iconImageCache = AppCenter.default.currentInstanceAs(ShopApp.self)?.contentImageCache

        if let charge = self.charge{
            if let image = iconImageCache?.object(forKey: charge.identifier as NSString){
                return image
            }

            //defined image first
            var iconImage: UIImage? = charge.rewardDescribable?.iconImage?.asUIImage

            //default image
            if iconImage == nil{

                if charge.payment is RestorePurchasesSystemPayment.Type{
                    //restore
                    iconImage = ChargeableImage.create(for: charge, tintColor: tintColor, appearance: ChargeableRestoreImageAppearance())

                }else{

                    //default
                    iconImage = ChargeableImage.create(for: charge, tintColor: tintColor, appearance: ChargeButtonAppearance(charge:charge))
                    /*
                    iconImage = ChargeableBadgeIcon.portraitBadgeIcon(badgeImage, title: "\(charge.rewardDescribable?.shortTitle ?? "                         ")", tintColor: tintColor)
                    */
                }
            }

            if let iconImage = iconImage{
                iconImageCache?.setObject(iconImage, forKey: charge.identifier as NSString)
            }
            return iconImage
        }

        return nil
    }

    var chargeIconImageStyle: PayItemImageStyle = PayItemImageStyle()
    var rewardIconImageStyle: PayItemImageStyle = PayItemImageStyle()

    var isIndicating: Bool = false
    let enabled: Bool = true
    let cellType:CellType
    let label:String
    let rewardLabel:String?

    init(payable: Payable.Type, cellType:CellType=CellType.button, availability: PayItemAvailability=[.paid, .unpaid]) {
        self.payable = payable
        self.availability = availability
        self.cellType = cellType
        self.charge = AppCenter.charge.getCharge(for: payable)
        self.label = charge?.describable.title ?? "Undefined Charge"
        self.rewardLabel = charge?.rewardDescribable?.title
    }

    var hashValue: Int {
        return String(describing: self.payable).hashValue
    }

    public static func == (lhs: PayItem, rhs: PayItem) -> Bool{
        return lhs.hashValue == rhs.hashValue
    }

}


private struct CellDescriberGroup: Section{
    fileprivate let label:String
    fileprivate var detailedLabel:String?
    fileprivate var describers:[UITableViewCellDefaultDescribable]

    var itemsOfSection: [Any] {
        return describers
    }
}

private struct CellDescriber {
    fileprivate enum Key:Int {
        case vipHotline
        case displayRemainingLevel
        case displayRemainingPercentage
        case support
        case displayChargeState
        case reviewRatingInApp
        case reviewRatingInAppStore
    }

    fileprivate var key: Key
    fileprivate var label:String
    fileprivate var valueGetter:() -> Any
    fileprivate var valueCollection:Any?
    fileprivate var valueHandler:((Any) -> ())?
    fileprivate var cellDescriber: UITableViewCellDescribable //TODO: integrate all properties
    fileprivate var iconImageName:String?
}


fileprivate class ShopAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource, AppLifecycleManagerAllowingInstanceAccessor{

    // Sections
    private lazy var payGroups:[PayGroup] = PayGroup.Default
    private var contactCellDescribers = [UITableViewCellDefaultDescribable]()
    private var freeChargeSettingsCellDescribers = [UITableViewCellDefaultDescribable]()
    private var informationOfUsetCellDescribers = [UITableViewCellDefaultDescribable]()

    private var sections:[Section] {
        var s:[Section] = payGroups

        if freeChargeSettingsCellDescribers.count > 0{
            let settings = CellDescriberGroup(label: "Settings for Main Apps License".localized, detailedLabel: "It Displays A Ratio of Remaining Free App Access Periods.".localized, describers: freeChargeSettingsCellDescribers)
            s.append(settings)
        }

        if contactCellDescribers.count > 0{
            s.append(CellDescriberGroup(label: "Staying with us".localized, detailedLabel: nil, describers: contactCellDescribers))
        }

        if informationOfUsetCellDescribers.count > 0{
            var info = "Version \(Defaults.shared.latestShortVersion ?? "-")"
#if DEBUG
            info = "Version \(Defaults.shared.latestShortVersion ?? "-") | Build \(Bundle.main.version ?? "-")"
#endif
            s.append(CellDescriberGroup(label: "Information of Use".localized, detailedLabel: info, describers: informationOfUsetCellDescribers))
        }

        return s
    }

    required public override init() {
        super.init()
    }

    lazy var view: UIView = {
        let view = UIView(frame: .zero)
        view.addSubview(tableView)
        tableView.fitConstraints(to: view)
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        return tableView
    }()

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = AppDockContentPreferences.GreatestHeight
        return preferences
    }

    func willSetContentView(_ view: UIView, dock: AppDock) {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 44
        tableView.allowsSelection = false
        tableView.allowsMultipleSelection = false        

        reloadData()
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {

        tableView.performBatchUpdates({}, completion: { b in
            self.scrollToPaidChargeSection()
        })

        loadStoreProductsData(retryCount:5)
    }

    func scrollToPaidChargeSection(){
        //Scroll Top to Purchase Section
        for (i, s) in self.sections.enumerated(){
            if let g = s as? PayGroup, g.key == .PaidCharge{
                tableView.scrollToRow(at: IndexPath(item: 0, section: i), at: .top, animated: false)
                break
            }
        }
    }

    private func loadPayGroups(){
        //INFO: join local charges onto defaultCollection.

        if let loadedCollections = AppCenter.default.currentInstanceAs(ShopApp.self)?.loadDefaultPayGroups(){
            self.payGroups = loadedCollections

        }else{
            assert(false, "[!] ERROR: getDefaultPayDictionaries has not been loaded.")
            self.payGroups = PayGroup.Default
        }

    }

    private func loadShopSettingsCellDescribers(){
        freeChargeSettingsCellDescribers.removeAll()

        if !AppCenter.isPaidAsOwnedInCurrentContext{

            let c3 = UITableViewSwitchSubtitleCellDescriber()
            c3.itemIdentifier = CellDescriber.Key.displayRemainingLevel.hashValue
            c3.label = "Display Remaining Level".localized
            c3.detailedLabel = "Color And Reminder for Each Phases".localized
            c3.iconImageTintColor = ChargeLevel(rawValue: ChargeLevel.low.rawValue)?.representativeColor
            c3.iconImage = ChargeableImage(balance:Double(0.35), tintColor: self.view.tintColor, appearanceDelegate: ChargeButtonAppearance(charge: nil))
            c3.valueGetter = { return Defaults.shared.showChargeButtonLevelColorInNavigationBar }
            c3.valueHandler = { b in
                Defaults.shared.showChargeButtonLevelColorInNavigationBar = (b as? Bool) ?? false
            }
            freeChargeSettingsCellDescribers.append(c3)

            let c4 = UITableViewSwitchSubtitleCellDescriber()
            c4.itemIdentifier = CellDescriber.Key.displayRemainingPercentage.hashValue
            c4.label = "Display Remaining Percentage.".localized
            c4.iconImage = ChargeableBadgeIcon.portraitBadgeIcon(ChargeableImage(balance:0.64, tintColor: self.view.tintColor, appearanceDelegate: ChargeButtonAppearance(charge: nil)), title: String(format: "%d%%", 64), tintColor: self.view.tintColor)
            c4.valueGetter = { return Defaults.shared.showChargeButtonPercentageInNavigationBar }
            c4.valueHandler = { b in
                Defaults.shared.showChargeButtonPercentageInNavigationBar = (b as? Bool) ?? false
            }
            freeChargeSettingsCellDescribers.append(c4)
        }
    }

    private func loadContactCellDescribers(){
        contactCellDescribers.removeAll()

        let c0 = UITableViewButtonCellDescriber()
        c0.itemIdentifier = CellDescriber.Key.reviewRatingInApp.hashValue
        c0.label = "Give A Rating".localized
        c0.buttonTitle = "Rate Now".localized
        c0.iconImage = R.image.cellIconGiveARating.name
        c0.iconImageTintColor = self.view.tintColor
        c0.valueHandler = { _ in
            DispatchQueue.global().async{
                _ = InAppPromptRatingPayment.self.init().pay(AsyncSignal())
            }
        }
        contactCellDescribers.append(c0)

        let c1 = UITableViewButtonCellDescriber()
        c1.itemIdentifier = CellDescriber.Key.reviewRatingInAppStore.hashValue
        c1.label = "Write A Review".localized
        c1.buttonTitle = "Write".localized
        c1.iconImage = R.image.cellIconWriteAReview.name
        c1.iconImageTintColor = self.view.tintColor
        c1.valueHandler = { _ in
            DispatchQueue.global().async{
                _ = InAppStoreRatingPayment.self.init().pay(AsyncSignal())
            }
        }
        contactCellDescribers.append(c1)

        let c123 = UITableViewButtonCellDescriber()
        c123.itemIdentifier = CellDescriber.Key.reviewRatingInAppStore.hashValue
        c123.label = "Share This App".localized
        c123.buttonTitle = "Share".localized
        c123.iconImage = R.image.commonCellIconShare()
        c123.iconImageTintColor = self.view.tintColor
        c123.valueHandler = { _ in
            DispatchQueue.global().async{
                _ = SocialSharePayment.self.init().pay(AsyncSignal())
            }
        }
        contactCellDescribers.append(c123)

        let c2 = UITableViewButtonCellDescriber()
        c2.itemIdentifier = CellDescriber.Key.support.hashValue
        c2.label = "Contact Us Now".localized
        c2.buttonTitle = "Send".localized
        c2.iconImage = R.image.cellIconContactUs.name
        c2.valueHandler = { _ in
            AppCenter.charge.try(for: MailContactPayment<MailContactSupportType>.self)
        }
        contactCellDescribers.append(c2)

        if AppCenter.isPaidAsVIPInCurrentContext {
            let c6 = UITableViewButtonCellDescriber()
            c6.itemIdentifier = CellDescriber.Key.vipHotline.hashValue
            c6.label = "VIP Hotline".localized
            c6.buttonTitle = "Inquiry".localized
            c6.iconImage = R.image.cellIconVIPHotline.name
            c6.iconImageTintColor = self.view.tintColor
            c6.valueHandler = { _ in
                //TODO: add realtime messenger or in-app messaging.
                AppCenter.charge.try(for: MailContactPayment<MailContactHotlineType>.self)
            }
            contactCellDescribers.append(c6)
        }

        let c3 = UITableViewButtonCellDescriber()
        c3.itemIdentifier = CellDescriber.Key.support.hashValue
        c3.label = "User Community".localized
        c3.buttonTitle = "Visit".localized
        c3.iconImage = R.image.cellIconUserGroup.name
        c3.iconImageTintColor = self.view.tintColor
        c3.valueHandler = { _ in
            AppCenter.charge.try(for: URLOpenPayment<URLOpenTypeUserCommunity>.self)
        }
        contactCellDescribers.append(c3)


        let c345 = UITableViewButtonCellDescriber()
        c345.itemIdentifier = CellDescriber.Key.support.hashValue
        c345.label = "%@ Channel".localizedFormatted("Youtube")
        c345.buttonTitle = "Visit".localized
        c345.iconImage = R.image.cellIconYouTubeChannel.name
        c345.iconImageTintColor = self.view.tintColor
        c345.valueHandler = { _ in
            AppCenter.charge.try(for: URLOpenPayment<URLOpenTypeYouTubeChannel>.self)
        }
        contactCellDescribers.append(c345)
    }

    private func loadInformationOfUsetCellDescribers(){
        informationOfUsetCellDescribers.removeAll()


        let c234 = UITableViewButtonCellDescriber()
        c234.itemIdentifier = CellDescriber.Key.support.hashValue
        c234.label = "Reference Guide".localized
        c234.buttonTitle = "See".localized
        c234.iconImage = R.image.cellIconReferenceGuide.name
        c234.iconImageTintColor = self.view.tintColor
        c234.valueHandler = { _ in
            AppCenter.charge.try(for: URLOpenPayment<URLOpenTypeReferenceGuide>.self)
        }
        informationOfUsetCellDescribers.append(c234)

        let c3243 = UITableViewButtonCellDescriber()
        c3243.itemIdentifier = CellDescriber.Key.support.hashValue
        c3243.label = "Engineering Notes".localized
        c3243.buttonTitle = "See".localized
        c3243.iconImage = R.image.cellIconReferenceGuide.name
        c3243.iconImageTintColor = self.view.tintColor
        c3243.valueHandler = { _ in
            AppCenter.charge.try(for: URLOpenPayment<URLOpenTypeEngineeringNotes>.self)
        }
        informationOfUsetCellDescribers.append(c3243)

        let c3 = UITableViewButtonCellDescriber()
        c3.itemIdentifier = CellDescriber.Key.support.hashValue
        c3.label = "Privacy Policy".localized
        c3.buttonTitle = "See".localized
        c3.iconImage = R.image.commonCellIconInfo()
        c3.iconImageTintColor = self.view.tintColor
        c3.valueHandler = { _ in
            AppCenter.charge.try(for: URLOpenPayment<URLOpenTypePrivacyPolicy>.self)
        }
        informationOfUsetCellDescribers.append(c3)

        let c7 = UITableViewButtonCellDescriber()
        c7.itemIdentifier = CellDescriber.Key.support.hashValue
        c7.label = "Terms of Use".localized
        c7.buttonTitle = "See".localized
        c7.iconImage = R.image.commonCellIconInfo()
        c7.iconImageTintColor = self.view.tintColor
        c7.valueHandler = { _ in
            AppCenter.charge.try(for: URLOpenPayment<URLOpenTypeTermsOfUse>.self)
        }
        informationOfUsetCellDescribers.append(c7)
    }

    fileprivate func reloadData(){
        AppCenter.charge.synchronize()

        loadShopSettingsCellDescribers()
        loadContactCellDescribers()
        loadInformationOfUsetCellDescribers()
        loadPayGroups()

        for s in self.sections{
            if let cellGroup = s as? CellDescriberGroup{
                for desc in cellGroup.describers {
                    tableView.register(describer: desc)
                }
            }            
            else if let cellGroup = s as? PayGroup{
                for item in cellGroup.items {
                    tableView.register(item.cellInfo.cellClass, forCellReuseIdentifier: item.cellInfo.id)
                }
            }
        }
        
        tableView.reloadData()
    }

    private func loadStoreProductsData(retryCount:Int=0){
        weak var shopApp = AppCenter.default.currentInstanceAs(ShopApp.self)
        shopApp?.fetchStoreProductsInfo() { [weak self] _ in
            guard let wself = self else{
                return
            }

            //Retry
            if let shopApp = shopApp{
                if shopApp.getStorePayablesNotFetched().count > 0{
                    if retryCount > 0{
                        wself.loadStoreProductsData(retryCount:retryCount-1)
                        print("[!] WARNING: Retried - loadStoreProductsInfo()")
                    }
                }
                DispatchQueue.main.async { wself.reloadData() }
            }
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[safe: section]?.label
    }

    private lazy var footerViews = [String:UIView]()

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let detailedLabel = sections[safe: section]?.detailedLabel else{
            return nil
        }

        let k = detailedLabel
        if footerViews[k] == nil{
            footerViews[k] = UITableView.createHeaderFooterViewForSmallMessage(text: detailedLabel)
            footerViews[k]?.sizeToFit()
        }
        return footerViews[k]
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return self.tableView(tableView, viewForFooterInSection: section)?.height ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[safe: section]?.itemsOfSection.count ?? 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let section = sections[safe: indexPath.section] {

            if section is PayGroup, let item = section.itemsOfSection[indexPath.item] as? PayItem{
                return cellForRow(tableView, cellForRowAt: indexPath, forItem: item)
            }
            else if section is CellDescriberGroup, let item = section.itemsOfSection[indexPath.item] as? UITableViewCellDefaultDescribable{
                return cellForRow(tableView, cellForRowAt: indexPath, forItem:item)
            }
        }

        assert(false, "Section Index \(indexPath.section) was overflowed or undefined section type.")
        return UITableViewCell()
    }

    func pay(item:PayItem, indexPath:IndexPath){
        item.isIndicating = true
        updateIndicatorCellIfNeeded(at: indexPath, with: item)

        AppCenter.charge.pay(for: item.payable) { succeed in
            item.isIndicating = false

            self.updateIndicatorCellIfNeeded(at: indexPath, with: item)

            if succeed, let rid = AppCenter.default.currentInstanceAs(ShopApp.self)?.launchedOption?.identifierToReturn{
                AppCenter.default.openApp(identifier: rid)
            }else{
                self.reloadData()
            }
        }
    }

    func unpay(item:PayItem, indexPath:IndexPath){

        if let charge = item.charge, let r = AppCenter.charge.bank.getReceipt(for: charge){
            ChargeableReceipt.reserveShouldFailVerification(uuid: r.uuid)
            AppCenter.charge.synchronize()
        }
    }

    private func updateIndicatorCellIfNeeded(at indexPath: IndexPath, with item: PayItem) {
        if let cell = tableView.cellForRow(at: indexPath) as? UITableViewIndicatorCell {
            if item.isIndicating {
                cell.isUserInteractionEnabled = false
                cell.startIndicating()
            }
            else {
                cell.isUserInteractionEnabled = true
                cell.stopIndicating()
            }
        }
    }
}

/*
    Payable Macros
*/

extension ShopAppDockContent{
    fileprivate func getPayItem(for payable:Payable.Type) -> (item:PayItem, indexPath:IndexPath)?{
        for (si, section) in sections.enumerated(){
            if section is PayGroup{
                for (ii, item) in section.itemsOfSection.enumerated(){
                    if let pItem = item as? PayItem, pItem.payable.identifier == payable.identifier{
                        return (item:pItem, indexPath:IndexPath(item: ii, section: si))
                    }
                }
            }
        }
        return nil
    }

    fileprivate func indicateCell(for payable:Payable.Type, indicating:Bool){
        guard let o = getPayItem(for:payable) else{
            return
        }

        o.item.isIndicating = indicating
        self.updateIndicatorCellIfNeeded(at:o.indexPath, with:o.item)
    }
}

/*
    Cell Loaders by Group Type
*/
extension ShopAppDockContent {

    private func defaultSetCellAppearanceForRow(cellForRowAt indexPath: IndexPath, describer:UITableViewCellDescriber, cell:UITableViewCell){
        let item = describer

        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.text = item.label

        cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.text = item.detailedLabel

        if let image = item.iconImage?.asUIImage{
            cell.imageView?.image = image.withRenderingMode(.alwaysTemplate)

            if let iconTintColor = item.iconImageTintColor{
                cell.imageView?.tintColor = iconTintColor
            }else{
                cell.imageView?.tintColor = self.view.tintColor
            }
        }
    }

    func cellForRow(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, forItem:UITableViewCellDefaultDescribable) -> UITableViewCell{
        let item = forItem

        if let cellDescriber = item as? UITableViewSwitchCellDescriber
        , let value = item.valueGetter() as? Bool
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSwitchCell {
            defaultSetCellAppearanceForRow(cellForRowAt: indexPath, describer: cellDescriber, cell: cell)

            cell.switcher.setOn(value, animated: false)
            cell.switcher.onTintColor = self.view.tintColor
            cell.switchDidChange = item.valueHandler
            return cell
        }

        else if let cellDescriber = item as? UITableViewButtonCellDescriber
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewButtonCell {
            defaultSetCellAppearanceForRow(cellForRowAt: indexPath, describer: cellDescriber, cell: cell)

            if let buttonTitle = cellDescriber.buttonTitle{
                cell.setButtonTitle(title: buttonTitle, detailTitle: cellDescriber.buttonDetailTitle, for: .normal)
                cell.button.setTitleColor(self.view.tintColor, for: .normal)
            }
            cell.didTap = {
                cellDescriber.valueHandler?("tapped")
            }
            return cell
        }

        else if let cellDescriber = item as? UITableViewStepperCellDescriber
        , let value = item.valueGetter() as? Int
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewStepperCell {
            defaultSetCellAppearanceForRow(cellForRowAt: indexPath, describer: cellDescriber, cell: cell)

            cell.detailTextLabel?.text = cellDescriber.valuePresenter?(value) ?? String(value)

            cell.stepper.stepValue = cellDescriber.stepValue
            cell.stepper.minimumValue = cellDescriber.minimumValue
            cell.stepper.maximumValue = cellDescriber.maximumValue
            cell.stepper.value = Double(value)

            cell.didChangeValue = { value in
                cell.detailTextLabel?.text = cellDescriber.valuePresenter?(value) ?? String(Int(value))
                item.valueHandler?(value)
            }
            return cell
        }


        else if let cellDescriber = item as? UITableViewSegmentControlCellDescriber
        , let valueCollection = cellDescriber.valueCollection as? [(String, Int)]
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSegmentedControlCell{
            defaultSetCellAppearanceForRow(cellForRowAt: indexPath, describer: cellDescriber, cell: cell)

            cell.segmentedControl.removeAllSegments()

            for (label, _) in valueCollection{
                cell.segmentedControl.insertSegment(withTitle: label, at: cell.segmentedControl.numberOfSegments, animated: false)
            }

            cell.segmentedControl.selectedSegmentIndex = valueCollection.index { t in
                t.1 == (item.valueGetter() as! Int)
            } ?? 0

            cell.didChangeValue = item.valueHandler
            return cell
        }

        let defaultCell = tableView.cellForRow(at: indexPath) ?? UITableViewCell()
        defaultCell.textLabel?.text = item.label
        defaultCell.detailTextLabel?.textColor = UIColor.gray

        return defaultCell
    }
}

extension ShopAppDockContent{

    func cellForRow(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, forItem:PayItem) -> UITableViewCell{

        /*
            Common
        */
        let dataItem = forItem

        let cell = tableView.dequeueReusableCell(withIdentifier: forItem.cellInfo.id) as! UITableViewIndicatorCell

        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.text = dataItem.label
        cell.textLabel?.text = dataItem.label

        cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.text = dataItem.rewardLabel
        cell.detailTextLabel?.textColor = UIColor.gray

        // Cell.ImageView: Reward
        cell.imageView?.tintColor = self.view.tintColor

        if dataItem.rewardIconImageStyle.useTintColor {
            cell.imageView?.image = dataItem.getRewardIconImage(tintColor:view.tintColor)?.asUIImage?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        }else{
            cell.imageView?.image = dataItem.getRewardIconImage(tintColor:view.tintColor)?.asUIImage?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        }
        if dataItem.rewardIconImageStyle.beRound, let image = cell.imageView?.image{
            cell.imageView?.image = image.rounded(radius: image.size.height)?.resize(aspectFit: CGSize(width: tableView.rowHeight*image.size.height/image.size.width, height: tableView.rowHeight))
        }

        if dataItem.isIndicating{
            cell.isUserInteractionEnabled = false
            cell.startIndicating()
        }else{
            cell.isUserInteractionEnabled = true
            cell.stopIndicating()
        }

        /*
           Cell Type Specific
        */
        switch forItem.cellType{
            case .button:
                return buttonCellForRow(tableView, cell as! UITableViewButtonCell, cellForRowAt: indexPath, forItem: forItem)
            case .switcher:
                return switcherCellForRow(tableView, cell as! UITableViewSwitchSubtitleCell, cellForRowAt: indexPath, forItem: forItem)
        }
    }

    func switcherCellForRow(_ tableView: UITableView, _ cell:UITableViewSwitchSubtitleCell, cellForRowAt indexPath: IndexPath, forItem:PayItem) -> UITableViewCell{

        cell.switcher.onTintColor = self.view.tintColor

        cell.switcher.isOn = AppCenter.charge.isPaid(payable: forItem.payable)
        cell.switchDidChange = { on in
            if on {
                self.pay(item: forItem, indexPath: indexPath)
            }else{
                self.unpay(item: forItem, indexPath: indexPath)
            }
        }

        return cell
    }

    func buttonCellForRow(_ tableView: UITableView, _ cell:UITableViewButtonCell, cellForRowAt indexPath: IndexPath, forItem:PayItem) -> UITableViewCell{

        let dataItem = forItem

        // Cell.AssessoryView: Charge
        cell.buttonFrameInset = nil
        cell.button.tintColor = self.view.tintColor
        cell.button.setTitleColor(self.view.tintColor, for: .normal)
        cell.button.tintColor = self.view.tintColor

        //1st Image
        if let payingImage = dataItem.chargeIconImage?.asUIImage{
            if dataItem.chargeIconImageStyle.useTintColor {
                cell.button.setImage(payingImage.withRenderingMode(UIImageRenderingMode.alwaysTemplate), for: .normal)
            }else{
                cell.button.setImage(payingImage.withRenderingMode(UIImageRenderingMode.alwaysOriginal), for: .normal)
            }
            if dataItem.chargeIconImageStyle.beRound, let image = cell.button.image(for: .normal){
                cell.imageView?.image = image.rounded(radius: image.size.height)
            }

        }else{

            let action = dataItem.payable.action
            if action.detailedTitle == nil{
                cell.button.setTitle(action.title, for: .normal)
            }else{
                cell.setButtonTitle(title: action.title, detailTitle: action.detailedTitle, for: .normal)
            }

            cell.button.setTitleColor(self.view.tintColor, for: .normal)
        }

        let unpaid = AppCenter.charge.isPaid(payable: dataItem.payable) == false

        if unpaid{
            cell.didTap = { self.pay(item: dataItem, indexPath:indexPath) }
            cell.accessoryType = .none
            cell.accessoryView = cell.button
            cell.enable(true)
        }else{
            cell.didTap = nil
            cell.accessoryView = nil
            cell.accessoryType = .checkmark
            cell.enable(false)
        }

        return cell
    }
}

