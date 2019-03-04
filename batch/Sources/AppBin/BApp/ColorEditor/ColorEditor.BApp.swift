//
//  ColorEditor.BApp.swift
//  pap
//
//  Created by HYOJIN MO on 28/02/2019.
//  Copyright © 2019 Stells. All rights reserved.
//

import UIKit
import PropertyKit
import Photos

protocol ColorEditorDefaults: AppDefaults {
    var aspectRatio: Double {get set}
    var contentMode: PHImageContentMode {get set}
}

extension Defaults: ColorEditorDefaults {
    
}

class ColorEditor: NSObject, BApp, PropertyWatchable, ConfigurableApp, _ConfigurableApp,
    PHAssetFinalizableApp, EditableApp, PreviewProcessableApp, AppDockApp,
PhotoPickerCollectionViewDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp, PhotoEditorViewControllerDelegatableApp {
    public static let taskType: AppTaskable.Type = ColorEditorTask.self
    
    public static let paramType: AppTaskParamable.Type = _ColorEditorAsset.self
    
    public static var defaultConfigValue: AppConfigValuable {
        let config = FiltersAppConfigValue()
        return config
    }
    
    @objc dynamic
    public private(set) lazy var config: FiltersAppConfigValue? = type(of:self).defaultConfigValue as? FiltersAppConfigValue
    
    public private(set) lazy var content: AppDockContent? = ColorEditorDockContent()
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.coloreditor"
        , version: "0.1"
        , phase: .develop
        , appType: ColorEditor.self
        , displayName: "Color Tool".localized.localizedCapitalized, description:nil, keywords:nil
        , iconBundleName: nil
        , themeColor: UIColor(red: 1.0, green: 0, blue: 0, alpha: 1)
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    required public override init() {
        super.init()
        
        let controllerContent = self.content as? ColorEditorDockContent
        controllerContent?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContent?.filter {
                self.config?.filter = CIFilterItem(filter)
            }
            else if var defaults = type(of: self).defaults as? ColorEditorDockContent {
//                let filter = controllerContent?.preferredFilter(with: defaults.adjustments)
//
//                let filterItem = CIFilterItem(filter)
//                self.config?.filter = filterItem
//                self.defaultEditStateValue = filterItem
            }
        }
        
//        let controllerContentInPhotoEditor = self.photoEditorDockContent as? AdjustmentsAppDockContent
//        controllerContentInPhotoEditor?.watch(\.filter, options: [.initial, .new]) {
//            if let filter = controllerContentInPhotoEditor?.filter {
//                self.config?.filter = CIFilterItem(filter)
//            }
//            else if var defaults = type(of: self).defaults as? AdjustmentsAppDefaults {
//                let filter = controllerContent?.preferredFilter(with: defaults.adjustments)
//
//                let filterItem = CIFilterItem(filter)
//                self.config?.filter = filterItem
//            }
//        }
    }
    
    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.actions]
    }
    
    public static var fixedContentLayout: Bool {
        return true
    }
    
    public var doneButtonTitle: String? {
        return "Apply".localized
    }
    
    public func shouldSelect(item: AppAsset) -> Bool {
        return true
    }
    
    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
    }
    
    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?) {}
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {
        defaultEditStateValue = editStateValue
    }
    
    //INFO: prevent memory leak for creating CIImage(uiImage:)
    public lazy var previewOriginalImageCache: NSCache<NSString, CIImage>? = NSCache<NSString, CIImage>()
    public func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void)) {
        let original = cachedOriginalImage(with: appAsset.asset, targetSize: targetSize)
        
        let filtered = original?.applyFilter(ciFilter: appAsset.editState.ciFilter)
        completion(original?.asUIImage, filtered?.asUIImage)
    }
}

extension ColorEditor {
    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncWaitSignalable) -> [AppTaskRespondable] {
        let resultItems = result
            .filter { respondable in respondable.info.state == .completed }
            .compactMap { ($0.result as? ColorEditorResultItem) }
        
        var results = [PHAssetResultItem]()
        
//        let video = mergeVideo(with: resultItems)
//
//        asyncSignal.begin()
//        DispatchQueue(label: #file + "_mergeVideos", qos: .utility).async {
//            let videoURL = FileURL.temp(UUID().uuidString, UTI.quickTimeMovie, group: FileURL.fileAndQueuePrivateGroup())
//            AVAssetExportSession.export(asset: video, outputURL: videoURL, progressHandler: { progress in
//
//            }, completionHandler: { (success) in
//                if success {
//                    results.append(PHAssetResultItem(asset: AppAsset(PHAsset()), editingResultItems: [PHAssetEditingResultItem(url: videoURL, resourceType: .video)]))
//                }
//                asyncSignal.end()
//            })
//        }
//        asyncSignal.waitUntilEnd()
        
        let success = showingActionsAndWait(targetResultAssets: results, excludedActions: [.modify], asyncSignal)
        result.forEach {
            $0.info.userInfo[AppTaskInfo.UserInfo.Key.removedOnCompletion] = success
        }
        
        return result
    }
}

