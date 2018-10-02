//
//  SiriSettings.SApp.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 9. 17..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import PropertyKit
import Intents
import IntentsUI

class SiriApp: NSObject
    , PropertyWatchable
    , SApp
    , AppDockApp {
    public private(set) lazy var content: AppDockContent? = SiriSettingsDockContent()
    
    public static let info = AppInfo(
        identifier: "com.stells.pap.siri"
        , version: "1.0"
        , phase: .release
        , appType: SiriApp.self
        , displayName: "Siri"
        , description: nil
        , keywords: nil
        , iconBundleName: R.image.siriSAppIcon.name
        , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: .default)
        , minOSVersion: OperatingSystemVersion(majorVersion: 12, minorVersion: 0, patchVersion: 0)
    )
    
    public required override init() {
        
    }
    
    public private(set) static var fixedContentLayout: Bool = true
}

fileprivate class SiriSettingsDockContent: NSObject, AppDockContent {
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
    
    lazy var delegator = SiriSettingsTableViewContentDelegator()
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        tableView.dataSource = delegator
        tableView.delegate = delegator
        tableView.rowHeight = UITableView.automaticDimension
        tableView.allowsSelection = false
        tableView.allowsMultipleSelection = false
        
        reloadData()
    }
    
    func didSetContentView(_ view:UIView, dock:AppDock) {
        
    }
    
    private func reloadData() {
        delegator.group.removeAll()
        
        if #available(iOS 12.0, *) {
            let apps = AppCenter.default.apps(by: .default)
                    .compactMap { return $0 as? UIApplicationDelegatableApp.Type}
                    //INFO: sort by amount of intent
                    .sorted { appType, appType2 in
                        return appType.intents.count > appType2.intents.count
                    }

            for section in apps.map({ (app) -> IntentGroup in
                IntentGroup(app: app)
            }) {
                var intentCellDescribers = [UITableViewCellDefaultDescribable]()
                
                for intent in section.intents {
                    let cell = UITableViewCustomViewAccessoryCellDescriber()
                    cell.itemIdentifier = "Intent".hashValue
                    cell.label = "\"\(intent.suggestedInvocationPhrase ?? "")\""
                    cell.accessoryGenerator = {
                        let button = intent.addToSiriButton(style: .white)
                        button?.delegate = self
                        return button
                    }
                    intentCellDescribers.append(cell)
                    
                    intent.donate()
                }

                let groupDescriber = UITableViewCellDescriber()
                groupDescriber.itemIdentifier = "groupDescriber".hashValue
                groupDescriber.label = section.app?.info.displayName ?? "Unknown App"
                groupDescriber.iconImage = section.app?.info.iconBundleName

                let group = CellDescriberGroup(label: section.label, detailedLabel: section.detailedLabel, groupHeaderCellDescriber: groupDescriber, itemCellDescribers: intentCellDescribers)
                delegator.group.append(group)
            }
        }

        for group in delegator.group{
            if let groupDesc = group.groupHeaderCellDescriber{
                tableView.register(describer: groupDesc)
            }
            for intentCellDescriber in group.itemCellDescribers {
                tableView.register(describer: intentCellDescriber)
            }
        }

        tableView.reloadData()
    }
}

private protocol Section{
    var label:String{get}
    var detailedLabel:String?{get}
    var itemsOfSection:[Any]{get}
}

private struct IntentGroup: Hashable, Equatable, Section {
    var app: App.Type?
    var title: String
    var intents: [INIntent]
    
    var label: String {
        return app?.info.displayName ?? title
    }
    
    var detailedLabel: String? {
        return nil
    }
    
    var itemsOfSection: [Any] {
        return intents
    }
    
    var hashValue: Int{
        return app?.info.hashValue ?? title.hash
    }
    
    static func == (lhs: IntentGroup, rhs: IntentGroup) -> Bool{
        return lhs.hashValue == rhs.hashValue
    }
    
