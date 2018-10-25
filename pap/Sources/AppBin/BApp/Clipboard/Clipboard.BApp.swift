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
        return tableView
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        return tableView
    }()
    
    var contentScrollable: AppDockContentScrollable? {
        return AppDockScrollableContent(tableView)
    }
    
    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = tableView.estimatedRowHeight * 5
        return preferences
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        tableView.dataSource = delegator
        tableView.delegate = delegator
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.allowsSelection = false
        tableView.allowsMultipleSelection = false
        tableView.tintColor = view.tintColor
    }
    
    func didSetContentView(_ view:UIView, dock:AppDock) {
        view.tintColor = view.colorTheme.tintColor
        
        reloadData()
        
        registerClipboardObservingTimer()
    }
    
    func willRemoveContentView() {
        unregisterClipboardObservingTimer()
    }
    
    private var clipboardObservingTimerId: String {
        return "\(#file)_clipboardObservingTimer"
    }
    
    private var fetchedChangeCount: Int = 0
    private var hasClipboardChanges: Bool {
        return fetchedChangeCount != UIPasteboard.general.changeCount
    }
    
    internal func registerClipboardObservingTimer() {
        Timer.scheduledTimer(identifier: clipboardObservingTimerId, withTimeInterval: 1, repeats: true) { timer in
            if self.hasClipboardChanges {
                self.reloadData()
            }
        }
    }
    
    internal func unregisterClipboardObservingTimer() {
        Timer.removeScheduledTimer(identifier: clipboardObservingTimerId)
    }
    
    lazy var delegator = ClipboardTableViewContentDelegator()
    
    private func reloadData() {
        DispatchQueue(label: #file + "fetchPasteboardItems", qos: .utility).async {
            self.delegator.group = self.fetchPasteboardItems()
            
            DispatchQueue.main.async {
                for group in self.delegator.group{
                    if let groupDesc = group.groupHeaderCellDescriber{
                        self.tableView.register(describer: groupDesc)
                    }
                    for intentCellDescriber in group.itemCellDescribers {
                        self.tableView.register(describer: intentCellDescriber)
                    }
                }
                
                self.tableView.reloadData()
            }
        }
    }
    
    private func fetchPasteboardItems() -> [CellDescriberGroup] {
        self.fetchedChangeCount = UIPasteboard.general.changeCount
        
        var groups = [CellDescriberGroup]()
        
        let items = UIPasteboard.general.items
        for item in items {
            let rawValues: [(type: String, value: Any?)] = item.keys.map { (type: $0, value: item[$0]) }
            
            var values = [(type: String, value: Any?)]()
            for rawValue in rawValues {
                guard !values.contains(where: { ($0.value as? AnyHashable) == (rawValue.value as? AnyHashable) }) else { continue }
                values.append(rawValue)
            }
            
            let group = ClipboardGroup(type: "", values: values)
            
            var cellDescribers = [UITableViewButtonCellDescriber]()
            for (idx, value) in values.enumerated() {
                let cell = UITableViewButtonCellDescriber()
                cell.itemIdentifier = idx
                
                if value.type == UTI.tiff.rawValue, let data = value.value as? Data, let image = UIImage(data: data) {
                    cell.label = "Image"
                    cell.iconImage = image
                    cell.buttonTitle = "Save"
                    cell.buttonDetailTitle = "Image"
                    cell.valueHandler = { _ in
                        cell.indicating = true
                        DispatchQueue.main.async { self.tableView.reloadData() }
                        
                        self.saveImageFromData(data) {
                            cell.indicating = false
                            DispatchQueue.main.async { self.tableView.reloadData() }
                        }
                    }
                }
                else if UIPasteboard.typeListURL.contains(value.type), let url = value.value as? URL, UTI(withURL: url).conforms(to: UTI.image) {
                    cell.label = url.lastPathComponent
                    cell.buttonTitle = "Download"
                    cell.buttonDetailTitle = "Image"
                    cell.valueHandler = { _ in
                        cell.indicating = true
                        DispatchQueue.main.async { self.tableView.reloadData() }
                        
                        self.saveImageFromURL(url, completion: {
                            cell.indicating = false
                            DispatchQueue.main.async { self.tableView.reloadData() }
                        })
                    }
                }
                else if UIPasteboard.typeListString.contains(value.type), let urlString = value.value as? String, let url = URL(string: urlString), UTI(withURL: url).conforms(to: UTI.image) {
                    cell.label = url.lastPathComponent
                    cell.buttonTitle = "Download"
                    cell.buttonDetailTitle = "Image"
                    cell.valueHandler = { _ in
                        cell.indicating = true
                        DispatchQueue.main.async { self.tableView.reloadData() }
                        
                        self.saveImageFromURL(url, completion: {
                            cell.indicating = false
                            DispatchQueue.main.async { self.tableView.reloadData() }
                        })
                    }
                }
                else if UIPasteboard.typeListImage.contains(value.type), let image = value.value as? UIImage {
                    cell.iconImage = image
                    cell.label = "Image"
                    cell.buttonTitle = "Save"
                    cell.buttonDetailTitle = "Image"
                    cell.valueHandler = { _ in
                        if let data = image.jpegData(compressionQuality: 0.7) {
                            cell.indicating = true
                            DispatchQueue.main.async { self.tableView.reloadData() }
                            
                            self.saveImageFromData(data) {
                                cell.indicating = false
                                DispatchQueue.main.async { self.tableView.reloadData() }
                            }
                        }
                    }
                }
                else if UIPasteboard.typeListString.contains(value.type), let text = value.value as? String {
                    cell.label = text
                }
                else {
                    continue
                }
                
                cellDescribers.append(cell)
            }
            
            guard !cellDescribers.isEmpty else { continue }
            
            var detailedLabel: String? = nil
            if values.contains(where: { $0.type == "com.apple.is-remote-clipboard" }) {
                detailedLabel = "From Remote Clipboard"
            }
            
            let cellGroup = CellDescriberGroup(label: group.label, detailedLabel: detailedLabel, groupHeaderCellDescriber: nil, itemCellDescribers: cellDescribers)
            groups.append(cellGroup)
        }
        return groups
    }
    
    private func saveImageFromURL(_ url: URL, completion: (() -> Void)?) {
        DispatchQueue(label: #file + #function, qos: .utility).async {
            if let data = try? Data(contentsOf: url) {
                self.saveImageFromData(data, completion: completion)
            }
            else {
                completion?()
            }
        }
    }
    
    private func saveImageFromData(_ data: Data, completion: (() -> Void)?) {
        DispatchQueue(label: #file + #function, qos: .utility).async {
            let signal = AsyncSignal()
            signal.begin()
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: data, options: nil)
            }, completionHandler: { (success, info) in
                signal.end()
                completion?()
            })
            signal.waitUntilEnd()
        }
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
            
            cell.imageView?.image = cellDescriber.iconImage?.asUIImage
            cell.textLabel?.text = cellDescriber.label
            
            if let buttonTitle = cellDescriber.buttonTitle{
                cell.setButtonTitle(title: buttonTitle, detailTitle: cellDescriber.buttonDetailTitle, for: .normal)
                cell.button.setTitleColor(tableView.tintColor, for: .normal)
            }
            cell.didTap = {
                cellDescriber.valueHandler?("tapped")
            }
            
            let _ = cellDescriber.indicating ? cell.startIndicating() : cell.stopIndicating()
            
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
