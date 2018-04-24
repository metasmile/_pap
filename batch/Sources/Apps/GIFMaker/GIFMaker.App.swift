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
    public private(set) lazy var controller: AppDockContent? = createController()
    
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
        return [.create]
    }
    
    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
    }
    
    private func createController() -> AppDockContent {
        let items = [
            BAppUICollectionView.CollectionItem(title: "FPS", image: nil, action: nil),
            BAppUICollectionView.CollectionItem(title: "Direction", image: nil, action: nil)
        ]
        
        let view = BAppUICollectionStackView(items: items)
        var preferences = AppDockContentPreferences()
        preferences.pinned = true
        preferences.minimumHeight = 44
        return AppDockContentItem(view: view, preferences: preferences)
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
