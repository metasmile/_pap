//
//  SettingsSApp.swift
//  batch
//
//  Created by HYOJIN MO on 08/11/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import UIKit

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


public class SettingsApp: NSObject
    , PropertyWatchable
    , SApp
    , AppDockApp
    , LaunchableApp
    , ManagerConfigurableApp {
    
    public private(set) lazy var content: AppDockContent? = SettingsAppDockContent()
    
    fileprivate lazy var contentImageCache:NSCache = NSCache<NSString, UIImage>()
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.settings"
        , version: "1.0"
        , phase: .develop
        , appType: SettingsApp.self
        , displayName: "Settings".localized
        , description: nil
        , keywords: nil
        , iconBundleName: R.image.shopSAppIcon.name
        , themeColor: UIColor(red:1, green:0.99, blue:0.22, alpha:1), policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: .default)
        , minOSVersion: nil
    )
    
    public required override init() {
        
    }
    
    static func didConfigure(with manager: AppManager) {
        
    }
    
    func didResign(current: App.Type?) {
        
    }
    
    var sourceAppType:App.Type?
    
    fileprivate var launchedOption: AppLaunchOptions?
    
    func didLaunch(previous: App.Type?, withOption: AppLaunchOptions?) {
        launchedOption = withOption
        sourceAppType = launchedOption?.options?[.ShopCallerAppType] as? App.Type
    }
    
    public private(set) static var fixedContentLayout: Bool = true
}

private protocol Section{
    var label:String{get}
    var detailedLabel:String?{get}
    var itemsOfSection:[Any]{get}
}

private extension ChargeableImage{
    static var estimatedMaxSizeLength:CGFloat{
        return 32
    }
    
