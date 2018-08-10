//
// Created by BLACKGENE on 8/8/18.
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
        StorePayableConfigurator.configure()
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


private struct PayDictionary:Hashable {
    static let Default: [PayDictionary] = [
        PayDictionary(
                key: .Purchase
                , label: "%@ Passes".localizedFormatted(papStrings.name)
                , items: [
                    PayForAllTimeAllApps.self

                    , PayForOneMonthAllApps.self
                    , PayForOneYearAllApps.self

                    , PayForMonthlyAllApps.self
                    , PayForYearlyAllApps.self

                ].sorted(by:{ (payType1: Payable.Type, payType2: Payable.Type) -> Bool in
                    return false
                }).map { PayItem(payable:$0) }
        )
        , PayDictionary(
                key: .FreeCharge
                , label: "FreeCharge Methods".localized
                , items: [
                    PayOnFeedback.self
                    , PayOnPromptRating.self
                    , PayOnSocialShare.self
                    , PayInAppStoreRating.self

                ].sorted(by:{ (payType1: Payable.Type, payType2: Payable.Type) -> Bool in
                    return false
                }).map { PayItem(payable:$0) }
        )
    ]

    enum Key: Int, Codable {
        case Purchase
        case FreeCharge
        case Promotion
    }

    fileprivate var key:Key
    fileprivate var label:String
    fileprivate var items:[PayItem]

    var hashValue: Int{
        return key.rawValue
    }
}


private struct PayItem: Hashable, Equatable {
    fileprivate let payable:Payable.Type

    fileprivate func getIconImage(tintColor:UIColor) -> ImageSourceable? {

        let iconImageCache = AppCenter.default.currentInstanceAs(ShopApp.self)?.contentImageCache

        if let charge = AppCenter.charge.getCharge(for: payable){
            if let image = iconImageCache?.object(forKey: charge.identifier as NSString){
                return image
            }

            var iconImage: UIImage?

            if let chargeableAppType = AppCenter.default.currentInstanceAs(ShopApp.self)?.sourceAppType as? ChargeableApp.Type{
                iconImage = chargeableAppType.info.iconBundleName?.asUIImage

            }else{
                iconImage = ChargeableImage(balance: charge.priceAmount.value, fillMode: .fill, tintColor: tintColor, appearanceDelegate: ShopAppChargeableAssets(charge:charge))
                        .withAlignmentRectInsets(UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4))
//            iconImage = ChargeableBadgeIcon.portraitBadgeIcon(badgeImage, title: "\(charge.rewardDescribable?.rewardShortTitle ?? "                         ")", tintColor: tintColor)
            }

            if let iconImage = iconImage{
                iconImageCache?.setObject(iconImage, forKey: charge.identifier as NSString)
            }
            return iconImage
        }

