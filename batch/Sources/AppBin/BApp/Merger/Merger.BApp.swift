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

class MergerApp: NSObject, BApp, FinalizableApp, PHAssetFinalizableApp, AppDockApp, PhotoEditorViewControllerDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp
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
    
    public private(set) lazy var content: AppDockContent? = nil//MergerAppDockContent()
    public private(set) lazy var photoEditorDockContent: AppDockContent? = MergerPhotoEditorAppDockContent(app: self)
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.merger"
        , version: "0.1"
        , phase: .develop
        , appType: MergerApp.self
        , displayName: "Movie Maker".localized.localizedCapitalized, description:nil, keywords:nil
        , iconBundleName: nil
        , themeColor: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
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
    
    public static var fixedContentLayout: Bool {
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
    
    private var exportSession: AVAssetExportSession?
    
    public var dataSource: AppDockAppDataSource?
    func reloadData() {
        let assetItem = dataSource?.appDockApp(self, appAssetAt: 0)
        (self.photoEditorDockContent as? MergerPhotoEditorAppDockContent)?.setAssetItem(assetItem)
    }
}

extension MergerApp {
    private func mergeVideo(with resultItems: [MergerResultItem]) -> AVPlayerItem {
        var mergedItems = [MergerResultItem]()
        var previousTimeRange = CMTimeRange.zero
        
        var estimatedVideoSize = CGSize.zero
        var exportsPassThrough = true
        let intersectsTimeRange = true
        for var resultItem in resultItems {
            guard let video = resultItem.video else { continue }
            let videoSize = video.renderSize
            
            let videoBounds = CGRect(origin: .zero, size: videoSize)
            
            if estimatedVideoSize != .zero {
                exportsPassThrough = exportsPassThrough && (estimatedVideoSize == videoSize)
            }
            estimatedVideoSize = CGRect(origin: .zero, size: estimatedVideoSize).union(videoBounds).size
            
            if intersectsTimeRange, let startTime = resultItem.asset.creationDate?.timeIntervalSinceReferenceDate {
                let globalTimeRange = CMTimeRange(start: CMTimeMakeWithSeconds(startTime, preferredTimescale: video.duration.timescale), duration: video.duration)
                
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
            else {
                mergedItems.append(resultItem)
            }
        }
        
        let composition = AVMutableComposition()
        
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var instructions = [AVMutableVideoCompositionInstruction]()
        
        var insertTime = CMTime.zero
        for mergedItem in mergedItems {
            guard let video = mergedItem.video else { continue }
            
            let timeRange = mergedItem.timeRange ?? CMTimeRangeMake(start: CMTime.zero, duration: video.duration)
            
            if let compositionVideoTrack = compositionVideoTrack, let videoTrack = video.tracks(withMediaType: .video).first, let _ = try? compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: insertTime) {
                let preferredTransform = videoTrack.preferredTransform
                if exportsPassThrough {
                    compositionVideoTrack.preferredTransform = preferredTransform
                }
                else {
                    let preferredVideoRect = CGRect(origin: .zero, size: video.naturalSize).applying(preferredTransform)
                    
                    var renderScale: CGFloat = 1
                    if mergedItem.contentMode == .aspectFill {
                        
                    }
                    else {
                        if estimatedVideoSize.ratio <= preferredVideoRect.size.ratio {
                            if preferredVideoRect.size.ratio > 1 {
                                renderScale = preferredVideoRect.maxLength / estimatedVideoSize.minLength
                            }
                            else {
                                renderScale = estimatedVideoSize.minLength / preferredVideoRect.minLength
                            }
                        }
                        else {
                            renderScale = estimatedVideoSize.maxLength / preferredVideoRect.maxLength
                        }
                    }
                    
                    let scaleTransform = CGAffineTransform(scaleX: renderScale, y: renderScale)
                    let renderVideoRect = preferredVideoRect.applying(scaleTransform)
                    
                    let translateTransform = CGAffineTransform(translationX: -renderVideoRect.minX + (estimatedVideoSize.width - renderVideoRect.width) / 2, y: -renderVideoRect.minY + (estimatedVideoSize.height - renderVideoRect.height) / 2)
                    
                    var transform = scaleTransform.concatenating(translateTransform)
                    transform = preferredTransform.concatenating(transform)
                    
                    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
                    layerInstruction.setTransform(transform, at: .zero)
                    
                    let instruction = AVMutableVideoCompositionInstruction()
                    instruction.timeRange = CMTimeRange(start: insertTime, duration: timeRange.duration)
                    instruction.layerInstructions = [layerInstruction]
                    instructions.append(instruction)
                }
            }
            else {
                compositionVideoTrack?.insertEmptyTimeRange(timeRange)
            }
            
            if let audioTrack = video.tracks(withMediaType: .audio).first, let _ = try? compositionAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: insertTime) {
            }
            else {
                compositionAudioTrack?.insertEmptyTimeRange(timeRange)
            }
            
            insertTime = insertTime + timeRange.duration
        }
        
