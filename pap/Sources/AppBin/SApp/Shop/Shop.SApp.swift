//
// Crea?ted by B?LACKGENE on 8/8/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import FirebaseMLVision
import DefaultsKit
import Contacts
import ContactsUI
import EventKit
import EventKitUI
import UIKit
import SafariServices
import StoreKit

public class ShopApp: NSObject
        , KeyPathWatchable
        , SApp
        , AppDockApp
        , LaunchableApp
        , ManagerConfigurableApp {

    fileprivate static var privateDefaults = ShopApp.defaults as! ShopAppDefaults
    
    public private(set) lazy var content: AppDockContent? = ShopAppDockContent()

    fileprivate lazy var contentImageCache:NSCache = NSCache<NSString, UIImage>()

    public static let info = AppInfo(
            identifier: "com.stells.pap.shop"
            , version: "1.0"
            , phase: .release
            , appType: ShopApp.self
            , displayName: "Shop".localized
            , description: nil
            , keywords: nil
            , iconBundleName: nil
            , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: .default)
            , minOSVersion: nil
    )

    public required override init() {

    }

    static func didConfigure(with manager: AppManager) {
        StorePayableCenter.configure()
    }

    func didResign(current: App.Type?) {

    }

    fileprivate var launchedOption: AppLaunchOptions?
    func didLaunch(previous: App.Type?, withOption: AppLaunchOptions?) {
        launchedOption = withOption
    }

    var sourceAppType:App.Type?{
        return self.launchedOption?.options?[.SourceAppType] as? App.Type
    }
    
    public private(set) static var fixedContentLayout: Bool = true
}

/*
    Utilities
*/
extension ShopApp{