    static func create(for charge:Charge?, tintColor:UIColor, appearance:ChargeableButtonAppearance) -> UIImage{
        let image = ChargeableImage(balance: charge?.priceAmount.value ?? 0, fillMode: .fill, tintColor: tintColor, appearanceDelegate: appearance)
        return image.withAlignmentRectInsets(UIEdgeInsets(top: -6, left: -6, bottom: -6, right: -6))
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


fileprivate class SettingsAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource, AppLifecycleManagerAllowingInstanceAccessor{
    
    // Sections
    private var contactCellDescribers = [UITableViewCellDefaultDescribable]()
    private var freeChargeSettingsCellDescribers = [UITableViewCellDefaultDescribable]()
    private var youAppCellDescribers = [UITableViewCellDefaultDescribable]()
    private var informationOfUsetCellDescribers = [UITableViewCellDefaultDescribable]()
    
    private var sections:[Section] {
        var s:[Section] = [Section]()
        
        if youAppCellDescribers.count > 0{
            s.append(CellDescriberGroup(label: "Join In Partnership Program".localized, detailedLabel: "Share Your Talent, Make Together. Obtain Each Reward If Adopted.".localized, describers: youAppCellDescribers))
        }
        
        if contactCellDescribers.count > 0{
            s.append(CellDescriberGroup(label: "Staying With Us".localized, detailedLabel: nil, describers: contactCellDescribers))
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
        view.tintColor = view.colorTheme.tintColor
        view.addSubview(tableView)
        tableView.tintColor = view.tintColor
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
        tableView.rowHeight = 46
        tableView.allowsSelection = false
        tableView.allowsMultipleSelection = false
        
        reloadData()
    }
    
    func didSetContentView(_ view:UIView, dock:AppDock) {
        
    }
    
    private func loadShopSettingsCellDescribers(){
        freeChargeSettingsCellDescribers.removeAll()
        
        if !AppCenter.isPaidAsOwnedInCurrentContext{
            
            let c3 = UITableViewSwitchSubtitleCellDescriber()
            c3.label = "Remaining Level".localized
            c3.detailedLabel = "Color And Reminder for Each Phases".localized
            c3.iconImageTintColor = ChargeLevel(rawValue: ChargeLevel.low.rawValue)?.representativeColor
            c3.iconImage = ChargeableImage(balance:Double(0.35), tintColor: self.view.tintColor, appearanceDelegate: ChargeButtonAppearance(charge: nil))
            c3.valueGetter = { return Defaults.shared.showChargeButtonLevelColorInNavigationBar }
            c3.valueHandler = { b in
                Defaults.shared.showChargeButtonLevelColorInNavigationBar = (b as? Bool) ?? false
            }
            freeChargeSettingsCellDescribers.append(c3)
            
            let c4 = UITableViewSwitchSubtitleCellDescriber()
            c4.label = "Remaining Percentage".localized
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
        c0.label = "Give A Rating".localized
        c0.buttonTitle = "Rate It".localized
        c0.iconImage = R.image.cellIconGiveARating()//?.crop(aspectFillInset: CGPoint(x: 6, y: 0))
        c0.iconImageTintColor = self.view.tintColor
        c0.valueHandler = { _ in
            DispatchQueue.global().async{
                _ = InAppPromptRatingPayment.self.init().pay(AsyncSignal())
            }
        }
        contactCellDescribers.append(c0)
        
        let c1 = UITableViewButtonCellDescriber()
        c1.label = "Write A Review".localized
        c1.buttonTitle = "Write".localized
        c1.iconImage = R.image.cellIconWriteAReview()//?.crop(aspectFillInset: CGPoint(x: 6, y: 0))
        c1.iconImageTintColor = self.view.tintColor
        c1.valueHandler = { _ in
            DispatchQueue.global().async{
                _ = InAppStoreRatingPayment.self.init().pay(AsyncSignal())
            }
        }
        contactCellDescribers.append(c1)
        
        let c123 = UITableViewButtonCellDescriber()
        c123.label = "Share This App".localized
        c123.buttonTitle = "Share".localized
        c123.iconImage = R.image.commonCellIconShare()//?.crop(aspectFillInset: CGPoint(x: 6, y: 0))
        c123.iconImageTintColor = self.view.tintColor
        c123.valueHandler = { _ in
            DispatchQueue.global().async{
                _ = SocialSharePayment.self.init().pay(AsyncSignal())
            }
        }
        contactCellDescribers.append(c123)
        
        let c2 = UITableViewButtonCellDescriber()
        c2.label = "Message To Us".localized
        c2.buttonTitle = "Send".localized
        c2.iconImage = R.image.cellIconContactUs()//?.crop(aspectFillInset: CGPoint(x: 6, y: 0))
        c2.valueHandler = { _ in
            AppCenter.charge.try(for: MailContactPayment<MailContactSupportType>.self)
        }
        contactCellDescribers.append(c2)
        
        if AppCenter.isPaidAsVIPInCurrentContext {
            let c6 = UITableViewButtonCellDescriber()
            c6.label = "VIP Hotline".localized
            c6.buttonTitle = "Inquiry".localized
            c6.iconImage = R.image.cellIconVIPHotline()//?.crop(aspectFillInset: CGPoint(x: 6, y: 0))
            c6.iconImageTintColor = self.view.tintColor
            c6.valueHandler = { _ in
                //TODO: add realtime messenger or in-app messaging.
                AppCenter.charge.try(for: MailContactPayment<MailContactHotlineType>.self)
            }
            contactCellDescribers.append(c6)
        }
        
        //open later.
        let c3 = UITableViewButtonCellDescriber()
        c3.label = "User Community".localized
        c3.buttonTitle = "Visit".localized
        c3.iconImage = R.image.cellIconUserGroup.name
        c3.iconImageTintColor = self.view.tintColor
        c3.valueHandler = { _ in
            AppCenter.charge.try(for: URLOpenPayment<URLOpenTypeUserCommunity>.self)
        }
        contactCellDescribers.append(c3)
        
        let c322 = UITableViewButtonCellDescriber()
        c322.label = "Stories of Ours".localized
        c322.buttonTitle = "Visit".localized
        c322.iconImage = R.image.cellIconReferenceGuide()//?.crop(aspectFillInset: CGPoint(x: 6, y: 0))
        c322.iconImageTintColor = self.view.tintColor
        c322.valueHandler = { _ in
            AppCenter.charge.try(for: URLOpenPayment<URLOpenTypeBlog>.self)
        }
        contactCellDescribers.append(c322)
        
    }
    
    private func loadInformationOfUsetCellDescribers(){
        informationOfUsetCellDescribers.removeAll()
        
        //        let c42343 = UITableViewButtonCellDescriber()
        //        c42343.label = "Batch Tools List"
        //        c42343.buttonTitle = "Open".localized
        //        c42343.iconImage = R.image.cellIconAppsIndex()//?.crop(aspectFillInset: CGPoint(x: 6, y: 0))
        //        c42343.iconImageTintColor = self.view.tintColor
        //        c42343.valueHandler = { _ in
        //            AppCenter.charge.try(for: URLOpenPayment<URLOpenTypeAppsIndex>.self)
        //        }
        //        informationOfUsetCellDescribers.append(c42343)
        
        let c345 = UITableViewButtonCellDescriber()
        c345.label = "Video Tutorials".localized
        c345.buttonTitle = "Open".localized
        c345.iconImage = R.image.cellIconYouTubeChannel()//?.crop(aspectFillInset: CGPoint(x: 6, y: 0))
        c345.iconImageTintColor = self.view.tintColor
        c345.valueHandler = { _ in
            AppCenter.charge.try(for: URLOpenPayment<URLOpenTypeVideoTutorials>.self)
        }
        informationOfUsetCellDescribers.append(c345)
        
        let c234 = UITableViewButtonCellDescriber()
        c234.label = "Usage Guide".localized
        c234.buttonTitle = "Open".localized
        c234.iconImage = R.image.cellIconReferenceGuide()//?.crop(aspectFillInset: CGPoint(x: 6, y: 0))
        c234.iconImageTintColor = self.view.tintColor
        c234.valueHandler = { _ in
            AppCenter.charge.try(for: URLOpenPayment<URLOpenTypeReferenceGuide>.self)
        }
        informationOfUsetCellDescribers.append(c234)
        
        let c3243 = UITableViewButtonCellDescriber()
        c3243.label = "Engineering Notes".localized
        c3243.buttonTitle = "Open".localized
        c3243.iconImage = R.image.cellIconReferenceGuide()//?.crop(aspectFillInset: CGPoint(x: 6, y: 0))
        c3243.iconImageTintColor = self.view.tintColor
        c3243.valueHandler = { _ in
            AppCenter.charge.try(for: URLOpenPayment<URLOpenTypeEngineeringNotes>.self)
        }
        informationOfUsetCellDescribers.append(c3243)
        
        let c3 = UITableViewButtonCellDescriber()
        c3.label = "Privacy Policy".localized
        c3.buttonTitle = "Open".localized
        c3.iconImage = R.image.commonCellIconInfo()//?.crop(aspectFillInset: CGPoint(x: 6, y: 0))
        c3.iconImageTintColor = self.view.tintColor
        c3.valueHandler = { _ in
            AppCenter.charge.try(for: URLOpenPayment<URLOpenTypePrivacyPolicy>.self)
        }
        informationOfUsetCellDescribers.append(c3)
        
        let c7 = UITableViewButtonCellDescriber()
        c7.label = "Terms of Use".localized
        c7.buttonTitle = "Open".localized
        c7.iconImage = R.image.commonCellIconInfo()//?.crop(aspectFillInset: CGPoint(x: 6, y: 0))
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
        
        for s in self.sections{
            if let cellGroup = s as? CellDescriberGroup{
                for desc in cellGroup.describers {
                    tableView.register(describer: desc)
                }
            }
        }
        
        tableView.reloadData()
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
            
            if section is CellDescriberGroup, let item = section.itemsOfSection[indexPath.item] as? UITableViewCellDefaultDescribable{
                return cellForRow(tableView, cellForRowAt: indexPath, forItem:item)
            }
        }
        
        assert(false, "Section Index \(indexPath.section) was overflowed or undefined section type.")
        return UITableViewCell()
    }
}

/*
 Cell Loaders by Group Type
 */
extension SettingsAppDockContent {
    
    private func defaultSetCellAppearanceForRow(cellForRowAt indexPath: IndexPath, describer:UITableViewCellDescriber, cell:UITableViewCell){
        let item = describer
        
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.text = item.label
        
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.text = item.detailedLabel
        
        if let image = item.iconImage?.asUIImage, let imageView = cell.imageView{
            imageView.image = image.withRenderingMode(.alwaysTemplate)
            
            if let iconTintColor = item.iconImageTintColor{
                imageView.tintColor = iconTintColor
            }else{
                imageView.tintColor = self.view.tintColor
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
            cell.switcher.onTintColor = ShopApp.info.themeColor
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