        let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
        videoComposition.instructions = instructions
        videoComposition.renderSize = AVVideoComposition.makeVideoRenderSize(estimatedVideoSize)
        
        let playerItem = AVPlayerItem(asset: composition)
        if !exportsPassThrough {
            playerItem.videoComposition = videoComposition
        }
        
        return playerItem
    }
    
    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncWaitSignalable) -> [AppTaskRespondable] {
        let resultItems = result
            .filter { respondable in respondable.info.state == .completed }
            .compactMap { ($0.result as? MergerResultItem) }
            .sorted { ($0.orderedIndex ?? 0) < ($1.orderedIndex ?? 0) }
        
        var results = [PHAssetResultItem]()
        
        let playerItem = mergeVideo(with: resultItems)
        let exportPreset: String = playerItem.videoComposition == nil ? AVAssetExportPresetPassthrough : AVAssetExportPresetHighestQuality
        
        var exportSuccess = false
        
        asyncSignal.begin()
        DispatchQueue(label: #file + "_mergeVideos", qos: .utility).async {
            let videoURL = FileURL.temp(UUID().uuidString, UTI.quickTimeMovie, group: FileURL.fileAndQueuePrivateGroup())
            self.exportSession = AVAssetExportSession.export(asset: playerItem.asset, videoComposition: playerItem.videoComposition, presetName: exportPreset, outputURL: videoURL, progressHandler: { progress in
                self.finalizingProgressDidUpdate(progress)
            }, completionHandler: { (success) in
                exportSuccess = success
                if success {
                    let progress = Progress(totalUnitCount: 1)
                    progress.completedUnitCount = 1
                    self.finalizingProgressDidUpdate(progress)
                    
                    results.append(PHAssetResultItem(asset: AppAsset(PHAsset()), editingResultItems: [PHAssetEditingResultItem(url: videoURL, resourceType: .video)]))
                }
                asyncSignal.end()
            })
        }
        asyncSignal.waitUntilEnd()
        
        guard exportSuccess else { return result }
        
        let success = showingActionsAndWait(targetResultAssets: results, excludedActions: [.modify], asyncSignal)
        result.forEach {
            $0.info.userInfo[AppTaskInfo.UserInfo.Key.removedOnCompletion] = success
        }
        
        return result
    }
    
    public func cancelFinalizing() {
        self.exportSession?.cancelExport()
        self.exportSession = nil
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
    
    //INFO: resize
    var contentMode: PHImageContentMode = .aspectFit
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
        preferences.preferredHeight = 64
        return preferences
    }
    
    // crop or fit
    // aspect ratio
    // quality options
    // intersects time range
}

class MergerPhotoEditorAppDockContent: NSObject, PropertyWatchable, AppDockContent, AppDockDelegate {
    var app: MergerApp?
    convenience init(app: MergerApp) {
        self.init()
        
        self.app = app
    }
    
    private var video: AVAsset? {
        didSet {
            (view as? VideoTrimControl)?.video = video
        }
    }
    
    fileprivate func setAssetItem(_ assetItem: AppAsset?) {
        self.video = nil
        
        guard let assetItem = assetItem else { return }
        DispatchQueue(label: #file + #function, qos: .utility).async {
            var videoURL: URL?
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
            
            if let url = videoURL {
                self.video = AVAsset(url: url)
            }
        }
    }
    