        return nil
    }

    fileprivate var iconImageShouldUseTintColor: Bool
    fileprivate var enabled: Bool = true
    fileprivate let label:String
    fileprivate let rewardLabel:String

    init(payable: Payable.Type) {
        self.payable = payable
        self.label = AppCenter.charge.getCharge(for: payable)?.title ?? "Untitled"
        self.rewardLabel = AppCenter.charge.getCharge(for: payable)?.rewardDescribable?.rewardTitle ?? "Undefined Reward"
        self.iconImageShouldUseTintColor = true
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

private protocol ShopAppDefaults: AppDefaults{
//    var selectedCollection: [PayDictionary] {get set}
    var deletingTarget: Int {get set}
    var saveContactWithoutEdit:Bool {get set}
    var quickActionOnly:Bool {get set}
    var autoSelect:Bool {get set}
}

extension Defaults: ShopAppDefaults {
//    fileprivate var selectedCollection: [PayDictionary] {
//        set{ set(newValue) }
//        get{
//            let defaultCollection = PayDictionary.DefaultCollection
//            let collection = get(or: defaultCollection )
//
//            //diff == 0 return
//            if defaultCollection == collection{
//                return collection
//            }
//
//            //if not -> migrate
//            var migratedCollection = [PayDictionary]()
//            let keyedCollection = collection.dictionary { $0.key }
//
//            var modCount = 0
//            for ddict in defaultCollection {
//                guard let ndict = keyedCollection[ddict.key] else {
//                    migratedCollection.append(ddict)
//                    continue
//                }
//
//                var m_dict = ddict
//                let oPayIds = ddict.itemsChargeIdentifiers
//                let nPayIds = ndict.itemsChargeIdentifiers
//
//                for nPayId in nPayIds{
//                    if let oindex = oPayIds.index(of: nPayId)
//                    , let nindex = nPayIds.index(of: nPayId){
//                        m_dict.items[oindex] = ndict.items[nindex]
//                        modCount += 1
//                    }
//                }
//                migratedCollection.append(m_dict)
//            }
//
//            if modCount > 0{
//                let mSelf = self
//                mSelf.selectedCollection = migratedCollection
//            }
//
//            return migratedCollection
//        }
//    }

    fileprivate var deletingTarget: Int {
        set{ set(newValue); papLog.app.defaults.log(value:newValue) }
        get{ return get(or: DeletingTarget.selected.rawValue ) }
    }

    fileprivate var saveContactWithoutEdit: Bool {
        set{ set(newValue); papLog.app.defaults.log(value:newValue) }
        get{ return get(or: false ) }
    }

    fileprivate var quickActionOnly: Bool {
        set{ set(newValue); papLog.app.defaults.log(value:newValue) }
        get{ return get(or: false ) }
    }

    fileprivate var autoSelect: Bool {
        set{ set(newValue); papLog.app.defaults.log(value:newValue) }
        get{ return get(or: false ) }
    }
}

private struct ShopAppChargeableAssets : ChargeableButtonAppearance{
    let charge:Charge

//    fileprivate lazy var chargeableButton = makeChargeableBarButtonItem()
//
//    func makeChargeableBarButtonItem() -> ChargeableBarButtonItem{
//        let chargeableButton = ChargeableButton(type: .system, appearance: self)
//        chargeableButton.imageView?.contentMode = .scaleAspectFit
//        chargeableButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
//
//        chargeableButton.fillMode = [.fill]
//
//        //TODO: apply true when some restrictful conditions (e.g. finished trial days) to induce for paying
//        chargeableButton.showsColorLevel = false
//        chargeableButton.showsAnimation = false
//        chargeableButton.showsPercentage = false
//
//        chargeableButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
//        chargeableButton.titleEdgeInsets.left = 2
//        chargeableButton.titleEdgeInsets.right = -2
//
//        return ChargeableBarButtonItem(button:chargeableButton)
//    }

    var emptyImage: UIImage? {
        switch charge.reward{
            case .owned, .rented:
                return R.image.systemIconFavoriteLineCharging()
            default:
                return R.image.systemIconFavoriteLine()
        }
    }
    var filledImage: UIImage? {
        return R.image.systemIconFavoriteFill()
    }
}




/*

AppContent

*/

private enum DeletingTarget:Int{
    case selected
    case targeted
}

private enum ShopAppSettingCells {
    case deletingTarget
    case autoSelect
    case saveContactWithoutEdit
    case quickActionOnly
//    case delete
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
    private lazy var tintColor = UIColor(red:0.31, green:0.44, blue:0.84, alpha:1)

    fileprivate var settingCellDescribers = [UITableViewCellDefaultDescribable]()

    private var defaultCollections:[PayDictionary] {
        var defaultCollection = PayDictionary.Default

        if let appType = AppCenter.default.currentInstanceAs(ShopApp.self)?.sourceAppType as? ChargeableApp.Type{
            if let _ = (appType.getInstance(user: ShopAppDockContent.self) as? ChargeableApp)?.chargesRequired?.contains(where: { c -> Bool in
                return c.isEqualTo(other: AppCenter.defaultPaidAppChargeable)
            }){
                if let purchaseDir = defaultCollection.first (where:{ dictionary in
                    return dictionary.key == .Purchase
                }){
                    var _purchaseDir = purchaseDir
                    _purchaseDir.items.insert(PayItem(payable: AppCenter.defaultPaidAppChargeable.payment), at: 0)
                    defaultCollection[0] = _purchaseDir
                }
            }
        }
        return defaultCollection
    }

    required public override init() {
        super.init()
    }

    lazy var view: UIView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tintColor = tintColor
        return tableView
    }()

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = AppDockContentPreferences.GreatestHeight
        return preferences
    }

    private func createCellDescriber_SelectionPreset_contact_saveContactWithoutEdit() -> UITableViewSwitchCellDescriber{
        let celld = UITableViewSwitchCellDescriber()
        celld.itemIdentifier = ShopAppSettingCells.saveContactWithoutEdit.hashValue
        celld.label = "Save Contacts".localized
        celld.valueGetter = { ShopApp.privateDefaults.saveContactWithoutEdit }
        celld.valueHandler = {
            var defaults = ShopApp.privateDefaults
            defaults.saveContactWithoutEdit = $0 as! Bool
        }
        return celld
    }

    private func createCellDescriber_SelectionPreset_action_quickActionsOnly() -> UITableViewSwitchCellDescriber{
        let celld = UITableViewSwitchCellDescriber()
        celld.itemIdentifier = ShopAppSettingCells.quickActionOnly.hashValue
        celld.label = "Enable Quick Actions".localized
        celld.valueGetter = { ShopApp.privateDefaults.quickActionOnly }
        celld.valueHandler = {
            var defaults = ShopApp.privateDefaults
            defaults.quickActionOnly = $0 as! Bool
        }
        return celld
    }