    init(app: App.Type) {
        self.app = app
        self.title = ""
        self.intents = (app as? UIApplicationDelegatableApp.Type)?.intents ?? []
    }
    
    init(title: String, intents: [INIntent]) {
        self.app = nil
        self.title = title
        self.intents = intents
    }
}

private struct CellDescriberGroup: Section{
    fileprivate let label:String
    fileprivate var detailedLabel:String?
    fileprivate var groupHeaderCellDescriber:UITableViewCellDefaultDescribable?
    fileprivate var itemCellDescribers:[UITableViewCellDefaultDescribable]
    
    var itemsOfSection: [Any] {
        return itemCellDescribers
    }
}

private class SiriSettingsTableViewContentDelegator: NSObject, UITableViewDataSource, UITableViewDelegate {
    var group: [CellDescriberGroup] = []
    
    convenience init(group: [CellDescriberGroup]) {
        self.init()
        
        self.group = group
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return group.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = group[section]
        return section.itemsOfSection.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellDescriber = group[indexPath.section].itemCellDescribers[indexPath.row]

        if let cellDescriber = cellDescriber as? UITableViewCustomViewAccessoryCellDescriber
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewCustomViewAccessoryCell {

            cell.textLabel?.text = cellDescriber.label
            cell.detailTextLabel?.text = cellDescriber.detailedLabel
            cell.textLabel?.font = UIFont.italicSystemFont(ofSize: UIFont.systemFontSize)
            cell.detailTextLabel?.textColor = UIColor.gray
            
            if let button = cellDescriber.accessoryGenerator?() {
                button.translatesAutoresizingMaskIntoConstraints = false
                cell.customAccessoryView = button

                button.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 0).isActive = true
                cell.contentView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 0).isActive = true
                cell.contentView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 0).isActive = true
            }
            
            return cell
        }
        else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return group[section].label
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return group[section].detailedLabel
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    private lazy var iconImageCache:NSCache = NSCache<NSString,UIImage>()

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        if let cellDescriber = group[section].groupHeaderCellDescriber,
           let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier){

            var iconImage = iconImageCache.object(forKey: cellDescriber.label as NSString)
            if iconImage == nil{
                if let image = cellDescriber.iconImage?.asUIImage?.rounded()?.resize(aspectFit: CGSize(width: 34, height: 34)){
                    iconImage = image
                    iconImageCache.setObject(image, forKey: cellDescriber.label as NSString)
                }
            }

            cell.imageView?.image = iconImage
            cell.textLabel?.text = cellDescriber.label
            cell.textLabel?.textColor = UIColor.gray
            cell.textLabel?.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
            return cell
        }

        return nil
    }
}

@available(iOS 12.0, *)
extension INIntent {
    func addToSiriButton(style: INUIAddVoiceShortcutButtonStyle) -> INUIAddVoiceShortcutButton? {
        let button = INUIAddVoiceShortcutButton(style: style)
        button.shortcut = INShortcut(intent: self)
        return button
    }
    
    func donate() {
        let interaction = INInteraction(intent: self, response: nil)
        if let appId = self.appIdentifier {
            interaction.groupIdentifier = appId
        }
        interaction.identifier = String(describing: self)
        interaction.donate(completion: nil)
    }
}

@available(iOS 12.0, *)
extension SiriSettingsDockContent: INUIAddVoiceShortcutButtonDelegate {
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        addVoiceShortcutViewController.delegate = self
        UIViewController.present(addVoiceShortcutViewController, animated: true, completion: nil)
    }
    
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        editVoiceShortcutViewController.delegate = self
        UIViewController.present(editVoiceShortcutViewController, animated: true, completion: nil)
    }
}

@available(iOS 12.0, *)
extension SiriSettingsDockContent: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

@available(iOS 12.0, *)
extension SiriSettingsDockContent: INUIEditVoiceShortcutViewControllerDelegate {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)

        tableView.reloadData()
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
