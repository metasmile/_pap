//
//  GIFMaker.App.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 23..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Photos
import NSGIF2
import DefaultsKit

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
            imageToWrite = UIGraphicsImageRenderer(size: targetSize).image(actions: { (ctx) in
                UIColor.white.setFill()
                ctx.cgContext.fill(CGRect(origin: .zero, size: targetSize))
                image.draw(at: CGPoint(x: (targetSize.width - image.size.width) / 2, y: (targetSize.height - image.size.height) / 2))
            })
        }
        
        let data: Data?
        var fileExtension = "jpg"
        switch uti as CFString {
        case kUTTypePNG:
            data = UIImagePNGRepresentation(imageToWrite)
            fileExtension = "png"
        default:
            data = UIImageJPEGRepresentation(imageToWrite, 1)
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
    var aspectRatio: Double {get set}
    var contentMode: Int {get set}
    var frameDelay: Int {get set}
    var size: Double {get set}
}

extension Defaults: GIFMakerDefaults {
    var aspectRatio: Double {
        set{ set(newValue) }
        get{ return get(or: 1 ) }
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
}

struct GIFMakerSettings {
    struct aspectRatio {
        struct keys {
            static let square = "Square"
            static let w4h3 = "4:3"
            static let w16h9 = "16:9"
            static let w3h4 = "3:4"
            static let w9h16 = "9:16"
        }
        
        static let values: [String: Double] = [
            keys.square: 1.0,
            keys.w3h4: 3.0 / 4.0,
            keys.w9h16: 9.0 / 16.0,
            keys.w4h3: 4.0 / 3.0,
            keys.w16h9: 16.0 / 9.0
        ]
        
        static let orderedKeys: [String] = [
            keys.w9h16,
            keys.w3h4,
            keys.square,
            keys.w4h3,
            keys.w16h9
        ]
        
        static func value(_ key: String) -> Double {
            return values[key] ?? 1.0
        }
    }
    
    struct contentMode {
        static let fit = PHImageContentMode.aspectFit.rawValue
        static let fill = PHImageContentMode.aspectFill.rawValue
        static let values: [String: Int] = [
            "Crop": contentMode.fill,
            "No Crop": contentMode.fit
        ]
    }
    
    struct size {
        struct keys {
            static let large = "Large"
            static let medium = "Medium"
            static let small = "Small"
        }
        
        static let values: [String: Double] = [
            keys.large: 1920,
            keys.medium: 1280,
            keys.small: 640
        ]
        
        static let orderedKeys: [String] = [
            keys.small,
            keys.medium,
            keys.large
        ]
        
        static func value(_ key: String) -> Double {
            return values[key] ?? 1280
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
}

//MARK: -

public class GIFMakerAppConfig: NSObject, KeyPathWatchable, AppConfigUIAttrributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?
    
//    @objc dynamic
//    public var filter: AppValue?
    
    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttrributeValuable {
            self.tintColor = other.tintColor
        }
        
//        if let other = fromOther as? PhotosFilterAppConfig, let filter = other.filter{
//            self.filter = filter
//        }
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
    public private(set) lazy var controller: AppDockContent? = GIFMakerAppDockContent()
    
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
        return item.asset.imageType == .stillImage || item.asset.imageType == .burst
        
//        guard let firstItem = AppAssets.selected.at(unsafeIndex: 0) else { return true }
//        return firstItem.asset.mediaType == item.asset.mediaType
    }
    
    public var numberOfItemsShouldSelect: Int? {
        guard let firstItem = AppAssets.selected.at(unsafeIndex: 0) else { return Int.max }
        if firstItem.asset.mediaType == .video || firstItem.asset.imageType == .burst {
            return 1
        }
        else {
            return Int.max
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
        
        print(resultItems)
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(GIFMaker.info.identifier).gif")
        let frameDelay = Double((GIFMaker.defaults as! GIFMakerDefaults).frameDelay) / 1000.0
        let gifData = GIFactory.createGIF(with: resultItems.map({ $0.imageFileURL }), frameDelay: frameDelay, to: url)
        
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

private struct GIFactory {
    static func createGIF(with imageFiles: [URL], loopCount: Int = 0, frameDelay: Double, to url: URL) -> Data? {
        let fileProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: loopCount
            ]
        ]
        let frameProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: frameDelay,
                kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB
            ]
        ]
        
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, imageFiles.count, nil) else { return nil }
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
        
        for imageFile in imageFiles {
            autoreleasepool {
                guard let cgImage = UIImage(contentsOfFile: imageFile.path)?.cgImage else { return }
                CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
            }
        }
        
        var gifData: Data?
        if CGImageDestinationFinalize(destination) {
            gifData = try? Data(contentsOf: url)
        }
        