    lazy var view: UIView = {
        let view = VideoTrimControl(frame: .zero)
        view.tintColor = MergerApp.info.themeColor
        return view
    }()
    
    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = 64
        return preferences
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        
    }
    
    func didSetContentView(_ view:UIView, dock:AppDock) {
        view.tintColor = view.colorTheme.tintColor
    }
    
    // crop or fit
    // trimming
}

class VideoTrimControl: UIControl {
    private lazy var contentView: UIView = UIView(frame: .zero)
    private lazy var thumbnailCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.dataSource = self
        view.delegate = self
        view.register(VideoThumbnailCell.self, forCellWithReuseIdentifier: VideoThumbnailCell.reuseIdentifier)
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    typealias ThumbnailInfo = (image: CGImage?, time: CMTime, size: CGSize)
    var thumbnails: [ThumbnailInfo] = [ThumbnailInfo]()
    
    var video: AVAsset? {
        didSet {
            DispatchQueue.main.async {
                self.reloadData()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        addSubview(contentView)
        contentView.fitConstraints(to: self)
        
        contentView.addSubview(thumbnailCollectionView)
        thumbnailCollectionView.fitConstraints(to: contentView)
    }
    
    func reloadData() {
        
        let insets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        let contentBounds = self.thumbnailCollectionView.bounds.inset(by: insets)
        
        self.thumbnailCollectionView.contentInset = insets
        
        self.thumbnails = []
        
        if let video = self.video {
            let videoSize = video.renderSize
            let thumbnailSize = videoSize.aspectFit(in: contentBounds.size)
            
            let imageGenerator = AVAssetImageGenerator(asset: video)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.requestedTimeToleranceBefore = .zero
            imageGenerator.requestedTimeToleranceAfter = .zero
            imageGenerator.maximumSize = thumbnailSize * UIScreen.main.scale
            
            let sampleImage = try? imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            
            var contentWidth: CGFloat = 0
            let numberOfThumbnails = Int(contentBounds.width / thumbnailSize.width)
            for i in 0..<numberOfThumbnails {
                let time = CMTimeMultiplyByRatio(video.duration, multiplier: Int32(i), divisor: Int32(numberOfThumbnails))
                let thumbnailInfo = ThumbnailInfo(image: sampleImage, time: time, size: thumbnailSize)
                self.thumbnails.append(thumbnailInfo)
                
                contentWidth += thumbnailSize.width
            }
            
            let thumbnailInfo = ThumbnailInfo(image: sampleImage, time: video.duration, size: CGSize(width: max(0, contentBounds.width - contentWidth), height: thumbnailSize.height))
            self.thumbnails.append(thumbnailInfo)
            
            DispatchQueue.main.async {
                var idx = 0
                imageGenerator.generateCGImagesAsynchronously(forTimes: self.thumbnails.map({ NSValue(time: $0.time) })) { (requestTime, image, actualTime, result, error) in
                    autoreleasepool {
                        let indexPath = IndexPath(item: idx, section: 0)
                        self.thumbnails[idx].image = image
                        
                        idx += 1
                        
                        DispatchQueue.main.async {
                            self.thumbnailCollectionView.performBatchUpdates({
                                self.thumbnailCollectionView.reloadItems(at: [indexPath])
                            }, completion: nil)
                        }
                    }
                }
            }
        }
        
        self.thumbnailCollectionView.reloadData()
    }
}

extension VideoTrimControl: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbnails.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoThumbnailCell.reuseIdentifier, for: indexPath) as! VideoThumbnailCell
        if let cgImage = self.thumbnails[safe: indexPath.item]?.image {
            cell.imageView.image = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
        }
        return cell
    }
}

extension VideoTrimControl: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.thumbnails[safe: indexPath.item]?.size ?? .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

private class VideoThumbnailCell: UICollectionViewCell {
    class var reuseIdentifier: String {
        return "VideoThumbnailCell"
    }
    
    lazy var imageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.contentMode = .left
        view.clipsToBounds = true
        return view
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        contentView.addSubview(imageView)
        imageView.fitConstraints(to: contentView)
    }
}
