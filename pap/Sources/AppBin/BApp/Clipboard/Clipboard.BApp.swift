//
//  Clipboard.BApp.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 10. 18..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Photos
import PropertyKit

private typealias ClipboardAppParam = AppAsset
private struct ClipboardAppResult: AppTaskResultable {
//    fileprivate let asset:PHAsset
//    fileprivate let isAdjusted:Bool
}
private class _ClipboardAppTask: AppTaskPrototype, AppTaskable {
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){}
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is ClipboardAppParam, "TaskParamable type of this app is \(ClipboardAppParam.self)")
        guard let _param = param as? ClipboardAppParam else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ clipboardParam: ClipboardAppParam, _ async: AsyncWaitSignalable) throws -> ClipboardAppResult?  {
//        guard revertParam.asset.isAdjusted else { return RevertAppResult(asset: revertParam.asset, isAdjusted: revertParam.asset.isAdjusted) }
        
//        async.begin()
//
//        DispatchQueue(label: "com.stells.internal."+#file, qos: .utility).async {
//            //INFO: prepare original version of asset
//            // it may get original version from icloud to local
//            PHImageManager.default().touchOriginalVersion(for: revertParam.asset, completion: {
//                async.end()
//            })
//        }
//
//        async.waitUntilEnd()
        return ClipboardAppResult()
    }
}

class ClipboardApp: NSObject, BApp, PropertyWatchable, AppDockApp {
    public static let taskType: AppTaskable.Type = _ClipboardAppTask.self
    public static let paramType: AppTaskParamable.Type = ClipboardAppParam.self
    
    public static let info = AppInfo(
        identifier: "com.stells.pap.clipboard"
        , version: "1.0"
        , phase: .develop
        , appType: ClipboardApp.self
        , displayName: "Clipboard".localized.localizedCapitalized
        , description: "Paste images from your clipboards".localized
        , keywords: ["Clipboard","Pasteboard","Copy","Paste","Cut"]
        , iconBundleName: nil
        , themeColor: UIColor.lightGray
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    public private(set) lazy var content: AppDockContent? = ClipboardAppDockContent()
    
    required override init() {
        super.init()
    }
}

fileprivate class ClipboardAppDockContent: NSObject, PropertyWatchable, AppDockContent {
    lazy var view: UIView = {
        let view = UIView(frame: .zero)
        view.addSubview(tableView)
        tableView.fitConstraints(to: view)
//        view.addSubview(pasteButton)
//        pasteButton.translatesAutoresizingMaskIntoConstraints = false
//        pasteButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
//        view.bottomAnchor.constraint(equalTo: pasteButton.bottomAnchor, constant: 10).isActive = true
//        pasteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
//        view.trailingAnchor.constraint(equalTo: pasteButton.trailingAnchor, constant: 10).isActive = true
        return view
    }()
    
    private lazy var pasteButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.roundedRect)
        button.backgroundColor = UIColor.lightGray
        button.setTitle("Paste", for: .normal)
        button.addTarget(self, action: #selector(self.pasteButtonDidTap), for: .touchUpInside)
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        return tableView
    }()
    
    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = min(tableView.contentSize.height, 44 * 4)
        return preferences
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        tableView.dataSource = delegator
        tableView.delegate = delegator
        tableView.rowHeight = UITableView.automaticDimension
        tableView.allowsSelection = false
        tableView.allowsMultipleSelection = false
        tableView.tintColor = view.tintColor
    }
    
    func didSetContentView(_ view:UIView, dock:AppDock) {
        view.tintColor = view.colorTheme.tintColor
        
        reloadData()
    }
    
    lazy var delegator = ClipboardTableViewContentDelegator()
    
    private func reloadData() {
        delegator.group.removeAll()
        
        let items = UIPasteboard.general.items
        for item in items {
            let values = item.keys.map { (key: $0, value: item[$0]) }
            let group = ClipboardGroup(type: "", values: values)
            
            var cellDescribers = [UITableViewButtonCellDescriber]()
            for (idx, value) in values.enumerated() {
                let cell = UITableViewButtonCellDescriber()
                cell.itemIdentifier = idx
                cell.label = "\(value.key) \(value.value ?? "")"
                cellDescribers.append(cell)
            }
            
            let cellGroup = CellDescriberGroup(label: group.label, detailedLabel: nil, groupHeaderCellDescriber: nil, itemCellDescribers: cellDescribers)
            delegator.group.append(cellGroup)
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
    
    @objc private func pasteButtonDidTap(sender: UIButton) {
        
    }
}

private protocol Section{
    var label:String{get}
    var detailedLabel:String?{get}
    var itemsOfSection:[Any]{get}
}

private struct ClipboardGroup: Hashable, Equatable, Section {
    var type: String
    var values: [Any]
    
    var label: String {
        return ""
    }
    
    var detailedLabel: String? {
        return nil
    }
    
    var itemsOfSection: [Any] {
        return values
    }
    
    var hashValue: Int{
        return type.hashValue
    }
    
    static func == (lhs: ClipboardGroup, rhs: ClipboardGroup) -> Bool{
        return lhs.hashValue == rhs.hashValue
    }
    
    init(type: String, values: [Any]) {
        self.type = type
        self.values = values
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

private class ClipboardTableViewContentDelegator: NSObject, UITableViewDataSource, UITableViewDelegate {
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
        
        if let cellDescriber = cellDescriber as? UITableViewButtonCellDescriber
            , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewButtonCell {
            
            cell.textLabel?.text = cellDescriber.label
            
            if let buttonTitle = cellDescriber.buttonTitle{
                cell.setButtonTitle(title: buttonTitle, detailTitle: cellDescriber.buttonDetailTitle, for: .normal)
                cell.button.setTitleColor(tableView.tintColor, for: .normal)
            }
            cell.didTap = {
                cellDescriber.valueHandler?("tapped")
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
                if let image = cellDescriber.iconImage?.asUIImage?/*.rounded()?*/.resize(aspectFit: CGSize(width: 34, height: 34)){
                    iconImage = image
                    iconImageCache.setObject(image, forKey: cellDescriber.label as NSString)
                }
            }
            
            cell.imageView?.image = iconImage
            cell.textLabel?.text = cellDescriber.label
            cell.textLabel?.textColor = UIColor.gray
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
            cell.backgroundColor = UIColor.clear
            return cell
        }
        
        return nil
    }
}
