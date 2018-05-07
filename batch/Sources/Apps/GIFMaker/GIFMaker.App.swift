//
//  GIFMaker.App.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 23..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Photos
import DefaultsKit
import MobileCoreServices

//INFO: feature reference: https://ezgif.com

class _GIFMakerAppAsset: PHAssetItem<ImageEditStateValue> {
    func cancelProcessing() {

    }
}

private struct GIFMakerCachedAsset {
    public var asset: PHAsset
    public var imageFileURL: URL
    
    static func cacheAsset(_ asset: PHAsset, image: UIImage, targetSize: CGSize, uti: String) -> GIFMakerCachedAsset {
        let imageToWrite: UIImage
        if targetSize == image.size {
            imageToWrite = image
        }
        else {
            imageToWrite = UIGraphicsImageRenderer(size: targetSize, format: image.imageRendererFormat).imageWithCurrentContext { (cgContext) in
                UIColor.white.setFill()
                cgContext.fill(CGRect(origin: .zero, size: targetSize))
                image.draw(in: AVMakeRect(aspectRatio: image.size, insideRect: CGRect(origin: .zero, size: targetSize)))
            } ?? image
        }
        
        var data: Data?
        var fileExtension = "jpg"
        switch uti{
            case UTCoreTypes.PNG:
                data = UIImagePNGRepresentation(imageToWrite)
                fileExtension = "png"
            default:
                data = UIImageJPEGRepresentation(imageToWrite, CGFloat((GIFMaker.defaults as! GIFMakerDefaults).gifQuality))
        }
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(GIFMaker.info.identifier)_\(UUID().uuidString).\(fileExtension)")
        try? data?.write(to: url)
        
        return GIFMakerCachedAsset(asset: asset, imageFileURL: url)
    }
}

private struct GIFMakerPHAssetResult: TaskResultable{
    public var items: [GIFMakerCachedAsset]
}

//MARK: -

protocol GIFMakerDefaults: AppDefaults{
    var sourceType: Int {get set}
    var aspectRatio: Double {get set}
    var contentMode: Int {get set}
    var frameDelay: Int {get set}
    var size: Double {get set}
    var direction: Int {get set}
    var gifQuality: Double {get set}
    var loopCount: Int {get set}
}

extension Defaults: GIFMakerDefaults {
    var sourceType: Int {
        set { set(newValue) }
        get { return get(or: 0) }
    }
    
    var aspectRatio: Double {
        set{ set(newValue) }
        get{ return get(or: 1) }
    }
    
    var contentMode: Int {
        set{ set(newValue) }
        get{ return get(or: PHImageContentMode.aspectFill.rawValue ) }
    }
    
    var frameDelay: Int {
        set { set(newValue) }
        get { return get(or: 300)}
    }
    
    var size: Double {
        set{ set(newValue) }
        get{ return get(or: 640 ) }
    }
    
    var direction: Int {
        set { set(newValue) }
        get { return get(or: 0) }
    }
    
    var gifQuality: Double {
        set{ set(newValue) }
        get{ return get(or: 0.8) }
    }
    
    var loopCount: Int {
        set { set(newValue) }
        get { return get(or: 0)}
    }
}

struct GIFMakerSettings {
    struct sourceType {
        enum type: Int {
            case photo
            case burst
            case video
        }
        
        static let labels: [type: String] = [
            .photo: "Photos".localized,
            .burst: "Burst".localized,
            .video: "Video".localized
        ]
        
        static let orderedLabels: [String?] = [
            labels[.photo],
            labels[.burst],
//            labels[.video]
        ]
        
        static func key(with value: String) -> Int {
            return (labels.first(where: { value == $0.value })?.key ?? .photo).rawValue
        }
    }
    
    struct aspectRatio {
        struct labels {
            static let square = "Square".localized
            static let w4h3 = "4:3"
            static let w16h9 = "16:9"
            static let w3h4 = "3:4"
            static let w9h16 = "9:16"
        }
        