fileprivate class CIToneCurveFilter: CIAdjustmentFilter {
    convenience init() {
        self.init(name: "CIToneCurve", sliderInfo: CIToneCurveFilter.toneCurveSliderInfoItems())
    }
    
    static func toneCurveSliderInfoItems() -> [CIAdjustmentSliderInfo] {
        return [
            CIAdjustmentSliderInfo(name: "point0", attributeKey: "inputPoint0", userAttributeItems: [
                CIFilterAttributeItem(name: "inputPoint0.x", defaultValue: 0, minimumValue: 0, maximumValue: 1, offset: 0, canEdit: false),
                CIFilterAttributeItem(name: "inputPoint0.y", defaultValue: 0, minimumValue: 0, maximumValue: 1, offset: 1)
                ]),
            CIAdjustmentSliderInfo(name: "point1", attributeKey: "inputPoint1", userAttributeItems: [
                CIFilterAttributeItem(name: "inputPoint1.x", defaultValue: 0.25, minimumValue: 0, maximumValue: 1, offset: 0, canEdit: false),
                CIFilterAttributeItem(name: "inputPoint1.y", defaultValue: 0.25, minimumValue: 0, maximumValue: 1, offset: 1)
                ]),
            CIAdjustmentSliderInfo(name: "point2", attributeKey: "inputPoint2", userAttributeItems: [
                CIFilterAttributeItem(name: "inputPoint2.x", defaultValue: 0.5, minimumValue: 0, maximumValue: 1, offset: 0, canEdit: false),
                CIFilterAttributeItem(name: "inputPoint2.y", defaultValue: 0.5, minimumValue: 0, maximumValue: 1, offset: 1)
                ]),
            CIAdjustmentSliderInfo(name: "point3", attributeKey: "inputPoint3", userAttributeItems: [
                CIFilterAttributeItem(name: "inputPoint3.x", defaultValue: 0.75, minimumValue: 0, maximumValue: 1, offset: 0, canEdit: false),
                CIFilterAttributeItem(name: "inputPoint3.y", defaultValue: 0.75, minimumValue: 0, maximumValue: 1, offset: 1)
                ]),
            CIAdjustmentSliderInfo(name: "point4", attributeKey: "inputPoint4", userAttributeItems: [
                CIFilterAttributeItem(name: "inputPoint4.x", defaultValue: 1, minimumValue: 0, maximumValue: 1, offset: 0, canEdit: false),
                CIFilterAttributeItem(name: "inputPoint4.y", defaultValue: 1, minimumValue: 0, maximumValue: 1, offset: 1)
                ])
        ]
    }
}

fileprivate class CIColorFilterGroup: CIFilterGroup<CIAdjustmentFilter> {
    var filterAttributes: [CIFilterAttributes] {
        return filters.map { $0.filterAttributes.values }.reduce([], +)
    }
}

class _ColorEditorAsset: _FiltersAppAsset {}

struct ColorEditorResultItem: AppTaskResultable {
    var asset: PHAsset
    var result: [PHAssetEditingResultItem]?
    
    init(asset: PHAsset, result: [PHAssetEditingResultItem]?) {
        self.asset = asset
        self.result = result
    }
}

public class ColorEditorValue: ImageEditStateValue {}

private class ColorEditorTask: AppTaskPrototype, AppTaskable {
    public typealias ParamType = _ColorEditorAsset
    public typealias ResultType = PHAssetResultItem
    
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){
        
        (param as? _ColorEditorAsset)?.cancelAllRequestIDs()
        (param as? _ColorEditorAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _ColorEditorAsset, "TaskParamable type of this app is \(_ColorEditorAsset.self)")
        guard let _param = param as? _ColorEditorAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _ColorEditorAsset, _ async: AsyncWaitSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
//        async.begin()
//
//        DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
//            assetItem.runEditing({ (progress) in
//                AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
//            }) { (asset, editingResultItems, contentEditingOutput) in
//                if let asset = asset, let contentEditingOutput = contentEditingOutput {
//                    let adjustments = (assetItem.editState.ciFilter as? CIFilterGroup)?.filters.map({ $0.adjustmentItems.values }).reduce([], +) ?? []
//
//                    var editInfo: [String: Any] = [:]
//                    if let jsonData = try? JSONEncoder().encode(adjustments), let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? Array<Any> {
//                        editInfo["adjustments"] = json
//                    }
//
//                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: AdjustmentsApp.self, editInfo: editInfo, from: asset)
//
//                    result = PHAssetResultItem(
//                        asset: assetItem,
//                        editingResultItems: editingResultItems,
//                        contentEditingOutput: contentEditingOutput)
//                }
//                async.end()
//            }
//        }
//
//        async.waitUntilEnd()
        return result
    }
}

