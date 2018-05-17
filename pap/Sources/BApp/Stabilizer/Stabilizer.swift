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

class _StabilizerAppAsset: PHAssetItem<ImageEditStateValue> {
    fileprivate var exportSession: AVAssetExportSession?
    
    func cancelProcessing() {
        exportSession?.cancelExport()
        exportSession = nil
    }
}

public class StabilizerAppValue: ImageEditStateValue {
    override var stabilizationMode: ImageAlignment.StabilizationMode? {
        return _stabilizationMode
    }
    
    private var _stabilizationMode: ImageAlignment.StabilizationMode?
    
    init(_ stabilizationMode: ImageAlignment.StabilizationMode? = nil) {
        super.init()
        
        _stabilizationMode = stabilizationMode
    }
}

public extension StateValueSet where T: ImageEditStateValue {
    var stabilizationMode: ImageAlignment.StabilizationMode? {
        return self.iterator().reversed().first?.stabilizationMode
    }
    
    var stabilizationClamp: CGFloat {
        return stabilizationMode == .translation ? 30 : 60
    }
}

public class StabilizerAppConfigValue: NSObject, KeyPathWatchable, AppConfigUIAttrributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?
    
    @objc dynamic
    public var stabilizationMode: ImageEditStateValue?
    
    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttrributeValuable {
            self.tintColor = other.tintColor
        }
        
        if let other = fromOther as? StabilizerAppConfigValue, let stabilizationMode = other.stabilizationMode{
            self.stabilizationMode = stabilizationMode
        }
    }
}

public class Stabilizer: BApp, PHAssetFinalizableApp, AppDockControllableApp, PhotoPickerViewControllerDelegatableApp, PhotoPickerCollectionViewDisplayableApp, ConfigurableApp, _ConfigurableApp {
    public static let taskType:Taskable.Type = StabilizerTask.self

    public static let paramType:TaskParamable.Type = _StabilizerAppAsset.self
    
    public static var configure:(() -> StabilizerAppConfigValue)?
    
    @objc dynamic
    public private(set) lazy var config: StabilizerAppConfigValue? = Stabilizer.configure?()
    public private(set) lazy var dockContent: AppDockContent? = createController()

    public static let info = AppInfo(
            identifier: "com.stells.pap.stabilizer"
            , version: "0.1"
            , phase: .develop
            , appType: Stabilizer.self
            , displayName: "Stabilizer"
            , icon: nil
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    required public init() {}
    
    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.modify]
    }

    public var titleWillFinalize: String? {
        return "Stabilizing Selected Items...".localized
    }
    public var doneButtonTitle: String? {
        return "Stabilize".localized
    }
    
    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.mediaType == .video// || (item.asset.mediaType == .image && !item.asset.mediaSubtypes.contains(.photoLive))
    }
    
    private func createController() -> AppDockContent {
        let items = [
            AppUICollectionView.CollectionItem(title: "Original".localized, image: nil, action: { self.config?.stabilizationMode = StabilizerAppValue() }),
            AppUICollectionView.CollectionItem(title: "Normal".localized, image: nil, action: { self.config?.stabilizationMode = StabilizerAppValue(.translation) }),
            AppUICollectionView.CollectionItem(title: "Strong".localized, image: nil, action: { self.config?.stabilizationMode = StabilizerAppValue(.homographic) })
        ]
        
        let view = AppUICollectionView(items: items)
        
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
    
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable) {
        
        (param as? _StabilizerAppAsset)?.cancelAllRequestIDs()
        (param as? _StabilizerAppAsset)?.cancelProcessing()
    }

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {
        assert(param is _StabilizerAppAsset, "TaskParamable type of this app is \(_StabilizerAppAsset.self)")
        guard let _param = param as? _StabilizerAppAsset else{
            throw TaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _StabilizerAppAsset, _ async: AsyncManualSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
        async.begin()
        
        assetItem.runEditing({ (progress) in
            guard let progress = progress else { return }
            NotificationCenter.default.post(name: PHAssetProcessableNotification.Name.progressChanged, object: self, userInfo: [
                PHAssetProcessableNotification.UserInfo.Key.progress: progress,
                PHAssetProcessableNotification.UserInfo.Key.assetItem: assetItem
                ])
        }) { (asset, contentEditingOutput) in
            if let asset = asset, let contentEditingOutput = contentEditingOutput {
                result = PHAssetResultItem(
                    asset: asset,
                    contentEditingOutput: contentEditingOutput)
            }
            async.end()
        }
        
        async.waitUntilEnd()
        return result
    }
}

extension _StabilizerAppAsset: PHAssetVideoEditable {
    func edit<T>(processor: T, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? where T : VideoProcessable {
        let asset = self.asset
        
        guard
            let video = asset.asAVAsset,
            let stabilizationMode = editState.stabilizationMode
            else {
                completionHandler(nil, nil)
                return nil
        }
        
        var reqIDs = [PHAssetRequestID]()
        
        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil,nil)
                return
            }
            
            self.exportSession = AVAssetExportSession(asset: video, videoComposition: video.stabilize(with: stabilizationMode, clamp: self.editState.stabilizationClamp), presetName: AVAssetExportPresetHighestQuality, outputURL: item.output.renderedContentURL, progressHandler: progressHandler, completionHandler: { (success) in
                if success {
                    completionHandler(asset, item.output)
                }
                else {
                    completionHandler(nil, nil)
                }
            })
        }

        reqIDs.append(PHAssetRequestID(forEditingInput: r))
        return reqIDs
    }
}