        static let values: [String: Double] = [
            labels.square: 1.0,
            labels.w3h4: 3.0 / 4.0,
            labels.w9h16: 9.0 / 16.0,
            labels.w4h3: 4.0 / 3.0,
            labels.w16h9: 16.0 / 9.0
        ]
        
        static let orderedLabels: [String] = [
            labels.w9h16,
            labels.w3h4,
            labels.square,
            labels.w4h3,
            labels.w16h9
        ]
        
        static func value(_ key: String) -> Double {
            return values[key] ?? 1.0
        }
    }
    
    struct contentMode {
        static let fit = PHImageContentMode.aspectFit.rawValue
        static let fill = PHImageContentMode.aspectFill.rawValue
        
        static let labels: [Int: String] = [
            PHImageContentMode.aspectFit.rawValue: "No Crop".localized,
            PHImageContentMode.aspectFill.rawValue: "Crop".localized
        ]
        
        static let orderedLabels: [String?] = [
            labels[PHImageContentMode.aspectFill.rawValue],
            labels[PHImageContentMode.aspectFit.rawValue],
        ]
        
        static func key(with value: String) -> Int {
            return labels.first(where: { value == $0.value })?.key ?? PHImageContentMode.aspectFill.rawValue
        }
    }
    
    // https://en.wikipedia.org/wiki/Graphics_display_resolution
    struct size {
        struct labels {
            static let nhd = "nHD".localized
            static let qhd = "qHD".localized
            static let hd = "HD".localized
            static let fhd = "FHD".localized
        }
        
        static let values: [String: Double] = [
            labels.nhd: 640,
            labels.qhd: 960,
            labels.hd: 1280,
            labels.fhd: 1920
        ]
        
        static let orderedLabels: [String] = [
            labels.nhd,
            labels.qhd,
            labels.hd,
            labels.fhd,
        ]
        
        static func value(_ key: String) -> Double {
            return values[key] ?? 960
        }
        
        static func sizeWithAspectRatio() -> CGSize {
            let size = (GIFMaker.defaults as! GIFMakerDefaults).size
            let aspectRatio = (GIFMaker.defaults as! GIFMakerDefaults).aspectRatio
            if aspectRatio < 1 {
                return CGSize(width: Int(size * aspectRatio), height: Int(size))
            }
            else {
                return CGSize(width: Int(size), height: Int(size / aspectRatio))
            }
        }
    }
    
    struct direction {
        enum type: Int {
            case forward
            case reverse
            case forwardAndReverse
        }
        
        static let labels: [type: String] = [
            .forward: "Forward".localized,
            .reverse: "Reverse".localized,
            .forwardAndReverse: "Forward & Reverse".localized
        ]
        
        static let orderedLabels: [String?] = [
            labels[.forward],
            labels[.reverse],
            labels[.forwardAndReverse]
        ]
        
        static func key(with value: String) -> Int {
            return (labels.first(where: { value == $0.value })?.key ?? .forward).rawValue
        }
    }
}

//MARK: -

public class GIFMakerAppConfig: NSObject, KeyPathWatchable, AppConfigUIAttrributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?

    @objc dynamic
    public var sourceType: Int = Int.max
    
    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttrributeValuable {
            self.tintColor = other.tintColor
        }
    }
}

public class GIFMaker: BApp, ConfigurableApp, _ConfigurableApp,
    AppDockControllableApp, PHAssetFinalizableApp, PhotoPickerCollectionViewDisplayableApp,
