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

class _GIFMakerAppAsset: PHAssetItem<ImageEditStateValue> {
    func cancelProcessing() {
        
    }
}

private struct GIFMakerPHAssetResult: TaskResultable{
    public var asset: PHAsset
    public var imageFileURL: URL
}

//MARK: -

protocol GIFMakerDefaults: AppDefaults{
    var aspectRatio: Double {get set}
    var contentMode: Int {get set}
    var frameDelay: Double {get set}
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
    
    var frameDelay: Double {
        set { set(newValue) }
        get { return get(or: 0.3)}
    }
}

struct GIFMakerSettings {
    enum aspectRatio {
        static let labels: [String: Double] = [
            "Square": 1.0,
            "4:3": 3.0 / 4.0,
            "16:9": 9.0 / 16.0,
            "3:4": 4.0 / 3.0,
            "9:16": 16.0 / 9.0
        ]
    }
    
    enum contentMode {
        static let fit = PHImageContentMode.aspectFit.rawValue
        static let fill = PHImageContentMode.aspectFill.rawValue
        static let labels: [String: Int] = [
            "No Crop": contentMode.fit,
            "Crop": contentMode.fill
        ]
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

public class GIFMaker: BatchApp, ConfigurableApp, _ConfigurableApp,
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
        , version: "0.1"
        , phase: .beta
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
        return item.asset.imageType == .stillImage
        
//        guard let firstItem = AppAssets.selected.at(unsafeIndex: 0) else { return true }
//        return firstItem.asset.mediaType == item.asset.mediaType
    }
    
