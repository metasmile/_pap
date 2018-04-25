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
    var aspectRatio: CGFloat {get set}
    var contentMode: Int {get set}
    var frameDelay: Double {get set}
}

extension Defaults: GIFMakerDefaults {
    var aspectRatio: CGFloat {
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
        return item.asset.mediaType == .image && !item.asset.mediaSubtypes.contains(.photoLive)
        
//        guard let firstItem = AppAssets.selected.at(unsafeIndex: 0) else { return true }
//        return firstItem.asset.mediaType == item.asset.mediaType
    }
    
    public var numberOfItemsShouldSelect: Int? {
        guard let firstItem = AppAssets.selected.at(unsafeIndex: 0) else { return Int.max }
        if firstItem.asset.mediaType == .video || (firstItem.asset.mediaType == .image && firstItem.asset.mediaSubtypes.contains(.photoLive)) {
            return 1
        }
        else {
            return Int.max
        }
    }
    
    public var finalizingOptions: [PHAssetFinalizingOption]{
        return [.custom]
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
        
        let gifData = createGIF(with: resultItems.map({ $0.imageFileURL }), frameDelay: (GIFMaker.defaults as? GIFMakerDefaults)?.frameDelay ?? 0.3)
        
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
        let aspectRatio = (GIFMaker.defaults as? GIFMakerDefaults)?.aspectRatio ?? 1
        let targetSize = CGSize(width: 640, height: 640 * aspectRatio)
        let contentMode = PHImageContentMode(rawValue: (GIFMaker.defaults as? GIFMakerDefaults)?.contentMode ?? PHImageContentMode.aspectFit.rawValue) ?? PHImageContentMode.aspectFit
        
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

class GIFMakerAppDockContent: NSObject, KeyPathWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    fileprivate var menus = [
        "Content mode",
        "Frame delay",
        "Loop",
        "Direction",
        "Quality"
    ]
    
    var view: UIView{
        let view = UITableView()
        view.dataSource = self
        view.delegate = self
        view.rowHeight = 44
        view.allowsSelection = false
        view.register(Cell.self, forCellReuseIdentifier: GIFMaker.info.identifier)
        
        return view
    }
    
    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.minimumHeight = 44 * CGFloat(menus.count) + 20
        preferences.pinned = false
        return preferences
    }
    
    func didSetContentView(_ view:UIView, dock:AppDock) {
        if options != nil{
            (view as! UITableView).reloadData()
        }
    }
    
    @objc dynamic
    var options:[String: Any]? // Bool may be other custom Codable type instead of Any
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return GIFMaker.info.displayName
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menus.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GIFMaker.info.identifier) as! Cell
        cell.textLabel?.text = menus[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
//            accessoryView = optionSwitch
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc func cellSwitchDidChange(sender: UISwitch) {
            switchDidChange?(sender.isOn)
        }
    }
}
