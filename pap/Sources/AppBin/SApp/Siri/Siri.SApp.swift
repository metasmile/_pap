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
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let navigationBar = UINavigationBar(frame: .zero)
        view.addSubview(navigationBar)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        tableView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        
        let navigationItem = UINavigationItem()
        navigationItem.titleView = searchBar
        navigationBar.items = [navigationItem]
        
        return view
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.sizeToFit()
        return searchBar
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
        
        tableView.tableHeaderView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: 22)))
        
        searchBar.placeholder = "Search for %@".localizedFormatted("Siri Shortcuts")
        searchBar.delegate = self
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { (notification) in
            guard let frameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            let frame = frameValue.cgRectValue
            
            self.tableView.contentInset.bottom = frame.height - (UIScreen.main.bounds.height - dock.contentInsets.bottom)
            self.tableView.scrollIndicatorInsets.bottom = self.tableView.contentInset.bottom
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { (notification) in
            self.tableView.contentInset.bottom = 0
            self.tableView.scrollIndicatorInsets.bottom = self.tableView.contentInset.bottom
        }
        
        reloadData()
    }
    
    func didSetContentView(_ view:UIView, dock:AppDock) {
        
    }

    private lazy var appsWithIntent = AppCenter.default.apps(by: .default)
            .compactMap { return $0 as? UIApplicationDelegateLaunchableApp.Type}
            .sorted { appType, appType2 in
                return appType.intents.count > appType2.intents.count
            }

    private var intentCellDescribersDict = [String:UITableViewCustomViewAccessoryCellDescriber]() // INIIntent.identifier: UITableViewCustomViewAccessoryCellDescriber
    private var tempIntentCellDescribers = [UITableViewCustomViewAccessoryCellDescriber]() // INIIntent.identifier: UITableViewCustomViewAccessoryCellDescriber

    private var intentGroups = [String:IntentGroup]() // App.info.identifier: IntentGroup
    private var intentCellDescriberGroups = [IntentGroup:CellDescriberGroup]() // IntentGroup: UITableViewCellDescriber

    private func reloadData(with searchText: String? = nil) {
        delegator.group.removeAll()
        
        if #available(iOS 12.0, *) {

            for app in appsWithIntent{
                let intentGroup:IntentGroup
                if let _intentGroup = intentGroups[app.info.identifier]{
                    intentGroup = _intentGroup
                }else{
                    intentGroup = IntentGroup(app: app)
                    intentGroups[app.info.identifier] = intentGroup
                }

                tempIntentCellDescribers.removeAll()

                for intent in intentGroup.intents {
                    if let searchText = searchText?.lowercased(), !searchText.isEmpty {
                        guard intent.suggestedInvocationPhrase?.lowercased().contains(searchText) == true else {
                            continue
                        }
                    }

                    let describerKey = intent.identifier ?? "\"\(intent.suggestedInvocationPhrase ?? "")\""

                    let cell:UITableViewCustomViewAccessoryCellDescriber
                    if let _cell = intentCellDescribersDict[describerKey]{
                        cell = _cell
                    }else{
                        cell = UITableViewCustomViewAccessoryCellDescriber()
                        cell.itemIdentifier = "Intent".hashValue
                        cell.label = "\"\(intent.suggestedInvocationPhrase ?? "")\""
                        cell.accessoryGenerator = {
                            let button = intent.addToSiriButton(style: .white)
                            button?.delegate = self
                            return button
                        }
                        intentCellDescribersDict[describerKey] = cell
                    }
                    tempIntentCellDescribers.append(cell)

                    intent.donate()
                }

                guard !tempIntentCellDescribers.isEmpty else { continue }

                var group:CellDescriberGroup
                if let _group = intentCellDescriberGroups[intentGroup]{
                    group = _group
                    group.itemCellDescribers = tempIntentCellDescribers

                } else{
                    let groupDescriber = UITableViewCellDescriber()
                    groupDescriber.itemIdentifier = "IntentGroup".hashValue
                    groupDescriber.label = intentGroup.app?.info.displayName ?? "Unknown App"
                    groupDescriber.iconImage = intentGroup.app?.info.iconBundleName

                    group = CellDescriberGroup(label: intentGroup.label, detailedLabel: intentGroup.detailedLabel, groupHeaderCellDescriber: groupDescriber, itemCellDescribers: tempIntentCellDescribers)

                    intentCellDescriberGroups[intentGroup] = group
                }

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
        return app?.info.identifier.hashValue ?? title.hashValue
    }
    
    static func == (lhs: IntentGroup, rhs: IntentGroup) -> Bool{
        return lhs.hashValue == rhs.hashValue
    }
    
    init(app: App.Type) {
        self.app = app
        self.title = ""
        self.intents = (app as? UIApplicationDelegateLaunchableApp.Type)?.intents ?? []
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

extension SiriSettingsDockContent: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        
        updateFilteredItems(by: searchBar.text)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        let textHasExisted = searchBar.text?.trimmed.count ?? 0 > 0
        if textHasExisted{
            searchBar.text = nil
            updateFilteredItems(by:nil)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateFilteredItems(by: searchText)
    }

    private func updateFilteredItems(by searchText: String?) {
        guard searchText?.trimmed.count ?? 0 > 0 else {
            Timer.removeScheduledTimer(identifier: #function)
            reloadData()
            return
        }

        Timer.scheduledTimer(identifier: #function, withTimeInterval: 0.5) { timer in
            DispatchQueue.main.asyncAfter(deadline: .now()){
                self.reloadData(with: searchText)
            }
        }
    }
}