    public var numberOfItemsShouldSelect: Int? {
        guard let firstItem = AppAssets.selected.at(unsafeIndex: 0) else { return Int.max }
        if firstItem.asset.mediaType == .video || firstItem.asset.imageType != .stillImage {
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
            .compactMap { $0.result as? GIFMakerPHAssetResult }
        
        //TODO: test test
        
        func createGIF(with imageFiles: [URL], loopCount: Int = 0, frameDelay: Double) -> Data? {
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
            
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(GIFMaker.info.identifier).gif")
            
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
        
        let gifData = createGIF(with: resultItems.map({ $0.imageFileURL }), frameDelay: (GIFMaker.defaults as! GIFMakerDefaults).frameDelay )
        
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
    
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable?){
        
        (param as? _GIFMakerAppAsset)?.cancelAllRequestIDs()
        (param as? _GIFMakerAppAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable?) throws -> TaskResultable? {
        guard let appAsset = param as? AppAsset else { return nil }
        return try _perform(appAsset, async)
    }
    
    private func _perform(_ assetItem: AppAsset, _ async: AsyncManualSignalable?) throws -> TaskResultable?  {
        var result: GIFMakerPHAssetResult?
        
        //TODO: to be options
        let aspectRatio = (GIFMaker.defaults as! GIFMakerDefaults).aspectRatio
        let targetSize = CGSize(width: 640, height: 640 * aspectRatio)
        let contentMode = PHImageContentMode(rawValue: (GIFMaker.defaults as! GIFMakerDefaults).contentMode) ?? PHImageContentMode.aspectFit
        
        async?.begin()
        
        if assetItem.asset.mediaType == .video {
            
        }
        else if assetItem.asset.mediaType == .image {
            if assetItem.asset.mediaSubtypes.contains(.photoLive) {
               
            }
            else {
                let response = assetItem.asset.requestImage(targetSize: targetSize, contentMode: contentMode)
                
                if let image = response.1, let res = PHAssetResource.assetResources(for: assetItem.asset).first {
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
                    switch res.uniformTypeIdentifier as CFString {
                        case kUTTypePNG:
                            data = UIImagePNGRepresentation(imageToWrite)
                            fileExtension = "png"
                        default:
                            data = UIImageJPEGRepresentation(imageToWrite, 1)
                    }
                    
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(GIFMaker.info.identifier)_\(uuid).\(fileExtension)")
                    try data?.write(to: url)
                    
                    result = GIFMakerPHAssetResult(asset: assetItem.asset, imageFileURL: url)
                    assetItem.requestIDs += [PHAssetRequestID(forImage:response.0)]
                }
                
                async?.end()
            }
        }
        
        async?.waitUntilEnd()
        return result
    }
}

private struct SettingsItem {
    enum Keys {
        case contentMode
        case aspectRatio
    }
    
    fileprivate var key: Keys
    fileprivate var label:String
    fileprivate var valueGetter:() -> Any
    fileprivate var valueCollection:Any?
    fileprivate var valueHandler:((Any) -> ())?
    fileprivate var cellDescriber: UITableViewDescribable //INFO: it will integrate all properties later
    fileprivate var iconImageName:String?
}

class GIFMakerAppDockContent: NSObject, KeyPathWatchable, AppDockContent, AppDockDelegate,
        UITableViewDelegate, UITableViewDataSource, UITableViewPickerCellDelegate {

    private var defaults = GIFMaker.defaults as! GIFMakerDefaults
    
    private var settings = [SettingsItem]()
    
    lazy var view: UIView = UITableView()
    
    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.minimumHeight = (self.view as! UITableView).rowHeight * 3 + 27
        preferences.pinned = false
        return preferences
    }
    
    var appDock:AppDock?
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        appDock = dock
        settings = [
            SettingsItem(
                key: .aspectRatio
                , label: "Aspect Ratio"
                , valueGetter: { self.defaults.aspectRatio }
                , valueCollection: GIFMakerSettings.aspectRatio.labels.keysArray
                , valueHandler: nil
                , cellDescriber: UITableViewPickerCellDescriber()
                , iconImageName: nil
                )
            , SettingsItem(
                key: .contentMode
                , label: "Crop"
                , valueGetter: { self.defaults.contentMode }
                , valueCollection: GIFMakerSettings.contentMode.labels
                , valueHandler: { self.defaults.contentMode = GIFMakerSettings.contentMode.labels.valuesArray[$0 as? Int ?? 0] }
                , cellDescriber: UITableViewSegmentControlCellDescriber()
                , iconImageName: nil
            )
        ]

        if let view = view as? UITableView{
            view.dataSource = self
            view.delegate = self
            view.rowHeight = 44

            for item in settings{
                view.register(describer: item.cellDescriber)
            }
        }
    }

    var delegate: AppDockDelegate? {
        return self
    }

    func dockWillContract(_ dock: AppDock) {
        (self.view as? UITableView)?.contractAllVisiblePickerCells()
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {
        (view as! UITableView).reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "GIF Options"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
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
            if cell.isExpanded{
                cell.contract(tableView)
            } else{
                appDock?.expandDockIfNeeded(reloadContents: nil)
                DispatchQueue.main.async{
                    cell.expand(tableView)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.settings[indexPath.item]

        if let cellDescriber = item.cellDescriber as? UITableViewPickerCellDescriber
            , let valueCollection = item.valueCollection as? [String]
            , let cell: UITableViewPickerCell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.identifier) as? UITableViewPickerCell
                ?? UITableViewPickerCell(type: .default, reuseIdentifier: cellDescriber.identifier) {

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
        else if let cellDescriber = item.cellDescriber as? UITableViewSegmentControlCellDescriber
            , let valueCollection = item.valueCollection as? [String:Int]
            , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.identifier) as? UITableViewSegmentedControlCell {

            cell.textLabel?.text = item.label
            cell.imageView?.image = item.iconImageName?.asUIImage
            cell.detailTextLabel?.textColor = UIColor.gray
            
            cell.segmentedControl.removeAllSegments()
            for k in valueCollection{
                cell.segmentedControl.insertSegment(withTitle: k.key, at: cell.segmentedControl.numberOfSegments, animated: false)
            }
            
            cell.segmentedControl.selectedSegmentIndex = valueCollection.valuesArray.index(of: item.valueGetter() as? Int ?? GIFMakerSettings.contentMode.fill) ?? 0
            cell.didChangeValue = item.valueHandler
            return cell
        }
        else {
            return UITableViewCell()
        }
    }
    
    func pickerCell(_ cell: UITableViewPickerCell, didPick row: Int, value: Any) {
        defaults.aspectRatio = GIFMakerSettings.aspectRatio.labels[cell.values[row]] ?? 1
    }
}