class ColorEditorDockContent: NSObject, PropertyWatchable, AppDockContent, AppDockDelegate, UITableViewDelegate, UITableViewDataSource {
    lazy var view: UIView = {
        let view = UITableView(frame: .zero)
        view.dataSource = self
        view.delegate = self
        view.rowHeight = UITableView.automaticDimension
        view.estimatedRowHeight = 52
        view.allowsSelection = false
        view.register(CIAdjustmentSliderCell.self, forCellReuseIdentifier: AdjustmentsApp.info.identifier + "\(CIAdjustmentSliderCell.self)")
        view.backgroundColor = .clear
        view.separatorStyle = .none
        return view
    }()
    
    var preferences: AppDockContentPreferable? {
        guard let tableView = view as? UITableView else{
            return nil
        }
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = tableView.estimatedRowHeight * 5
        return preferences
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        
    }
    
    func didSetContentView(_ view:UIView, dock:AppDock) {
        view.tintColor = view.colorTheme.tintColor
        
        if colorFilters.isEmpty {
            installFilters()
        }
        
        (view as? UITableView)?.reloadData()
    }
    
    @objc dynamic var filter: CIFilter?
    
    fileprivate var colorFilters = [CIAdjustmentFilter]()
    
    private func installFilters(with filters: [CIAdjustmentFilter]? = nil) {
//        filterManager.setAdjustmentFilters(filters)
        colorFilters.removeAll()
        
        colorFilters = [CIToneCurveFilter()]
        
        
//        for adjustmentFilter in filterManager.filters {
//            for adjustmentItem in adjustmentFilter.filterAttributes {
//                for attributeItem in adjustmentItem.value.attributeItems {
//                    guard let name = Adjustments.Name(rawValue: attributeItem.name), self.orderedAdjustments.contains(name) else { continue }
//                    attributeItems.append(attributeItem)
//                }
//            }
//        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return colorFilters.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colorFilters[safe: section]?.sliderInfoItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AdjustmentsApp.info.identifier + "\(CIAdjustmentSliderCell.self)") as! CIAdjustmentSliderCell
        
        let filter = colorFilters[indexPath.section]
        
        guard let sliderInfo = filter.sliderInfoItems?[indexPath.item], let attributeItem = sliderInfo.userAttributeItems?.first(where: { $0.canEdit }) else { return cell }
        
        cell.titleLabel.text = sliderInfo.name
        
        cell.highlightedColor = AdjustmentsApp.info.themeColor
        
        cell.slider.minimumValue = attributeItem.minimumValue
        cell.slider.maximumValue = attributeItem.maximumValue
        cell.slider.defaultValue = attributeItem.defaultValue
        cell.slider.value = attributeItem.value
        
        cell.resetButton.isHidden = !attributeItem.hasChanges
        cell.resetButtonDidTapHandler = {
            attributeItem.value = attributeItem.defaultValue
            cell.resetButton.isHidden = !attributeItem.hasChanges
            
            cell.slider.value = attributeItem.value
            
//            self.markAsSelectedFilterAttribiutes((self.filter as? CIAdjustmentFilterGroup)?.filterAttributes)
            self.filter = CIColorFilterGroup(filters: self.colorFilters)
        }
        
        cell.sliderDidChangeHandler = { value in
            attributeItem.value = value
            
            cell.resetButton.isHidden = !attributeItem.hasChanges
            
            DispatchQueue.main.async {
                self.filter = CIColorFilterGroup(filters: self.colorFilters)
            }
        }
        
        cell.sliderDidEndHandler = {
//            let filter = self.filterManager.ciFilter
//            self.markAsSelectedFilterAttribiutes(filter.filterAttributes)
            self.filter = CIColorFilterGroup(filters: self.colorFilters)
        }
        
        return cell
    }
    
//    private func markAsSelectedFilterAttribiutes(_ filterAttributes: [CIFilterAttributes]?) {
//        guard let filterAttributes = filterAttributes else { return }
//        self.app?.registerUndo(filterAttributes.compactMap({ $0.copy() as? CIFilterAttributes }))
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