        imageFiles.forEach({ try? FileManager.default.removeItem(at: $0) })
        try? FileManager.default.removeItem(at: url)
        
        return gifData
    }
}

private class _GIFMakerAppTask: TaskPrototype, Taskable {
    public typealias ParamType = _GIFMakerAppAsset
    public typealias ResultType = PHAssetResultItem
    
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable?){
        
        (param as? _GIFMakerAppAsset)?.cancelAllRequestIDs()
        (param as? _GIFMakerAppAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable?) throws -> TaskResultable? {
        guard let appAsset = param as? AppAsset else { return nil }
        return try _perform(appAsset, async)
    }
    
    private func _perform(_ assetItem: AppAsset, _ async: AsyncManualSignalable?) throws -> GIFMakerPHAssetResult?  {
        var result: GIFMakerPHAssetResult?
        
        let targetSize = GIFMakerSettings.size.sizeWithAspectRatio()
        let contentMode = PHImageContentMode(rawValue: (GIFMaker.defaults as! GIFMakerDefaults).contentMode) ?? PHImageContentMode.aspectFit
        
        async?.begin()
        
        if assetItem.asset.mediaType == .video {
            async?.end()
        }
        else if assetItem.asset.imageType == .stillImage {
            let response = assetItem.asset.requestImage(targetSize: targetSize, contentMode: contentMode)
            
            if let image = response.1, let uti = assetItem.asset.uniformTypeIdentifier {
                result = GIFMakerPHAssetResult(items: [GIFMakerCachedAsset.cacheAsset(assetItem.asset, image: image, targetSize: targetSize, uti: uti)])
                assetItem.requestIDs += [PHAssetRequestID(forImage:response.0)]
            }
            
            async?.end()
        }
        else if assetItem.asset.imageType == .burst {
            var results = [GIFMakerCachedAsset]()
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.includeAllBurstAssets = true
            
            let fetchedAsset = PHAsset.fetchAssets(withBurstIdentifier: assetItem.asset.burstIdentifier ?? "", options: fetchOptions)
            fetchedAsset.enumerateObjects { (asset, idx, stop) in
                let response = asset.requestImage(targetSize: targetSize, contentMode: contentMode)
                
                if let image = response.1, let uti = assetItem.asset.uniformTypeIdentifier {
                    results.append(GIFMakerCachedAsset.cacheAsset(assetItem.asset, image: image, targetSize: targetSize, uti: uti))
                    assetItem.requestIDs += [PHAssetRequestID(forImage:response.0)]
                }
            }
            
            result = GIFMakerPHAssetResult(items: results)
            
            async?.end()
        }
        else if assetItem.asset.imageType == .livePhoto {
            async?.end()
        }
        
        async?.waitUntilEnd()
        return result
    }
}

private enum Cells {
    case contentMode
    case aspectRatio
    case size
    case frameDelay
}

