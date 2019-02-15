//
//  Merger.BApp.swift
//  pap
//
//  Created by HYOJIN MO on 12/02/2019.
//  Copyright © 2019 Stells. All rights reserved.
//

import UIKit
import PropertyKit
import Photos

protocol MergerAppDefaults: AppDefaults {
    var aspectRatio: Double {get set}
    var contentMode: PHImageContentMode {get set}
}

extension Defaults: MergerAppDefaults {
    
}

class MergerApp: NSObject, BApp, FinalizableApp, PHAssetFinalizableApp, AppDockApp, PhotoPickerViewControllerAppearanceDelegatableApp
, PhotoPickerCollectionViewDelegatableApp, ConfigurableApp, _ConfigurableApp, EditableApp {
    public static let taskType: AppTaskable.Type = MergerTask.self
    
    public static let paramType: AppTaskParamable.Type = _MergerAppAsset.self
    
    public static var defaultConfigValue: AppConfigValuable {
        let config = MergerAppConfigValue()
        config.tintColor = .black
        return config
    }
    
    @objc dynamic
    public private(set) lazy var config: MergerAppConfigValue? = type(of:self).defaultConfigValue as? MergerAppConfigValue
    
    public private(set) lazy var content: AppDockContent? = MergerAppDockContent()
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.merger"
        , version: "0.1"
        , phase: .develop
        , appType: MergerApp.self
        , displayName: "Movie Maker".localized.localizedCapitalized, description:nil, keywords:nil
        , iconBundleName: nil
        , themeColor: UIColor(red: 0, green: 0, blue: 128 / 255.0, alpha: 1)
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    required public override init() {
        super.init()
        
        self.defaultEditStateValue = nil
    }
    
    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.actions]
    }
    
    public var doneButtonTitle: String? {
        return "Make".localized
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
}

extension MergerApp {
    private func mergeVideo(with resultItems: [MergerResultItem]) -> AVAsset {
        var mergedItems = [MergerResultItem]()
        var previousTimeRange = CMTimeRange.zero
        for var resultItem in resultItems {
            if let startTime = resultItem.asset.creationDate?.timeIntervalSinceReferenceDate, let duration = resultItem.video?.duration {
                let globalTimeRange = CMTimeRange(start: CMTimeMakeWithSeconds(startTime, preferredTimescale: duration.timescale), duration: duration)
                
                if resultItem.asset.imageType == .livePhoto {
                    let timeRange = previousTimeRange.intersection(globalTimeRange)
                    if !timeRange.isEmpty {
                        var estimatedTimeRange = CMTimeRange(start: timeRange.end, end: globalTimeRange.end)
                        estimatedTimeRange.start = estimatedTimeRange.start - globalTimeRange.start
                        resultItem.setEstimatedTimeRange(estimatedTimeRange)
                        
                        if !estimatedTimeRange.isEmpty {
                            mergedItems.append(resultItem)
                        }
                    }
                    else {
                        mergedItems.append(resultItem)
                    }
                }
                else {
                    mergedItems.append(resultItem)
                }
                
                previousTimeRange = globalTimeRange
            }
        }
        
        let composition = AVMutableComposition()
        
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var insertTime = CMTime.zero
        for mergedItem in mergedItems {
            guard let video = mergedItem.video else { continue }
            
            let timeRange = mergedItem.timeRange ?? CMTimeRangeMake(start: CMTime.zero, duration: video.duration)
            
            if let videoTrack = video.tracks(withMediaType: .video).first, let _ = try? compositionVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: insertTime) {
                compositionVideoTrack?.preferredTransform = videoTrack.preferredTransform
            }
            else {
                compositionVideoTrack?.insertEmptyTimeRange(timeRange)
            }
            
            if let audioTrack = video.tracks(withMediaType: .audio).first, let _ = try? compositionAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: insertTime) {
                compositionAudioTrack?.preferredVolume = audioTrack.preferredVolume
            }
            else {
                compositionAudioTrack?.insertEmptyTimeRange(timeRange)
            }
            
