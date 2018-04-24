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

class _GIFMakerAppAsset: PHAssetItem<ImageEditStateValue> {
    func cancelProcessing() {
        
    }
}

private struct GIFMakerPHAssetResult: TaskResultable{
    public var asset: PHAsset
    public var renderPixelSize: CGSize
    public var renderImage: UIImage
}

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
        guard let firstItem = AppAssets.selected.at(unsafeIndex: 0) else { return true }
        return firstItem.asset.mediaType == item.asset.mediaType
    }
    
    public var numberOfItemsShouldSelect: Int? {
        guard let firstItem = AppAssets.selected.at(unsafeIndex: 0) else { return Int.max }
        if firstItem.asset.mediaType == .video || (firstItem.asset.mediaType == .image && firstItem.asset.mediaSubtypes.contains(.photoLive)) {
            return 1
        }
        else {
            return 10
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
        
        func createGIF(with images: [UIImage], loopCount: Int = 0, frameDelay: Double) -> Data? {
            let fileProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: loopCount]]
            let frameProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: frameDelay]]
            
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("animated.gif")
            
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, images.count, nil) else { return nil }
            CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
            
            images.compactMap({ $0.cgImage }).forEach({ CGImageDestinationAddImage(destination, $0, frameProperties as CFDictionary) })
            
            if CGImageDestinationFinalize(destination) {
                return try? Data(contentsOf: url)
            } else {
                return nil
            }
        }
        
        print(createGIF(with: resultItems.map({ $0.renderImage }), frameDelay: 10))
        
        return []
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
        
        let size = CGSize(width: 300, height: 300)
        
        async?.begin()
        
        if assetItem.asset.mediaType == .video {
            
        }
        else if assetItem.asset.mediaType == .image {
            if assetItem.asset.mediaSubtypes.contains(.photoLive) {
               
            }
            else {
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .opportunistic
                options.resizeMode = .exact
                
                let response = assetItem.asset.requestImage(targetSize: size, contentMode: .aspectFit, options: options)
                if let image = response.1 {
                    result = GIFMakerPHAssetResult(asset: assetItem.asset, renderPixelSize: size, renderImage: image)
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
    
    func didSetContentView(_ view:UIView, on:AppDock) {
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