//    private var isActivatedAtLeastOne:Bool{
//        return self.defaultCollections.compactMap { dictionary -> PayDictionary? in
//            return dictionary.items.compactMap { $0.enabled ? $0 : nil }.count > 0 ? dictionary : nil
//        }.count > 0
//    }

    func willSetContentView(_ view: UIView, dock: AppDock) {

        if settingCellDescribers.count>0{
            return
        }

        let cell1 = UITableViewSwitchSubtitleCellDescriber()
        cell1.itemIdentifier = ShopAppSettingCells.autoSelect.hashValue
        cell1.label = "Auto Selection Bot".localized
        cell1.iconImage = R.image.commonIconRobot.name
        cell1.valueGetter = { ShopApp.privateDefaults.autoSelect }
        cell1.valueHandler = { val in


        }
//        settingCellDescribers.append(cell1)

        let cell0 = UITableViewSegmentControlCellDescriber()
        cell0.itemIdentifier = ShopAppSettingCells.deletingTarget.hashValue
        cell0.label = "Deleting Targets".localized
        cell0.valueGetter = { ShopApp.privateDefaults.deletingTarget
        }
        cell0.valueCollection = [
            (label:"Selected".localized,value: DeletingTarget.selected.rawValue),
            (label:"Targeted".localized,value: DeletingTarget.targeted.rawValue)
        ]
        cell0.valueHandler = {
            let preset = $0 as! Int

            var defaults = ShopApp.privateDefaults
            defaults.deletingTarget = preset

            // selectionPreset changed -> other self.parserCollection getter will be returned.
            (view as? UITableView)?.reloadData()


//            [
//                ShopAppSettingCells.saveContactWithoutEdit.hashValue
//                , ShopAppSettingCells.quickActionOnly.hashValue
//            ].forEach { hashValue in
//
//                if let index = self.settingCellDescribers.index(where:{ describable in
//                    return describable.itemIdentifier == hashValue
//                }){
//                    self.settingCellDescribers.remove(at: index)
//                }
//            }

            //saveContactWithoutEdit
//            if preset == DeletingTarget.matched.rawValue{
//                self.settingCellDescribers.append(self.createCellDescriber_SelectionPreset_contact_saveContactWithoutEdit())
//            }
//
//            if preset == DeletingTarget.selected.rawValue{
//                self.settingCellDescribers.append(self.createCellDescriber_SelectionPreset_action_quickActionsOnly())
//            }

            (view as? UITableView)?.reloadData()

            // autoSelect turn off and restore
//            cell1.valueHandler?(false)

        }
//        settingCellDescribers.append(cell0)

        //auto save
        if ShopApp.privateDefaults.deletingTarget == DeletingTarget.targeted.rawValue{
//            settingCellDescribers.append(createCellDescriber_SelectionPreset_contact_saveContactWithoutEdit())
        }
        else if ShopApp.privateDefaults.deletingTarget == DeletingTarget.selected.rawValue{
//            settingCellDescribers.append(createCellDescriber_SelectionPreset_action_quickActionsOnly())
        }

        if let tableView = view as? UITableView{
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = 44
            tableView.allowsSelection = false
            tableView.allowsMultipleSelection = false
            tableView.register(UITableViewButtonCell.self, forCellReuseIdentifier: ShopApp.info.identifier)

            for desc in settingCellDescribers {
                tableView.register(describer: desc)
            }
        }
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {

        (view as? UITableView)?.reloadData()

    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }

    func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {

    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + defaultCollections.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        let label_section0 = "Settings".localized
        return section < defaultCollections.count ? defaultCollections[section].label : label_section0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section < defaultCollections.count ? defaultCollections[section].items.count : settingCellDescribers.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = indexPath.section < defaultCollections.count
                ? itemCollection_tableView(tableView, cellForRowAt: IndexPath(item: indexPath.item, section: indexPath.section))
                : settings_tableView(tableView, cellForRowAt: indexPath)
        return cell
    }

    func settings_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

    func itemCollection_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let dictIndex = indexPath.section
        let dict = defaultCollections[dictIndex]

        let dataItem = dict.items[indexPath.item]
//        let selected = dataItem.enabled

        let cell = tableView.dequeueReusableCell(withIdentifier: ShopApp.info.identifier) as! UITableViewButtonCell
        cell.buttonFrameInset = nil
        cell.textLabel?.text = dataItem.label
        cell.detailTextLabel?.text = dataItem.rewardLabel
        cell.detailTextLabel?.textColor = UIColor.gray

        cell.imageView?.tintColor = self.view.tintColor
        let image = dataItem.getIconImage(tintColor:view.tintColor)

        if dataItem.iconImageShouldUseTintColor{
            cell.imageView?.image = image?.asUIImage?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        }else{
            cell.imageView?.image = image?.asUIImage?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        }

        //TODO: display already paid
        cell.enable(!AppCenter.charge.isPaid(payable: dataItem.payable))
        cell.button.setImage(cell.imageView?.image, for: .normal)
//        cell.button.setTitle(dataItem.payable.payingLabel, for: .normal)
//        cell.button.setTitleColor(self.view.tintColor, for: .normal)
        cell.didTap = {
            self.didTapPayButton(item: dataItem)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
        return cell
    }

    func didTapPayButton(item:PayItem){
        AppCenter.charge.pay(for: item.payable) { succeed in

            if succeed, let rid = AppCenter.default.currentInstanceAs(ShopApp.self)?.launchedOption?.identifierToReturn{
                DispatchQueue.main.async{
                    AppCenter.default.openApp(identifier: rid)
                }
            }
        }
    }
}


extension ShopAppDockContent: PreheatableAppSubscribable{
    func prepareStatusDisplaying(label:String?){
        var desc = self.settingCellDescribers.first { describable in
            describable.itemIdentifier == ShopAppSettingCells.autoSelect.hashValue
        }
        desc?.detailedLabel = label
    }

    func didStartPreheating() {
        prepareStatusDisplaying(label: "Activating Current Visible Items ...".localized)
        self.startSelectionBotIconAnimation(self.settingCellDescribers, ShopAppSettingCells.autoSelect.hashValue)
    }

    func didStopPreheating() {
        prepareStatusDisplaying(label: ShopApp.privateDefaults.autoSelect ? "On Standby".localized : nil)
        self.stopSelectionBotIconAnimation(self.settingCellDescribers, ShopAppSettingCells.autoSelect.hashValue)
    }
}