            insertTime = insertTime + timeRange.duration
        }
        
        return composition
    }
    
    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncWaitSignalable) -> [AppTaskRespondable] {
        let resultItems = result
            .filter { respondable in respondable.info.state == .completed }
            .compactMap { ($0.result as? MergerResultItem) }
            .sorted { ($0.orderedIndex ?? 0) < ($1.orderedIndex ?? 0) }
        
        var results = [PHAssetResultItem]()
        
        let video = mergeVideo(with: resultItems)
        
        asyncSignal.begin()
        DispatchQueue(label: #file + "_mergeVideos", qos: .utility).async {
            let videoURL = FileURL.temp(UUID().uuidString, UTI.quickTimeMovie, group: FileURL.fileAndQueuePrivateGroup())
            AVAssetExportSession.export(asset: video, outputURL: videoURL, progressHandler: { progress in
                
            }, completionHandler: { (success) in
                if success {
                    results.append(PHAssetResultItem(asset: AppAsset(PHAsset()), editingResultItems: [PHAssetEditingResultItem(url: videoURL, resourceType: .video)]))
                }
                asyncSignal.end()
            })
        }
        asyncSignal.waitUntilEnd()
        
        let success = showingActionsAndWait(targetResultAssets: results, excludedActions: [.modify], asyncSignal)
        result.forEach {
            $0.info.userInfo[AppTaskInfo.UserInfo.Key.removedOnCompletion] = success
        }
        
        return result
    }
}

public class MergerAppConfigValue: NSObject, PropertyWatchable, AppConfigUIAttributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?
    
    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttributeValuable {
            self.tintColor = other.tintColor
        }
    }
}

class _MergerAppAsset: AppAsset {}

struct MergerResultItem: AppTaskResultable {
    var asset: PHAsset
    var result: [PHAssetEditingResultItem]?
    var orderedIndex: Int?
    
    init(asset: PHAsset, result: [PHAssetEditingResultItem]?, orderedIndex: Int?) {
        self.asset = asset
        self.result = result
        self.orderedIndex = orderedIndex
    }
    
    var video: AVAsset? {
        guard let url = result?.url(for: .video) else { return nil }
        return AVAsset(url: url)
    }
    
    //INFO: trimming
    var timeRange: CMTimeRange?
    private(set) var estimatedTimeRange: CMTimeRange? {
        didSet {
            timeRange = estimatedTimeRange
        }
    }
    mutating func setEstimatedTimeRange(_ timeRange: CMTimeRange) {
        self.estimatedTimeRange = timeRange
    }
}

public class MergerAppValue: ImageEditStateValue {}

private class MergerTask: AppTaskPrototype, AppTaskable {
    override var info: AppTaskInfo {
        let info = super.info
        info.policy.estimatedConcurrencyCount = 1
        return info
    }
    
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) {
        (param as? _MergerAppAsset)?.cancelAllRequestIDs()
    }
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _MergerAppAsset, "TaskParamable type of this app is \(_MergerAppAsset.self)")
        guard let _param = param as? _MergerAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _MergerAppAsset, _ async: AsyncWaitSignalable) throws -> MergerResultItem?  {
        // 1: Load video
        // 2: Prepare for Output Size (Crop and resize)
        // 3: Add Effects (Overlays and transitions)
        
        var result: MergerResultItem?
        var videoURL: URL?
        
        async.begin()
        
        DispatchQueue(label: #file + "_prepareVideo", qos: .utility).async {
            if assetItem.asset.mediaType == .video {
                videoURL = assetItem.asset.asAVAsset?.asURL
            }
            else if assetItem.asset.imageType == .livePhoto {
                videoURL = MovConverter_LivePhoto().convert(source: assetItem, cancellation: nil, progressHandler: nil, AsyncSignal())?.first?.url
            }
            else if assetItem.asset.imageType == .burst {
                videoURL = MovConverter_Burst().convert(source: assetItem, cancellation: nil, progressHandler: nil, AsyncSignal())?.first?.url
            }
            else {
                videoURL = MovConverter_Jpeg().convert(source: assetItem, cancellation: nil, progressHandler: nil, AsyncSignal())?.first?.url
            }
            
            async.end()
        }
        async.waitUntilEnd()
        
        if let url = videoURL {
            result = MergerResultItem(asset: assetItem.asset, result: [PHAssetEditingResultItem(url: url, resourceType: .video)], orderedIndex: AppAssets.selected.index(of: assetItem))
        }
        
        return result
    }
}

class MergerAppDockContent: NSObject, PropertyWatchable, AppDockContent, AppDockDelegate {
    lazy var view: UIView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tintColor = MergerApp.info.themeColor
        return tableView
    }()
    
    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = 120
        return preferences
    }
    
}