PhotoPickerViewControllerDelegatableApp, FinalizableApp {
    public static let taskType:Taskable.Type = _GIFMakerAppTask.self
    public static let paramType:TaskParamable.Type = _GIFMakerAppAsset.self
    
    public static var configure:(() -> GIFMakerAppConfig)?
    
    @objc dynamic
    public private(set) lazy var config: GIFMakerAppConfig? = GIFMaker.configure?()
    public private(set) lazy var dockContent: AppDockContent? = GIFMakerAppDockContent()
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.gifmaker"
        , version: "1.0"
        , phase: .release
        , appType: GIFMaker.self
        , displayName: "GIF Maker"
        , icon: R.image.photosFilterAppIcon.name
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    required public init() {}
    
    public var doneButtonTitle: String? {
        return "Make GIF".localized
    }
    
    public func shouldSelect(item: PHAssetItem<ImageEditStateValue>) -> Bool {
        return (dockContent as? GIFMakerAppDockContent)?.shouldImport(asset: item.asset) ?? false
    }
    
    public var numberOfItemsShouldSelect: Int? {
        switch GIFMakerSettings.sourceType.type(rawValue: (GIFMaker.defaults as! GIFMakerDefaults).sourceType) {
        case .photo?: return Int.max
        case .burst?: return Int.max
        default: return Int.max
        }
    }
    
    public var finalizingPresets: [PHAssetFinalizingPresets]? {
        return nil
    }
    
    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
    }
    
    public func shouldFinalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> Bool {
        return true
    }
    
    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        let resultItems = result
            .filter { respondable in respondable.info.state == .completed }
            .compactMap { ($0.result as? GIFMakerPHAssetResult)?.items }.reduce([], +)
        
        let frameDelay = Double((GIFMaker.defaults as! GIFMakerDefaults).frameDelay) / 1000.0
        let loopCount = (GIFMaker.defaults as! GIFMakerDefaults).loopCount
        var imageFiles = resultItems.map({ $0.imageFileURL })
        if imageFiles.count > 1 {
            switch GIFMakerSettings.direction.type(rawValue: (GIFMaker.defaults as! GIFMakerDefaults).direction) {
            case .reverse?: imageFiles.reverse()
            case .forwardAndReverse?: imageFiles.append(contentsOf: imageFiles[1...].reversed()[1...])
            default: break
            }
        }

        let gifData = UIImageGIFRepresentation(with:imageFiles, loopCount:loopCount, frameDelay:frameDelay)
        
        asyncSignal.begin()
        
        DispatchQueue.main.async {
            guard let data = gifData, let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { return }
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [data], applicationActivities: nil)
            activityViewController.completionWithItemsHandler = { (activityType:UIActivityType?, completed:Bool, returnedItems:[Any]?, activityError:Error?) in
                asyncSignal.end()
            }
            activityViewController.popoverPresentationController?.sourceView=rootViewController.view
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
        
        asyncSignal.waitUntilEnd()
        
        return result
    }
}