    //INFO: Important section - Creating final list for gloabal use.
    fileprivate func loadDefaultPayDictionaries() -> [PayDictionary] {
        var mutableDefaultCollection = PayDictionary.Default

        //INFO: get source app info
        if let sourceChargeableApp = AppCenter.default.currentInstanceAs(ShopApp.self)?.sourceAppType as? ChargeableApp.Type {
            if let localCharges = sourceChargeableApp.localCharges.nilEmpty{
                    mutableDefaultCollection.append(PayDictionary(
                            key: .LocalPaidCharge
                            , label: "%@ App Passes".localizedFormatted(sourceChargeableApp.info.displayName)
                            , items: localCharges.map ({
                        let pay = PayItem(payable: $0.payment)
                        pay.rewardIconImageStyle.beRound = true
                        pay.rewardIconImageStyle.useTintColor = false
                        return pay
                    })
                ))
                mutableDefaultCollection.sort { dictionary1, dictionary2 in return dictionary1.key.rawValue < dictionary2.key.rawValue }
            }
        }

        //INFO: Apply dictionary deps
        var removingIndexes = [Int]()
        let paidChargesByPaymentIDs = AppCenter.charge.getChargesPaid(synchronize: true).dictionary { $0.payment.identifier }
        let paidPayableIDs = Set(paidChargesByPaymentIDs.keys)

        let paidStorePayableHasExisted = AppCenter.charge.getChargesPaidByStorePayable().count > 0
        let paidOwnedHasExisted = paidChargesByPaymentIDs.values.contains(where:{ $0.reward.isOwned })
        
        for (i, payDict) in mutableDefaultCollection.enumerated() {

            var mutablePayDict = payDict

            //Check invisibility
            mutablePayDict.items = mutablePayDict.items.filter { item -> Bool in

                //Check Restore Visibility
                if item.payable is RestorePurchasesSystemPayment.Type && paidStorePayableHasExisted{
                    return false
                }

                //Check if isOwned has existed, isLocalOwned will be hidden.
                if let charge = item.charge, charge.reward.isLocalOwned, paidOwnedHasExisted {
                    return false
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
                    if Set(superPayables.map({ $0.type.identifier })).intersection(paidPayableIDs).count > 0{
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
            if let index = mutableDefaultCollection.firstIndex(of: $0), let _ = removingIndexes.firstIndex(of: index) {
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
        let targetCollection = loadDefaultPayDictionaries()

        return targetCollection.compactMap { dictionary -> [StorePayable.Type]? in
            return dictionary.items.compactMap({
                return $0.payable as? StorePayable.Type
            })
        }.reduce([],+)
    }

    fileprivate var currentFetchedProducts:Set<SKProduct> {
        return Set(self.getStorePayables().compactMap({ $0.storeProduct }))
    }

    fileprivate func fetchStoreProductsInfo(completion:((StorePayableCenter.StoreProductFetchResult) -> ())?=nil) {
        let payablesNeedToFetch = self.getStorePayablesNotFetched()

        guard payablesNeedToFetch.count > 0 else {
            //INFO: Already all products are fetched
            completion?((products: currentFetchedProducts, invalidProductIDs:Set<String>()))
            return
        }

        DispatchQueue.global().async{
            let signal = AsyncSignal()

            if let result = StorePayableCenter.fetch(for: payablesNeedToFetch, signal){
                completion?(result)
            }else{
                print("[!] WARNING: \(String(describing: StorePayableCenter.self)) fetching was failed.")
            }
        }
    }
}


private struct PriceString:Codable{
    let title:String
    let detailedTitle:String?
}

private protocol ShopAppDefaults: AppDefaults{
    var storablePayablePriceInfo:[String: PriceString] {get set}
}

extension Defaults: ShopAppDefaults {
    fileprivate var storablePayablePriceInfo: [String: PriceString] {
        set{ set(newValue) }
        get{ return get(or:[String: PriceString]()) }
    }
}


private extension Array where Element==PayDictionary{
    func getDictionary(by key:PayDictionary.Key) -> PayDictionary?{
        return self.first { $0.key == key }
    }
}

private struct PayDictionary:Hashable, Equatable {
    enum Key: Int, Codable {
        case SystemOwned
        case PaidCharge
        case LocalPaidCharge
        case FreeCharge
        case Promotion
    }

    var isPaidAll:Bool{
        let payables = self.items.map{ $0.payable }
        return payables.count == payables.filter { AppCenter.charge.isPaid(payable: $0) }.count
    }

    static let Default: [PayDictionary] = [
        PayDictionary(
            key: .SystemOwned
            , label: "Settings".localized
            , items: [
                PayItem(payable:RestorePurchasesSystemPayment.self, availability: [.unpaid])
            ]
        ),
        PayDictionary(
                key: .PaidCharge
                , label: "%@ Passes".localizedFormatted(papStrings.name)
                , items: [
                    PayItem(payable:AllTimeAllAppsPayment.self)
                    , PayItem(payable:MonthlyAllAppsPayment.self)
                    , PayItem(payable:AnnualAllAppsPayment.self)
                    , PayItem(payable:OneMonthAllAppsPayment.self)
                    , PayItem(payable:OneYearAllAppsPayment.self)
                ]
        )

        , PayDictionary(
                key: .Promotion
                , label: "Event Passes".localized
                , items: [
                PayItem(payable:PayOfInitialTutorial.self, availability: [.paid])
            ]
        )

        , PayDictionary(
                key: .FreeCharge
                , label: "FreeCharge Passes".localized
                , items: [
                    PayItem(payable:PayOnFeedback.self)
                    , PayItem(payable:PayOnPromptRating.self)
                    , PayItem(payable:PayOnSocialShare.self)
                    , PayItem(payable:PayInAppStoreRating.self)

                ]
        )
    ]

    let key:Key
    let label:String
    var items:[PayItem]

    init(key:Key, label:String, items:[PayItem]){
        self.key = key
        self.label = label
        self.items = items
    }

    var hashValue: Int{
        return key.rawValue
    }

    static func == (lhs: PayDictionary, rhs: PayDictionary) -> Bool{
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
    let label:String
    let rewardLabel:String?

    init(payable: Payable.Type, availability: PayItemAvailability=[.paid, .unpaid]) {
        self.payable = payable
        self.availability = availability
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

/*

AppContent

*/

private enum ShopAppSettingCells {

}

private struct SettingsItem {
    fileprivate var key: ShopAppSettingCells
    fileprivate var label:String
    fileprivate var valueGetter:() -> Any
    fileprivate var valueCollection:Any?
    fileprivate var valueHandler:((Any) -> ())?
    fileprivate var cellDescriber: UITableViewCellDescribable //TODO: integrate all properties
    fileprivate var iconImageName:String?
}

fileprivate class ShopAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource, AppLifecycleManagerAllowingInstanceAccessor{
    fileprivate var settingCellDescribers = [UITableViewCellDefaultDescribable]()

    private lazy var payDictionaries:[PayDictionary] = PayDictionary.Default

    private func loadPayDictionaries(){
        //INFO: join local charges onto defaultCollection.

        if let loadedCollections = AppCenter.default.currentInstanceAs(ShopApp.self)?.loadDefaultPayDictionaries(){
            self.payDictionaries = loadedCollections

        }else{
            assert(false, "[!] ERROR: getDefaultPayDictionaries has not been loaded.")
            self.payDictionaries = PayDictionary.Default
        }

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

        if settingCellDescribers.count>0{
            return
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 44
        tableView.allowsSelection = false
        tableView.allowsMultipleSelection = false
        tableView.register(UITableViewButtonCell.self, forCellReuseIdentifier: ShopApp.info.identifier)
        
        for desc in settingCellDescribers {
            tableView.register(describer: desc)
        }
        reloadData()
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {
        loadStoreProductsData(retryCount:5)
    }

    private func reloadData(){
        loadPayDictionaries()
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
        return payDictionaries.count + (settingCellDescribers.count > 0 ? 1 : 0)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section < payDictionaries.count ? payDictionaries[section].label : (settingCellDescribers.count > 0 ? "Settings".localized : nil)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section < payDictionaries.count ? payDictionaries[section].items.count : settingCellDescribers.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = indexPath.section < payDictionaries.count
                ? cellPayableDictionary(tableView, cellForRowAt: indexPath)
                : cellSettingCellDescribers(tableView, cellForRowAt: indexPath)
        return cell
    }

    func cellSettingCellDescribers(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.settingCellDescribers[indexPath.item]

        if let cellDescriber = item as? UITableViewSwitchCellDescriber
        , let value = item.valueGetter() as? Bool
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSwitchCell {

            cell.textLabel?.text = item.label
            cell.detailTextLabel?.text = item.detailedLabel
            cell.switcher.setOn(value, animated: false)
            cell.switcher.onTintColor = self.view.tintColor
            if let image = item.iconImage?.asUIImage{
                cell.imageView?.image = image.withRenderingMode(.alwaysTemplate)
                cell.imageView?.tintColor = self.view.tintColor
            }
            cell.switchDidChange = item.valueHandler
            return cell
        }

        else if let cellDescriber = item as? UITableViewButtonCellDescriber
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewButtonCell {

            cell.textLabel?.text = item.label
            cell.detailTextLabel?.text = cellDescriber.detailedLabel
            cell.imageView?.image = item.iconImage?.asUIImage
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

            cell.textLabel?.text = item.label
            cell.detailTextLabel?.text = cellDescriber.valuePresenter?(value) ?? String(value)
            cell.imageView?.image = item.iconImage?.asUIImage

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

            cell.textLabel?.text = item.label
            cell.imageView?.image = item.iconImage?.asUIImage

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

        let cell = tableView.cellForRow(at: indexPath) ?? UITableViewCell()
        cell.textLabel?.text = item.label
        return cell
    }

    func cellPayableDictionary(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let dictIndex = indexPath.section
        let dict = payDictionaries[dictIndex]
        let dataItem = dict.items[indexPath.item]
//        let selected = dataItem.enabled

        let cell = tableView.dequeueReusableCell(withIdentifier: ShopApp.info.identifier) as! UITableViewButtonCell
        cell.buttonFrameInset = nil
        cell.button.tintColor = self.view.tintColor
        cell.button.setTitleColor(self.view.tintColor, for: .normal)
        cell.textLabel?.text = dataItem.label
        cell.textLabel?.text = dataItem.label
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


        // Cell.AssessoryView: Charge
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
            // 2nd - label
            if let storePayable = dataItem.payable as? StorePayable.Type
            , let priceString = cellGetPriceString(storePayable: storePayable) {

                if priceString.detailedTitle == nil{
                    cell.button.setTitle(priceString.title, for: .normal)
                }else{
                    cell.setButtonTitle(title: priceString.title, detailTitle: priceString.detailedTitle, for: .normal)
                }

            }else{
                cell.button.setTitle(dataItem.payable.label, for: .normal)
            }

            cell.button.setTitleColor(self.view.tintColor, for: .normal)
        }

        let unpaid = AppCenter.charge.isPaid(payable: dataItem.payable) == false

        if dataItem.isIndicating{
            cell.isUserInteractionEnabled = false
            cell.startIndicating()
        }else{
            cell.isUserInteractionEnabled = true
            cell.stopIndicating()
        }

        if unpaid{
            cell.didTap = { self.didTapPayButton(item: dataItem, indexPath:indexPath) }
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

    private func cellGetPriceString(storePayable:StorePayable.Type) -> PriceString?{

        var str:PriceString?

        if let storeProduct = storePayable.storeProduct {
            let priceString = storeProduct.localizedPrice ?? String(describing: storeProduct.price)

            //INFO: Per Day Display
            if let subscriptionPeriod = storePayable.product.subscriptionPeriod{
                let priceValue = storeProduct.price.doubleValue
                let unitAmount = Double(subscriptionPeriod.numberOfUnits)
                let perDayPriceValue:Double
                switch subscriptionPeriod.unit {
                case .day:
                    perDayPriceValue = priceValue/unitAmount
                case .week:
                    perDayPriceValue = priceValue/(7*unitAmount)
                case .month:
                    perDayPriceValue = priceValue/(30.436875*unitAmount)
                case .year:
                    perDayPriceValue = priceValue/(365*unitAmount)
                }

                if let pricePerDayString = SKProduct.localizePrice(price: NSDecimalNumber(value: perDayPriceValue.round(toPlaces: 2)), locale: storeProduct.priceLocale){
                    str = PriceString(title: priceString, detailedTitle: "%@ / Day".localizedFormatted(pricePerDayString))
                }

            }else{
                str = PriceString(title: priceString, detailedTitle: nil)
            }
        }

        if let str = str {
            ShopApp.privateDefaults.storablePayablePriceInfo[storePayable.product.identifier] = str
        }

        return str ?? ShopApp.privateDefaults.storablePayablePriceInfo[storePayable.product.identifier]
    }

    func didTapPayButton(item:PayItem, indexPath:IndexPath){
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
    
    private func updateIndicatorCellIfNeeded(at indexPath: IndexPath, with item: PayItem) {
        if let cell = tableView.cellForRow(at: indexPath) as? UITableViewIndicatorCell {
            if item.isIndicating {
                cell.startIndicating()
            }
            else {
                cell.stopIndicating()
            }
        }
    }
}