class GIFMakerAppDockContent: NSObject, KeyPathWatchable, AppDockContent, AppDockDelegate,
        UITableViewDelegate, UITableViewDataSource, UITableViewPickerCellDelegate {

    private var defaults = GIFMaker.defaults as! GIFMakerDefaults
    
    private var cellDescribers = [UITableViewCellDefaultDescribable]()
    
    lazy var view: UIView = UITableView()
    
    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.minimumHeight = (self.view as! UITableView).rowHeight * 4 + 27
        preferences.pinned = false
        return preferences
    }
    
    var appDock:AppDock?
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        appDock = dock

        if cellDescribers.count==0{
            cellDescribers = createCellDescribers()

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

    private func createCellDescribers() -> [UITableViewCellDefaultDescribable] {
        var cellDescribers = [UITableViewCellDefaultDescribable]()

        let cell0 = UITableViewSimpleValueCellDescriber()//UITableViewPickerCellDescriber()
        cell0.localIdentifier = Cells.size.hashValue
        cell0.label = "Size"
        cell0.valueGetter =  {
            GIFMakerSettings.size.values.first(where: { $0.value == self.defaults.size })?.key
        }
        cell0.valuePresenter = UITableViewSimpleValueCellDescriber.stringValuePresenter
//        cell0.valueCollection = GIFMakerSettings.size.orderedKeys
        cellDescribers.append(cell0)

        let cell1 = UITableViewPickerCellDescriber()
        cell1.localIdentifier = Cells.aspectRatio.hashValue
        cell1.label = "Aspect Ratio"
        cell1.valueGetter =  {
            GIFMakerSettings.aspectRatio.values.first(where: { $0.value == self.defaults.aspectRatio })?.key
        }
        cell1.valueCollection = GIFMakerSettings.aspectRatio.orderedKeys
        cellDescribers.append(cell1)


        let cell2 = UITableViewSegmentControlCellDescriber()
        cell2.localIdentifier = Cells.contentMode.hashValue
        cell2.label = "Crop to Fit"
        cell2.valueGetter = { self.defaults.contentMode }
        cell2.valueCollection = GIFMakerSettings.contentMode.values
        cell2.valueHandler = {
            self.defaults.contentMode = GIFMakerSettings.contentMode.values.valuesArray[$0 as? Int ?? 0]
        }
        cellDescribers.append(cell2)


        let cell3 =  UITableViewStepperCellDescriber()
        cell3.label = "Frame Delay"
        cell3.localIdentifier = Cells.frameDelay.hashValue
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "GIF Options"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellDescribers.count
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
        let item = self.cellDescribers[indexPath.item]

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
            
            if item.localIdentifier == Cells.size.hashValue {
                let size = GIFMakerSettings.size.sizeWithAspectRatio()
                cell.titleLabel.text = "Size (\(Int(size.width)) x \(Int(size.height)))"
            }
            else {
                cell.titleLabel.text = item.label
            }
            return cell
        }
        else if let cellDescriber = item as? UITableViewSimpleValueCellDescriber
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSimpleValueCell {

            if item.localIdentifier == Cells.size.hashValue {
                let size = GIFMakerSettings.size.sizeWithAspectRatio()
                cell.textLabel?.text = "Size (\(Int(size.width)) x \(Int(size.height)))"
            }
            else {
                cell.textLabel?.text = item.label
            }

            cell.valueLabel.text = cellDescriber.presentableValue
            cell.imageView?.image = cellDescriber.iconImage?.asUIImage
            cell.detailTextLabel?.textColor = UIColor.gray

            return cell
        }
        else if let cellDescriber = item as? UITableViewSegmentControlCellDescriber
            , let valueCollection = cellDescriber.valueCollection as? [String:Int]
            , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSegmentedControlCell {

            cell.textLabel?.text = item.label
            cell.imageView?.image = item.iconImage?.asUIImage
            cell.detailTextLabel?.textColor = UIColor.gray
            
            cell.segmentedControl.removeAllSegments()
            for k in valueCollection{
                cell.segmentedControl.insertSegment(withTitle: k.key, at: cell.segmentedControl.numberOfSegments, animated: false)
            }
            
            cell.segmentedControl.selectedSegmentIndex = valueCollection.valuesArray.index(of: item.valueGetter() as? Int ?? GIFMakerSettings.contentMode.fill) ?? 0
            cell.didChangeValue = item.valueHandler
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
            
            cell.textLabel?.isEnabled = true
            cell.detailTextLabel?.isEnabled = true
            cell.stepper.isEnabled = true
            cell.stepper.tintColor = self.view.tintColor
            cell.isUserInteractionEnabled = true
            
            cell.didChangeValue = { value in
                cell.detailTextLabel?.text = cellDescriber.valuePresenter?(value) ?? String(value)
                item.valueHandler?(value)
            }

            updateFrameDelayPreview(cell:cell)
            
            return cell
        }
        else {
            return UITableViewCell()
        }
    }
    
    private func updateFrameDelayPreview(cell:UITableViewStepperCell?=nil) {
        guard let row = cellDescribers.index(where: { $0.localIdentifier == Cells.frameDelay.hashValue }) else { return }
        let indexPath = IndexPath(row: row, section: 0)
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
        let setting = cellDescribers[indexPath.row]
        
        var needsToUpdateSizeCell = false

        if setting.localIdentifier == Cells.aspectRatio.hashValue {
            defaults.aspectRatio = GIFMakerSettings.aspectRatio.values[cell.values[row]] ?? GIFMakerSettings.aspectRatio.value(GIFMakerSettings.aspectRatio.keys.square)
            
            needsToUpdateSizeCell = true
            
        }
        else if setting.localIdentifier == Cells.size.hashValue {
            defaults.size = GIFMakerSettings.size.values[cell.values[row]] ?? GIFMakerSettings.size.value(GIFMakerSettings.size.keys.medium)
            
            needsToUpdateSizeCell = true
        }
        
        if needsToUpdateSizeCell, let rowOfSizeSetting = cellDescribers.index(where: { $0.localIdentifier == Cells.size.hashValue }) {
            let sizeCell = (view as! UITableView).cellForRow(at: IndexPath(row: rowOfSizeSetting, section: 0)) as? UITableViewPickerCell
            
            let size = GIFMakerSettings.size.sizeWithAspectRatio()
            sizeCell?.titleLabel.text = "Size (\(Int(size.width)) x \(Int(size.height)))"
        }
    }
}