private class _GIFMakerAppTask: TaskPrototype, Taskable {
    public typealias ParamType = _GIFMakerAppAsset
    public typealias ResultType = PHAssetResultItem
    
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){
        
        (param as? _GIFMakerAppAsset)?.cancelAllRequestIDs()
        (param as? _GIFMakerAppAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {
        guard let appAsset = param as? AppAsset else { return nil }
        return try _perform(appAsset, async)
    }
    
    private func _perform(_ assetItem: AppAsset, _ async: AsyncManualSignalable) throws -> GIFMakerPHAssetResult?  {
        var result: GIFMakerPHAssetResult?
        
        let targetSize = GIFMakerSettings.size.sizeWithAspectRatio()
        let contentMode = PHImageContentMode(rawValue: (GIFMaker.defaults as! GIFMakerDefaults).contentMode) ?? PHImageContentMode.aspectFit
        
        async.begin()
        
        if assetItem.asset.mediaType == .video {
            async.end()
        }
        else if assetItem.asset.imageType == .stillImage {
            let response = assetItem.asset.requestImage(targetSize: targetSize, contentMode: contentMode)
            
            if let image = response.1, let uti = assetItem.asset.uniformTypeIdentifier {
                result = GIFMakerPHAssetResult(items: [GIFMakerCachedAsset.cacheAsset(assetItem.asset, image: image, targetSize: targetSize, uti: uti)])
                assetItem.requestIDs += [PHAssetRequestID(forImage:response.0)]
            }
            
            async.end()
        }
        else if assetItem.asset.imageType == .burst {
            var results = [GIFMakerCachedAsset]()
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.includeAllBurstAssets = true
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            
            let fetchedAsset = PHAsset.fetchAssets(withBurstIdentifier: assetItem.asset.burstIdentifier ?? "", options: fetchOptions)
            fetchedAsset.enumerateObjects { (asset, idx, stop) in
                let response = asset.requestImage(targetSize: targetSize, contentMode: contentMode)
                if let image = response.1, let uti = assetItem.asset.uniformTypeIdentifier {
                    results.append(GIFMakerCachedAsset.cacheAsset(assetItem.asset, image: image, targetSize: targetSize, uti: uti))
                    assetItem.requestIDs += [PHAssetRequestID(forImage:response.0)]
                }
            }
            
            result = GIFMakerPHAssetResult(items: results)
            
            async.end()
        }
        else if assetItem.asset.imageType == .livePhoto {
            async.end()
        }
        
        async.waitUntilEnd()
        return result
    }
}

private enum Cells {
    case sourceType
    case export
    case contentMode
    case aspectRatio
    case size
    case frameDelay
    case direction
    case gifQuality
    case loopCount
}

class GIFMakerAppDockContent: NSObject, KeyPathWatchable, AppDockContent, AppDockDelegate,
        UITableViewDelegate, UITableViewDataSource, UITableViewPickerCellDelegate {

    private var defaults = GIFMaker.defaults as! GIFMakerDefaults
    
    lazy var view: UIView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tintColor = UIColor(red: 255 / 255.0, green: 0 / 255.0, blue: 170 / 255.0, alpha: 1)
        return tableView
    }()
    
    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.minimumHeight = (self.view as! UITableView).rowHeight * 4 + 27
        preferences.pinned = false
        return preferences
    }
    
    func shouldImport(asset: PHAsset) -> Bool {
        switch GIFMakerSettings.sourceType.type(rawValue: defaults.sourceType) {
        case .photo?: return asset.imageType == .stillImage
        case .burst?: return asset.imageType == .burst
        default: return false
        }
    }
    
    var appDock:AppDock?
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        appDock = dock

        if sections.count==0{
            let cellDescribers = createCellDescribers()

            if let view = view as? UITableView{
                view.dataSource = self
                view.delegate = self
                view.rowHeight = 44

                for item in cellDescribers {
                    view.register(describer: item)
                }
            }
        }
    }
    
    private var sections = [(String, [UITableViewCellDefaultDescribable])]()

    private func createCellDescribers() -> [UITableViewCellDefaultDescribable] {
        var cellDescribers = [UITableViewCellDefaultDescribable]()
        
        let sourceTypeCell = UITableViewSegmentControlCellDescriber()
        sourceTypeCell.itemIdentifier = Cells.sourceType.hashValue
        sourceTypeCell.label = "Import".localized
        sourceTypeCell.valueGetter = { GIFMakerSettings.sourceType.labels[GIFMakerSettings.sourceType.type(rawValue: self.defaults.sourceType) ?? .photo] }
        sourceTypeCell.valueCollection = GIFMakerSettings.sourceType.orderedLabels
        sourceTypeCell.valueHandler = {
            if let index = $0 as? Int {
                let key = GIFMakerSettings.sourceType.key(with: GIFMakerSettings.sourceType.orderedLabels[index] ?? "")
                self.defaults.sourceType = key
                AppCenter.default.currentInstanceAs(GIFMaker.self)?.config?.sourceType = key
            }
        }
        cellDescribers.append(sourceTypeCell)
        
        let exportCell = UITableViewSegmentControlCellDescriber()
        exportCell.itemIdentifier = Cells.export.hashValue
        exportCell.label = "Export".localized
        exportCell.valueGetter = { "Animated GIF" }
        exportCell.valueCollection = ["Animated GIF"]
        cellDescribers.append(exportCell)
        
        let cell0 = UITableViewActionSheetCellDescriber()
        cell0.itemIdentifier = Cells.size.hashValue
        cell0.label = "Size".localized
        cell0.valueGetter =  {
            GIFMakerSettings.size.values.first(where: { $0.value == self.defaults.size })?.key
        }
        cell0.valueCollection = GIFMakerSettings.size.orderedLabels
        cell0.valueHandler = { value in
            if let key = value as? String, let sizeValue = GIFMakerSettings.size.values[key]{
                self.defaults.size = sizeValue
                
                guard let indexPath = self.indexPath(with: cell0.itemIdentifier) else { return }
                (self.view as? UITableView)?.reloadRows(at: [indexPath], with: .none)
            }
        }
        cellDescribers.append(cell0)

        let cell1 = UITableViewActionSheetCellDescriber()
        cell1.itemIdentifier = Cells.aspectRatio.hashValue
        cell1.label = "Aspect Ratio".localized
        cell1.valueGetter =  {
            GIFMakerSettings.aspectRatio.values.first(where: { $0.value == self.defaults.aspectRatio })?.key
        }
        cell1.valueCollection = GIFMakerSettings.aspectRatio.orderedLabels
        cell1.valueHandler = { value in
            if let key = value as? String, let sizeValue = GIFMakerSettings.aspectRatio.values[key]{
                self.defaults.aspectRatio = sizeValue
            }
        }
        cellDescribers.append(cell1)

        let cell2 = UITableViewSegmentControlCellDescriber()
        cell2.itemIdentifier = Cells.contentMode.hashValue
        cell2.label = "Crop to Fit".localized
        cell2.valueGetter = { GIFMakerSettings.contentMode.labels[self.defaults.contentMode] }
        cell2.valueCollection = GIFMakerSettings.contentMode.orderedLabels
        cell2.valueHandler = {
            if let index = $0 as? Int {
                let key = GIFMakerSettings.contentMode.key(with: GIFMakerSettings.contentMode.orderedLabels[index] ?? "")
                self.defaults.contentMode = key
            }
        }
        cellDescribers.append(cell2)


        let cell3 =  UITableViewStepperCellDescriber()
        cell3.label = "Frame Delay".localized
        cell3.itemIdentifier = Cells.frameDelay.hashValue
        cell3.valueGetter = { self.defaults.frameDelay }
        cell3.valueHandler = {
            self.defaults.frameDelay = Int($0 as? Double ?? 300)
            self.updateFrameDelayPreview()
        }
        cell3.minimumValue = 50
        cell3.maximumValue = 3000
        cell3.stepValue = 50
        cell3.valuePresenter = { value in
            var label:String?
            if let val = value as? Double {
                label = String(format: "%.02f", val / 1000)
            }
            else if let val = value as? Int {
                label = String(format: "%.02f", Double(val) / 1000)
            }
            return (label ?? "-")+"s"
        }
        cellDescribers.append(cell3)
        
        let qualityCell =  UITableViewStepperCellDescriber()
        qualityCell.label = "Image Quality".localized
        qualityCell.itemIdentifier = Cells.gifQuality.hashValue
        qualityCell.valueGetter = { Int((self.defaults.gifQuality ) * 100) }
        qualityCell.valueHandler = {
            self.defaults.gifQuality = (($0 as? Double) ?? 1)/100
        }
        qualityCell.minimumValue = 10
        qualityCell.maximumValue = 100
        qualityCell.stepValue = 10
        qualityCell.valuePresenter = UITableViewStepperCellDescriber.percentageAsIntValuePresenter
        cellDescribers.append(qualityCell)
        
        let directionCell = UITableViewActionSheetCellDescriber()
        directionCell.itemIdentifier = Cells.direction.hashValue
        directionCell.label = "Direction".localized
        directionCell.valueGetter = {
            GIFMakerSettings.direction.labels[GIFMakerSettings.direction.type(rawValue: self.defaults.direction) ?? .forward]
        }
        directionCell.valueCollection = GIFMakerSettings.direction.orderedLabels
        directionCell.valueHandler = {
            if let value = $0 as? String {
                self.defaults.direction = GIFMakerSettings.direction.key(with: value)
            }
        }
        cellDescribers.append(directionCell)
        
        let loopCell =  UITableViewStepperCellDescriber()
        loopCell.label = "Repeat".localized
        loopCell.itemIdentifier = Cells.loopCount.hashValue
        loopCell.valueGetter = { self.defaults.loopCount }
        loopCell.valueHandler = { self.defaults.loopCount = Int($0 as? Double ?? 0) }
        loopCell.minimumValue = 0
        loopCell.maximumValue = 100
        loopCell.stepValue = 1
        loopCell.valuePresenter = { value in
            var count = 0
            if let val = value as? Int {
                count = val
            }
            else if let val = value as? Double {
                count = Int(val)
            }
            
            if count > 0 {
                if count == 1 {
                    return "No loop".localized
                }
                else {
                    return "\(count) \("times".localized)"
                }
            }
            else {
                return "Loop".localized
            }
        }
        cellDescribers.append(loopCell)
        
        sections.append(("GIF Maker".localized, [sourceTypeCell, exportCell]))
        sections.append(("Quality".localized, [cell0, cell1, qualityCell, cell2]))
        sections.append(("Animation".localized, [cell3, directionCell, loopCell]))

        return cellDescribers
    }

    var delegate: AppDockDelegate? {
        return self
    }

    func dockWillContract(_ dock: AppDock) {
        (self.view as? UITableView)?.contractAllVisiblePickerCells()
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {
        (view as! UITableView).reloadData()
        updateFrameDelayPreview()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].1.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = tableView.cellForRow(at: indexPath)
        
        if let c = cell as? UITableViewPickerCell {
            return c.estimatedHeightForRowSelected
        }
        return tableView.rowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = tableView.cellForRow(at: indexPath) as? UITableViewPickerCell {
            if cell.isExpanded {
                cell.contract(tableView)
            } else{
                tableView.contractAllVisiblePickerCells()
                
                appDock?.expandDockIfNeeded(reloadContents: nil)
                DispatchQueue.main.async{
                    cell.expand(tableView)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.sections[indexPath.section].1[indexPath.item]

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
            
            if item.itemIdentifier == Cells.size.hashValue {
                let size = GIFMakerSettings.size.sizeWithAspectRatio()
                cell.titleLabel.text = "\("Size".localized) (\(Int(size.width)) x \(Int(size.height)))"
            }
            else {
                cell.titleLabel.text = item.label
            }
            return cell
        }
        else if let cellDescriber = item as? UITableViewActionSheetCellDescriber
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewActionSheetCell {

            if item.itemIdentifier == Cells.size.hashValue {
                let size = GIFMakerSettings.size.sizeWithAspectRatio()
                cell.textLabel?.text = "\("Size".localized) (\(Int(size.width)) x \(Int(size.height)))"
            }
            else {
                cell.textLabel?.text = item.label
            }

            cell.valueLabelText = cellDescriber.presentableValue
            cell.imageView?.image = cellDescriber.iconImage?.asUIImage
            cell.detailTextLabel?.textColor = UIColor.gray

            // valueCollection -> [String]
            if let collection = cellDescriber.valueCollection as? [String]{
                cell.valueLabels = collection
                cell.valueSelected = { action, index in
                    if let index = index{
                        cellDescriber.valueHandler?(collection[index])
                    }
                }
            }

            return cell
        }
        else if let cellDescriber = item as? UITableViewSegmentControlCellDescriber
            , let valueCollection = cellDescriber.valueCollection as? [String]
            , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSegmentedControlCell {

            cell.textLabel?.text = item.label
            cell.imageView?.image = item.iconImage?.asUIImage
            cell.detailTextLabel?.textColor = UIColor.gray
            
            cell.segmentedControl.width = 140
            cell.segmentedControl.removeAllSegments()
            for k in valueCollection{
                cell.segmentedControl.insertSegment(withTitle: k, at: cell.segmentedControl.numberOfSegments, animated: false)
            }
            
            if let label = item.valueGetter() as? String {
                cell.segmentedControl.selectedSegmentIndex = valueCollection.index(of: label) ?? 0
            }
            cell.didChangeValue = item.valueHandler
            return cell
        }
        else if let cellDescriber = item as? UITableViewStepperCellDescriber
            , let value = item.valueGetter() as? Int
            , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewStepperCell {
            
            cell.textLabel?.text = item.label
            cell.detailTextLabel?.text = cellDescriber.valuePresenter?(value)
            cell.imageView?.image = item.iconImage?.asUIImage
            
            cell.stepper.stepValue = cellDescriber.stepValue
            cell.stepper.minimumValue = cellDescriber.minimumValue
            cell.stepper.maximumValue = cellDescriber.maximumValue
            cell.stepper.value = Double(value)
            
            cell.textLabel?.isEnabled = true
            cell.detailTextLabel?.isEnabled = true
            cell.stepper.isEnabled = true
            cell.stepper.tintColor = self.view.tintColor
            cell.isUserInteractionEnabled = true
            
            cell.didChangeValue = { value in
                cell.detailTextLabel?.text = cellDescriber.valuePresenter?(value)
                item.valueHandler?(value)
            }

            if item.itemIdentifier == Cells.frameDelay.hashValue {
                updateFrameDelayPreview(cell:cell)
            }
            
            return cell
        }
        else {
            return UITableViewCell()
        }
    }
    
    private func indexPath(with itemIdentifier: Int) -> IndexPath? {
        return sections.enumerated().compactMap({ (idx, section) -> IndexPath? in
            guard let row = section.1.index(where: { (describer) -> Bool in
                describer.itemIdentifier == itemIdentifier
            }), row != NSNotFound else { return nil }
            return IndexPath(row: row, section: idx)
        }).first
    }
    
    private func updateFrameDelayPreview(cell:UITableViewStepperCell?=nil) {
        guard let indexPath = indexPath(with: Cells.frameDelay.hashValue) else { return }
        let cell = cell ?? (view as! UITableView).cellForRow(at: indexPath)
        
        let frames = 8

        let durationNeeded = TimeInterval(frames * self.defaults.frameDelay) / 1000

        if let imageView = cell?.imageView, imageView.image?.duration != durationNeeded {

            let images = [ // already cached by main bundle.
                R.image.exifmaker_preview_frame_0()!,
                R.image.exifmaker_preview_frame_1()!,
                R.image.exifmaker_preview_frame_2()!,
                R.image.exifmaker_preview_frame_3()!,
                R.image.exifmaker_preview_frame_4()!,
                R.image.exifmaker_preview_frame_5()!,
                R.image.exifmaker_preview_frame_6()!,
                R.image.exifmaker_preview_frame_7()!
            ]
            assert(images.count == frames)
            imageView.image = UIImage.animatedImage(with: images, duration: durationNeeded)
        }

        cell?.imageView?.startAnimating()
        cell?.setNeedsLayout()
    }
    
    func pickerCell(_ cell: UITableViewPickerCell, didPick row: Int, value: Any) {
        guard let indexPath = (view as! UITableView).indexPath(for: cell) else { return }
        let setting = sections[indexPath.section].1[indexPath.row]
        
        var needsToUpdateSizeCell = false

        if setting.itemIdentifier == Cells.aspectRatio.hashValue {
            defaults.aspectRatio = GIFMakerSettings.aspectRatio.values[cell.values[row]] ?? GIFMakerSettings.aspectRatio.value(GIFMakerSettings.aspectRatio.labels.square)
            
            needsToUpdateSizeCell = true
            
        }
        else if setting.itemIdentifier == Cells.size.hashValue {
            defaults.size = GIFMakerSettings.size.values[cell.values[row]] ?? GIFMakerSettings.size.value(GIFMakerSettings.size.labels.qhd)
            
            needsToUpdateSizeCell = true
        }
        
        if needsToUpdateSizeCell, let indexPathOfSizeSetting = self.indexPath(with: Cells.size.hashValue) {
            let sizeCell = (view as! UITableView).cellForRow(at: indexPathOfSizeSetting) as? UITableViewPickerCell
            
            let size = GIFMakerSettings.size.sizeWithAspectRatio()
            sizeCell?.titleLabel.text = "\("Size".localized) (\(Int(size.width)) x \(Int(size.height)))"
        }
    }
}
