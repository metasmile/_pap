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
        , PhotoPickerCollectionViewDisplayableApp
        , LaunchableApp {

    public static let taskType: AppTaskable.Type = AppVoidTask.self

    public static let paramType: AppTaskParamable.Type = AppTaskVoidParameter.self

    public private(set) lazy var content: AppDockContent? = ShopAppDockContent()

    fileprivate static let privateDefaults = ShopApp.defaults as! ShopAppDefaults

    public static let info = AppInfo(
            identifier: "com.stells.pap.shop"
            , version: "1.0"
            , phase: .release
            , appType: ShopApp.self
            , displayName: "Shop".localized
            , description: nil
            , keywords: nil
            , iconBundleName: nil
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    public required override init() {

    }

    func shouldSelect(item: AppAsset) -> Bool {
        return false
    }

    func didResign(current: App.Type?) {

    }

    func didLaunch(previous: App.Type?, withOption: AppLaunchOption?) {
    }
}




/*

AppContent

*/

private enum SelectionPreset:Int{
    case action
    case contact
    case plaintext
}

private enum ShopAppSettingCells {
    case takePhoto
    case presets
    case autoSelect
    case saveContactWithoutEdit
    case quickActionOnly
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

private protocol ShopAppDefaults: AppDefaults{
    var selectedParserCollection: ParserCollection {get set}
    var selectionPreset: Int {get set}
    var saveContactWithoutEdit:Bool {get set}
    var quickActionOnly:Bool {get set}
}

extension Defaults: ShopAppDefaults {
    fileprivate var selectedParserCollection: ParserCollection {
        set{ set(newValue) }
        get{ return get(or: ParserDictionary.DefaultCollection) }
    }

    fileprivate var selectionPreset: Int {
        set{ set(newValue); papLog.app.defaults.log(value: newValue) }
        get{ return get(or: SelectionPreset.plaintext.rawValue ) }
    }

    fileprivate var saveContactWithoutEdit: Bool {
        set{ set(newValue); papLog.app.defaults.log(value:newValue) }
        get{ return get(or: false ) }
    }

    fileprivate var quickActionOnly: Bool {
        set{ set(newValue); papLog.app.defaults.log(value:newValue)  }
        get{ return get(or: false ) }
    }
}

extension ShopAppDefaults{
    fileprivate func addHandledProperty(_ dictionary:ParserDictionary.Key, _ property:ParserItem.Key){

        var immutableSelf = self
        if immutableSelf.selectedParserCollection[dictionary] == nil{
            immutableSelf.selectedParserCollection = ParserCollection()
            var p = immutableSelf.selectedParserCollection
            p[dictionary] = [property]
            immutableSelf.selectedParserCollection = p
        }else{
            if selectedParserCollection[dictionary]?.contains(property) == false{
                var p = immutableSelf.selectedParserCollection
                p[dictionary]?.append(property)
                immutableSelf.selectedParserCollection = p
            }
        }
    }

    fileprivate func removeHandledProperty(_ dictionary:ParserDictionary.Key, _ property:ParserItem.Key){

        if let index = selectedParserCollection[dictionary]?.index(of: property){
            var immutableSelf = self
            var p = immutableSelf.selectedParserCollection
            p[dictionary]?.remove(at: index)
            immutableSelf.selectedParserCollection = p
        }
    }
}

private typealias ParserCollection = [ParserDictionary.Key: [ParserItem.Key]]

private struct ParserItem {
    enum Key: Int, Codable {
        case PhoneNumber
        case EmailAddress
        case Address

        case Date
        case URL

        case FlightNumber
        case GPSCoordinates
    }

    fileprivate var key:Key
    fileprivate var label:String
    fileprivate var iconImageBundleName:String?
}

private struct ParserDictionary {

    static let DefaultCollection: ParserCollection = [
        ParserDictionary.Key.Information: [
            ParserItem.Key.PhoneNumber
            ,ParserItem.Key.EmailAddress
            ,ParserItem.Key.Address

            ,ParserItem.Key.Date
            ,ParserItem.Key.URL
            ,ParserItem.Key.FlightNumber
        ]
    ]

    enum Key: Int, Codable {
        case Information
    }

    fileprivate var key:Key
    fileprivate var label:String
    fileprivate var items:[ParserItem]
}

fileprivate class ShopAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource, UITableViewPickerCellDelegate{
    private lazy var tintColor = UIColor(red:0.36, green:0.31, blue:0.71, alpha:1)

    fileprivate var settingCellDescribers = [UITableViewCellDefaultDescribable]()

    private var parserCollection:[ParserDictionary] {
        get{
            if ShopApp.privateDefaults.selectionPreset == SelectionPreset.plaintext.rawValue{
                return []
            }

            return type(of: self).defaultParserCollection
        }
    }

    fileprivate static let defaultParserCollection:[ParserDictionary] = [

        ParserDictionary(key: ParserDictionary.Key.Information, label: "Items".localized,
                items: [
                    ParserItem(key: ParserItem.Key.PhoneNumber, label:"Phone Number".localized, iconImageBundleName:R.image.ico_action_phonenumber.name)
                    ,ParserItem(key: ParserItem.Key.EmailAddress, label:"E-mail Address".localized, iconImageBundleName:R.image.ico_action_email.name)
                    ,ParserItem(key: ParserItem.Key.Address, label:"Address".localized, iconImageBundleName:R.image.ico_action_address.name)
                    ,ParserItem(key: ParserItem.Key.Date, label:"Date".localized, iconImageBundleName:R.image.ico_action_date.name)
                    ,ParserItem(key: ParserItem.Key.URL, label:"URL", iconImageBundleName:R.image.ico_action_url.name)
                    ,ParserItem(key: ParserItem.Key.FlightNumber, label:"Flight Number".localized, iconImageBundleName:R.image.ico_action_flightnumber.name)
                ])
    ]

    required public override init() {
        super.init()
    }

    private var initialSelectedIndexPaths:[IndexPath]?

    lazy var view: UIView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tintColor = tintColor
        return tableView
    }()

    lazy var footerView:UITextView = UITableView.createHeaderFooterViewForMessage(text:"Currently, our AI text recognition model is only available for Alphanumeric and some special characters.".localized)

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = 300
        return preferences
    }

    private var selectedParserCollection: ParserCollection{
        return ShopApp.privateDefaults.selectedParserCollection
    }

    private var autoSelect:Bool = false


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

    func willSetContentView(_ view: UIView, dock: AppDock) {

        if settingCellDescribers.count>0{
            return
        }

        let cell1 = UITableViewSwitchSubtitleCellDescriber()
        cell1.itemIdentifier = ShopAppSettingCells.autoSelect.hashValue
        cell1.label = "Auto Selection Bot".localized
        cell1.valueGetter = { self.autoSelect }
        cell1.iconImage = R.image.commonIconRobot.name
//        cell1.valueHandler = {
//
//        }
        settingCellDescribers.append(cell1)

        let cell_b = UITableViewButtonCellDescriber()
        cell_b.itemIdentifier = ShopAppSettingCells.takePhoto.hashValue
        cell_b.label = "Take A Photo".localized
        cell_b.buttonImageName = R.image.systemIconCamera.name
        cell_b.valueHandler = { _ in
            var option = AppLaunchOption()
            option.identifierToReturn = ShopApp.info.identifier

            AppCenter.default.openApp(identifier:"com.stells.pap.camera", options:option)

        }
        settingCellDescribers.append(cell_b)


        let cell0 = UITableViewSegmentControlCellDescriber()
        cell0.itemIdentifier = ShopAppSettingCells.presets.hashValue
        cell0.label = "Formats".localized
        cell0.valueGetter = { ShopApp.privateDefaults.selectionPreset }
        cell0.valueCollection = [
            (label:"Actions".localized,value: SelectionPreset.action.rawValue),
            (label:"Contacts".localized,value: SelectionPreset.contact.rawValue),
            (label:"Text".localized,value: SelectionPreset.plaintext.rawValue)
        ]
        cell0.valueHandler = {
            let preset = $0 as! Int

            var defaults = ShopApp.privateDefaults
            defaults.selectionPreset = preset

            // selectionPreset changed -> other self.parserCollection getter will be returned.
            (view as? UITableView)?.reloadData()


            [
                ShopAppSettingCells.saveContactWithoutEdit.hashValue
                , ShopAppSettingCells.quickActionOnly.hashValue
            ].forEach { hashValue in

                if let index = self.settingCellDescribers.index(where:{ describable in
                    return describable.itemIdentifier == hashValue
                }){
                    self.settingCellDescribers.remove(at: index)
                }
            }

            //saveContactWithoutEdit
            if preset == SelectionPreset.contact.rawValue{
                self.settingCellDescribers.append(self.createCellDescriber_SelectionPreset_contact_saveContactWithoutEdit())
            }

            if preset == SelectionPreset.action.rawValue{
                self.settingCellDescribers.append(self.createCellDescriber_SelectionPreset_action_quickActionsOnly())
            }

            let tableView = view as? UITableView
            tableView?.reloadData()

            /*let d = Defaults.shared.shortVersionDescription*/
            if /*(d == .new || d == .first) && */(tableView?.numberOfSections ?? 0 > 1 && tableView?.numberOfRows(inSection: 1) ?? 0 > 1){
                tableView?.scrollToRow(at: IndexPath(item: 0, section: 1), at: .middle, animated: true)
            }

            // autoSelect turn off and restore
            cell1.valueHandler?(false)

        }
        settingCellDescribers.append(cell0)

        //auto save
        if ShopApp.privateDefaults.selectionPreset == SelectionPreset.contact.rawValue{
            settingCellDescribers.append(createCellDescriber_SelectionPreset_contact_saveContactWithoutEdit())
        }
        else if ShopApp.privateDefaults.selectionPreset == SelectionPreset.action.rawValue{
            settingCellDescribers.append(createCellDescriber_SelectionPreset_action_quickActionsOnly())
        }

        if let tableView = view as? UITableView{
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = 44
            tableView.allowsSelection = false
            tableView.allowsMultipleSelection = false
            tableView.register(Cell.self, forCellReuseIdentifier: ShopApp.info.identifier)
            for desc in settingCellDescribers {
                tableView.register(describer: desc)
            }
        }
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {

        let defaultsCollection = ShopApp.privateDefaults.selectedParserCollection

        //get indexes
        let sections = self.parserCollection.enumerated().compactMap { (section, dictionary) -> [IndexPath]? in
            if let handledItems = defaultsCollection[dictionary.key]{

                return handledItems.compactMap { key -> IndexPath? in
                    guard let item = dictionary.items.index(where: { item -> Bool in
                        return key == item.key
                    }) else{
                        return nil
                    }
                    return IndexPath(item: item, section: 1+section)
                }
            }
            return nil
        }


        //init initialSelectedIndexPaths
        initialSelectedIndexPaths = [IndexPath]()
        for indexPaths in sections{
            initialSelectedIndexPaths?.append(contentsOf: indexPaths)
        }

        (view as? UITableView)?.reloadData()

        initialSelectedIndexPaths = nil
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }

    func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {

    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + parserCollection.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return tableView.numberOfSections-1 == section ? footerView.height : 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        let label_section0 = "Select Photos To Find Everything.".localized
        return section == 0 ? label_section0 : parserCollection[section-1].label
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        footerView.sizeThatFits(CGSize(width:tableView.width, height:footerView.height))
        return tableView.numberOfSections-1 == section ? footerView : nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? settingCellDescribers.count : parserCollection[section-1].items.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = indexPath.section == 0 ? settings_tableView(tableView, cellForRowAt: indexPath) : parserCollection_tableView(tableView, cellForRowAt: IndexPath(item: indexPath.item, section: indexPath.section))
        return cell
    }

    func settings_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.settingCellDescribers[indexPath.item]

        if let cellDescriber = item as? UITableViewPickerCellDescriber
        , let valueCollection = cellDescriber.valueCollection as? [String]
        , let cell: UITableViewPickerCell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewPickerCell {

            cell.values = valueCollection
            cell.delegate = self
            if let value = item.valueGetter() as? String ?? valueCollection.first, let index = valueCollection.index(of: value){
                cell.selectedRow = index
            } else{
                cell.selectedRow = 0
            }
            cell.titleLabel.text = item.label
            return cell

        }

        else if let cellDescriber = item as? UITableViewSwitchCellDescriber
        , let value = item.valueGetter() as? Bool
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSwitchCell {

            cell.textLabel?.text = item.label
            cell.detailTextLabel?.text = item.detailedLabel
            cell.switcher.setOn(value, animated: false)
            cell.switcher.onTintColor = self.view.tintColor
            cell.imageView?.image = item.iconImage?.asUIImage?.withRenderingMode(.alwaysTemplate)
            cell.imageView?.tintColor = self.view.tintColor
            cell.switchDidChange = item.valueHandler
            return cell
        }

        else if let cellDescriber = item as? UITableViewButtonCellDescriber
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewButtonCell {

            cell.textLabel?.text = item.label

            if let buttonAsImage = cellDescriber.buttonImageName?.asUIImage{
                cell.button.setImage(buttonAsImage.withRenderingMode(.alwaysTemplate), for: .normal)
            }else if let buttonAsText = cellDescriber.buttonTitleLabel {
                cell.button.setTitle(buttonAsText, for: .normal)
                cell.button.setTitleColor(self.view.tintColor, for: .selected)
                cell.button.setTitleColor(self.view.tintColor, for: .highlighted)
            }
            cell.button.tintColor = self.view.tintColor
            cell.imageView?.image = item.iconImage?.asUIImage?.withRenderingMode(.alwaysTemplate)
            cell.imageView?.tintColor = self.view.tintColor
            cell.didTap = {
                cellDescriber.valueHandler?(true)
            }
            cell.button.layoutIfNeeded()
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

    func parserCollection_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let dict = self.parserCollection[indexPath.section-1]

        var selected = false
        if let _ = initialSelectedIndexPaths?.index(of: indexPath) {
            selected = true
        }
        if let _ = ShopApp.privateDefaults.selectedParserCollection[dict.key]?.index(of: dict.items[indexPath.item].key){
            selected = true
        }

        let dataItem = dict.items[indexPath.item]

        let cell = tableView.dequeueReusableCell(withIdentifier: ShopApp.info.identifier) as! Cell
        cell.textLabel?.text = dataItem.label
        cell.detailTextLabel?.text = selected ? "%@ might be found".localizedFormatted("").trimmed : nil

        cell.imageView?.tintColor = self.view.tintColor
        let image = dataItem.iconImageBundleName?.asUIImageNamed
        cell.imageView?.image = image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)

        cell.detailTextLabel?.textColor = UIColor.gray
        cell.optionSwitch.setOn(selected, animated: false)
        cell.switchDidChange = { on in

            if on{
                papLog.app.defaults.log(value: String(describing: dict.items[indexPath.item].key))
                ShopApp.privateDefaults.addHandledProperty(dict.key, dict.items[indexPath.item].key)
            }else{
                ShopApp.privateDefaults.removeHandledProperty(dict.key, dict.items[indexPath.item].key)
            }

            tableView.reloadRows(at: [indexPath], with: .fade)
        }
        return cell
    }

    func pickerCell(_ cell: UITableViewPickerCell, didPick row: Int, value: Any) {

    }
}

private class Cell: UITableViewCell {
    lazy var optionSwitch: UISwitch = {
        let view = UISwitch()
        view.addTarget(self, action: #selector(self.cellSwitchDidChange), for: .valueChanged)
        return view
    }()

    var switchDidChange: ((Bool) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()

        switchDidChange = nil
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        accessoryView = optionSwitch
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func cellSwitchDidChange(sender: UISwitch) {
        switchDidChange?(sender.isOn)
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        optionSwitch.onTintColor = tintColor
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

        prepareStatusDisplaying(label: self.autoSelect ? "On Standby".localized : nil)
        self.stopSelectionBotIconAnimation(self.settingCellDescribers, ShopAppSettingCells.autoSelect.hashValue)
    }
}
