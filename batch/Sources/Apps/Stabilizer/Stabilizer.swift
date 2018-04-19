//
// Created by BLACKGENE on 11/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

class _StabilizerAppAsset: PHAssetItem<AppValue> {}

public class StabilizerAppValue: AppValue {
    override var stabilizationMode: ImageAlignment.StabilizationMode? {
        return _stabilizationMode
    }
    
    private var _stabilizationMode: ImageAlignment.StabilizationMode?
    
    init(_ stabilizationMode: ImageAlignment.StabilizationMode? = nil) {
        super.init()
        
        _stabilizationMode = stabilizationMode
    }
}

public extension StateValueSet where T: AppValue {
    var stabilizationMode: ImageAlignment.StabilizationMode? {
        return self.iterator().reversed().first?.stabilizationMode
    }
}

public class StabilizerAppConfig: NSObject, KeyPathWatchable, AppConfigUIAttrributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?
    
    @objc dynamic
    public var stabilizationMode: AppValue?
    
    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttrributeValuable {
            self.tintColor = other.tintColor
        }
        
        if let other = fromOther as? StabilizerAppConfig, let stabilizationMode = other.stabilizationMode{
            self.stabilizationMode = stabilizationMode
        }
    }
}

public class Stabilizer: App, PersistableApp, PHAssetFinalizableApp, AppDockControllableApp, PhotoPickerViewControllerDelegatableApp, PhotoPickerCollectionViewDisplayableApp, ConfigurableApp, _ConfigurableApp {
    public static let taskType:Taskable.Type = StabilizerTask.self

    public static let paramType:TaskParamable.Type = _StabilizerAppAsset.self
    
    public static var configure:(() -> StabilizerAppConfig)?
    
    @objc dynamic
    public private(set) lazy var config: StabilizerAppConfig? = Stabilizer.configure?()
    public private(set) lazy var controller: AppDockContent? = createController()

    public static let info = AppInfo(
            identifier: "com.stells.batch.stabilizer"
            , version: "0.1"
            , phase: .develop
            , appType: Stabilizer.self
            , displayName: "Stabilizer"
            , icon: nil
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    public required init() {}
    
    public var finalizingOptions: [PHAssetFinalizingOption]{
        return [.modify]
    }

    public var titleWillFinalize: String? {
        return "Stabilizing Selected Items...".localized
    }
    public var doneButtonTitle: String? {
        return "Stabilize".localized
    }
    
    public func shouldSelect(item: PHAssetItem<AppValue>) -> Bool {
        return item.asset.mediaType == .video// || (item.asset.mediaType == .image && !item.asset.mediaSubtypes.contains(.photoLive))
    }
    
    private func createController() -> AppDockContent {
        let items = [
            BAppUICollectionView.CollectionItem(title: "Translation".localized, image: nil, action: { self.config?.stabilizationMode = StabilizerAppValue(.translation) }),
            BAppUICollectionView.CollectionItem(title: "Homographic".localized, image: nil, action: { self.config?.stabilizationMode = StabilizerAppValue(.homographic) })
        ]
        
        let view = BAppUICollectionView(items: items)
        
        var p = AppDockContentPreferences()
        p.pinned = true
        p.minimumHeight = 64 // for test. remove this line after fixed app design
        return AppDockContentItem(view: view, preferences: p)
    }
    
    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
    }
}

private class StabilizerTask: TaskPrototype, Taskable {
    private var isCancelled: Bool = false
    
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable?) {
        (param as? _StabilizerAppAsset)?.cancelAllRequestIDs()
    }

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable?) throws -> TaskResultable? {
        assert(param is _StabilizerAppAsset, "TaskParamable type of this app is \(_StabilizerAppAsset.self)")
        guard let _param = param as? _StabilizerAppAsset else{
            throw TaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _StabilizerAppAsset, _ async: AsyncManualSignalable?) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
        async?.begin()
        
        assetItem.runEditing(nil) { (asset, contentEditingOutput) in
            if let asset = asset, let contentEditingOutput = contentEditingOutput {
                result = PHAssetResultItem(
                    asset: asset,
                    contentEditingOutput: contentEditingOutput)
            }
            async?.end()
        }
        
        async?.waitUntilEnd()
        return result
    }
}

extension _StabilizerAppAsset: PHAssetVideoEditable {
    func edit<T>(processor: T, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? where T : VideoProcessable {
        let asset = self.asset
        
        guard
            let video = asset.asAVAsset,
            let stabilizationMode = editState.stabilizationMode
            else {
                completionHandler(nil, nil)
                return nil
        }
        
        let videoComposition = video.stabilize(with: stabilizationMode)
        
        var reqIDs = [PHAssetRequestID]()
        
        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil,nil)
                return
            }

            let exportSession = AVAssetExportSession(asset: video, presetName: AVAssetExportPresetHighestQuality)
            exportSession?.outputFileType = AVFileType.mov
            exportSession?.outputURL = item.output.renderedContentURL
            exportSession?.videoComposition = videoComposition
            exportSession?.shouldOptimizeForNetworkUse = false
            exportSession?.exportAsynchronously {
                guard let status = exportSession?.status else { return }
                switch status {
                case .completed:
                    completionHandler(asset, item.output)
                case .failed, .cancelled:
                    completionHandler(nil, nil)
                default:
                    break
                }
            }
        }

        reqIDs.append(PHAssetRequestID(forEditingInput: r))
        return reqIDs
    }
}
