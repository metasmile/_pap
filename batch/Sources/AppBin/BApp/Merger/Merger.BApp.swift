//
//  Merger.BApp.swift
//  pap
//
//  Created by HYOJIN MO on 12/02/2019.
//  Copyright © 2019 Stells. All rights reserved.
//

import UIKit
import Photos

protocol MergerAppDefaults: AppDefaults {
    var aspectRatio: Double {get set}
    var contentMode: PHImageContentMode {get set}
}

extension Defaults: MergerAppDefaults {

}

public class MergerAppValue: ImageEditStateValue {
    override public var timeRange: CMTimeRange? {
        return _timeRange
    }

    private var _timeRange: CMTimeRange?

    init(_ timeRange: CMTimeRange? = nil) {
        super.init()

        _timeRange = timeRange
    }
}

class MergerApp: NSObject, BApp, FinalizableApp, PHAssetFinalizableApp, AppDockApp, PhotoEditViewControllerInteractableApp, PhotoEditViewControllerDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp
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
    public private(set) lazy var editViewDockContent: AppDockContent? = MergerPhotoEditorAppDockContent(app: self)

    public static let info = AppInfo(
        identifier: "com.stells.batch.merger"
        , version: "1.0"
        , phase: .beta
        , appType: MergerApp.self
        , displayName: "Movie Maker".localized.localizedCapitalized
        , description: "Combine videos, live photos and photos."
        , keywords: ["movie", "merge", "combine", "slideshow", "montage"]
        , icon: nil
        , themeColor: UIColor(rgb: 0xFFE259)//https://uigradients.com/#Mango
        , policy: AppPolicy.default
        , minOSVersion: nil
    )

    required public override init() {
        super.init()
        // watch stubbed
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
    public func selectEditState(value: ImageEditStateValue?, in content: AppDockContent?) {}
    public func setDefaultEditState(value: ImageEditStateValue?) {}

    private var exportSession: AVAssetExportSession?

    public var dataSource: AppDockAppDataSource?
    func reloadData() {
        let assetItem = dataSource?.appDockApp(self, appAssetAt: 0)
        (self.editViewDockContent as? MergerPhotoEditorAppDockContent)?.setAssetItem(assetItem)
    }

    func previewDidTap(at normalizedPoint: CGPoint, with value: ImageEditStateValue?) {
        if let content = self.editViewDockContent as? MergerPhotoEditorAppDockContent, let player = content.player, let timeRange = value?.timeRange {
            if !timeRange.containsTime(player.currentTime()) {
                (content.view as? VideoTrimControl)?.seekTime(timeRange.start)
                player.seek(to: timeRange.start, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }
    }
}

extension MergerApp {
    private func mergeVideo(with resultItems: [MergerResultItem]) -> AVPlayerItem {
        var mergedItems = [MergerResultItem]()
//        var previousTimeRange = CMTimeRange.zero

        var estimatedVideoSize = CGSize.zero
        var exportsPassThrough = true
//        let intersectsTimeRange = false
        for resultItem in resultItems {
            guard let video = resultItem.video else { continue }
            let videoSize = video.renderSize

            let videoBounds = CGRect(origin: .zero, size: videoSize)

            if estimatedVideoSize != .zero {
                exportsPassThrough = exportsPassThrough && (estimatedVideoSize == videoSize)
            }
            estimatedVideoSize = CGRect(origin: .zero, size: estimatedVideoSize).union(videoBounds).size

//            if intersectsTimeRange, let startTime = resultItem.asset.creationDate?.timeIntervalSinceReferenceDate {
//                let globalTimeRange = CMTimeRange(start: CMTimeMakeWithSeconds(startTime, preferredTimescale: video.duration.timescale), duration: video.duration)
//
//                if resultItem.asset.imageType == .livePhoto {
//                    let timeRange = previousTimeRange.intersection(globalTimeRange)
//                    if !timeRange.isEmpty {
//                        var estimatedTimeRange = CMTimeRange(start: timeRange.end, end: globalTimeRange.end)
//                        estimatedTimeRange.start = estimatedTimeRange.start - globalTimeRange.start
//                        resultItem.setEstimatedTimeRange(estimatedTimeRange)
//
//                        if !estimatedTimeRange.isEmpty {
//                            mergedItems.append(resultItem)
//                        }
//                    }
//                    else {
//                        mergedItems.append(resultItem)
//                    }
//                }
//                else {
//                    mergedItems.append(resultItem)
//                }
//
//                previousTimeRange = globalTimeRange
//            }
//            else {
//                mergedItems.append(resultItem)
//            }

            mergedItems.append(resultItem)
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
                        if estimatedVideoSize.ratio <= preferredVideoRect.size.ratio {
                            renderScale = estimatedVideoSize.height / preferredVideoRect.height
                        }
                        else {
                            renderScale = estimatedVideoSize.width / preferredVideoRect.width
                        }
                    }
                    else {
                        if estimatedVideoSize.ratio <= preferredVideoRect.size.ratio {
                            renderScale = estimatedVideoSize.width / preferredVideoRect.width
                        }
                        else {
                            renderScale = estimatedVideoSize.height / preferredVideoRect.height
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

    @objc dynamic
    public var timeRange: ImageEditStateValue?

    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttributeValuable {
            self.tintColor = other.tintColor
        }

        if let other = fromOther as? MergerAppConfigValue, let timeRange = other.timeRange {
            self.timeRange = timeRange
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

private extension AppAsset {
    var asVideoURL: URL? {
        if self.asset.mediaType == .video {
            return self.asset.asAVAsset?.asURL
        }
        else if self.asset.imageType == .livePhoto {
            return MovConverter_LivePhoto().convert(source: self, cancellation: nil, progressHandler: nil, AsyncSignal())?.first?.url
        }
        else if self.asset.imageType == .animatedGIF {
            return MovConverter_Gif().convert(source: self, cancellation: nil, progressHandler: nil, AsyncSignal())?.first?.url
        }
        else if self.asset.imageType == .burst {
            return MovConverter_Burst().convert(source: self, cancellation: nil, progressHandler: nil, AsyncSignal())?.first?.url
        }
        else {
            return MovConverter_Jpeg().convert(source: self, cancellation: nil, progressHandler: nil, AsyncSignal())?.first?.url
        }
    }
}

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
            videoURL = assetItem.asVideoURL
            async.end()
        }
        async.waitUntilEnd()

        if let url = videoURL {
            result = MergerResultItem(asset: assetItem.asset, result: [PHAssetEditingResultItem(url: url, resourceType: .video)], orderedIndex: AppAssets.selected.index(of: assetItem))

            if let timeRange = assetItem.editState.timeRange {
                result?.setEstimatedTimeRange(timeRange)
            }
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

class MergerPhotoEditorAppDockContent: NSObject, PropertyWatchable, AppDockContent, AppDockDelegate, AppDockContentPlayerControllable {
    var app: MergerApp?
    convenience init(app: MergerApp) {
        self.init()

        self.app = app
    }

    private var timePeriodicObserver: Any?
    var player: AVPlayer? {
        willSet {
            if let observer = self.timePeriodicObserver {
                player?.removeTimeObserver(observer)
            }
            self.timePeriodicObserver = nil

            if let observer = self.playerBoundaryTimeObserver {
                player?.removeTimeObserver(observer)
            }
            self.playerBoundaryTimeObserver = nil
        }

        didSet {
            if let player = player {
                let interval = CMTime(value: 1, timescale: 30)
                self.timePeriodicObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { (time) in
                    if player.timeControlStatus == .playing {
                        (self.view as? VideoTrimControl)?.seekTime(time)
                    }
                })

                if let timeRange = (self.view as? VideoTrimControl)?.timeRange {
                    self.setPlayerBoundaryTime(timeRange)
                }
            }
        }
    }

    private(set) var assetItem: AppAsset?

    fileprivate func setAssetItem(_ assetItem: AppAsset?) {
        self.assetItem = assetItem

        (view as? VideoTrimControl)?.setVideo(nil, with: .zero)

        guard let assetItem = assetItem else { return }
        DispatchQueue(label: #file + #function, qos: .utility).async {
            if let url = assetItem.asVideoURL {
                let video = AVAsset(url: url)
                let timeRange = assetItem.editState.timeRange ?? CMTimeRange(start: .zero, duration: video.duration)
                (self.view as? VideoTrimControl)?.setVideo(video, with: timeRange)
                self.setPlayerBoundaryTime(timeRange)
            }
        }
    }

    lazy var view: UIView = {
        let view = VideoTrimControl(frame: .zero)
        view.tintColor = MergerApp.info.themeColor
        view.addTarget(self, action: #selector(self.seekTimeDidChange), for: .valueChanged)
        view.addTarget(self, action: #selector(self.timeRangeDidChange), for: .scrollDidEnd)
        return view
    }()

    @objc private func seekTimeDidChange(sender: VideoTrimControl) {
        if player?.timeControlStatus == .playing {
            player?.pause()
        }
        player?.seek(to: sender.seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private var playerBoundaryTimeObserver: Any?
    @objc private func timeRangeDidChange(sender: VideoTrimControl) {
        self.timeRange = NSValue(timeRange: sender.timeRange)
        self.player?.seek(to: sender.seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
        setPlayerBoundaryTime(sender.timeRange)
    }

    private func setPlayerBoundaryTime(_ timeRange: CMTimeRange) {
        DispatchQueue(label: #file + #function, qos: .utility).async {
            if let observer = self.playerBoundaryTimeObserver {
                self.player?.removeTimeObserver(observer)
            }

            self.playerBoundaryTimeObserver = self.player?.addBoundaryTimeObserver(forTimes: [NSValue(time: timeRange.end)], queue: DispatchQueue.main, using: {
                self.player?.seek(to: timeRange.start, toleranceBefore: .zero, toleranceAfter: .zero)
                self.player?.play()
            })
        }
    }

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

    @objc dynamic var timeRange: NSValue?

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

    private lazy var startDimmedView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor(white: 1, alpha: 0.5)
        return view
    }()

    private lazy var endDimmedView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor(white: 1, alpha: 0.5)
        return view
    }()

    typealias ThumbnailInfo = (image: CGImage?, time: CMTime, size: CGSize)
    var thumbnails: [ThumbnailInfo] = [ThumbnailInfo]()

    var timeRange: CMTimeRange = .zero
    var seekTime: CMTime = .zero

    func setVideo(_ video: AVAsset?, with timeRange: CMTimeRange) {
        self.video = video
        self.timeRange = timeRange

        DispatchQueue.main.async {
            self.reloadData()
        }
    }

    func seekTime(_ time: CMTime) {
        guard let _ = video, time.isNumeric, duration.isNumeric else { return }

        seekTime = time

        let seekBounds = CGRect(origin: CGPoint(x: startTimeThumb.frame.maxX, y: seekThumbBeginRect.origin.y), size: CGSize(width: endTimeThumb.frame.minX - startTimeThumb.frame.maxX - seekTimeThumb.width, height: seekThumbBeginRect.height))
        var offset = seekBounds.minX + seekBounds.width * CGFloat((time.seconds - timeRange.start.seconds) / timeRange.duration.seconds)
        if offset.isNaN || offset < seekBounds.minX {
            offset = seekBounds.minX
        }
        else if offset > seekBounds.maxX {
            offset = seekBounds.maxX
        }

        seekTimeThumb.frame.origin.x = offset
    }

    private var video: AVAsset?
    private var duration: CMTime {
        return video?.duration ?? .zero
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

        contentView.addSubview(startDimmedView)
        contentView.addSubview(endDimmedView)

        contentView.addSubview(timeRangeView)
        contentView.addSubview(seekTimeThumb)
        contentView.addSubview(startTimeThumb)
        contentView.addSubview(endTimeThumb)
    }

    private var timeRangeControlBackgroundColor: UIColor? {
        didSet {
            timeRangeView.layer.borderColor = timeRangeControlBackgroundColor?.cgColor
            startTimeThumb.backgroundColor = timeRangeControlBackgroundColor
            endTimeThumb.backgroundColor = timeRangeControlBackgroundColor
        }
    }

    private var timeRangeControlTintColor: UIColor? {
        didSet {
            startTimeThumb.iconColor = timeRangeControlTintColor
            endTimeThumb.iconColor = timeRangeControlTintColor
        }
    }

    private lazy var timeRangeView: UIView = {
        let view = UIView(frame: .zero)
        view.layer.borderWidth = timeRangeBorderWidth
        return view
    }()

    private var timeRangeBorderWidth: CGFloat = 2

    class ThumbView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            initialize()
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            initialize()
        }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            if bounds.inset(by: UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)).contains(point) {
                return self
            }
            else {
                return super.hitTest(point, with: event)
            }
        }

        override class var layerClass: AnyClass {
            return CAShapeLayer.self
        }

        private func initialize() {
            (layer as? CAShapeLayer)?.lineWidth = 3
            (layer as? CAShapeLayer)?.strokeColor = UIColor.white.cgColor
            (layer as? CAShapeLayer)?.fillColor = UIColor.clear.cgColor

            (layer as? CAShapeLayer)?.lineCap = CAShapeLayerLineCap.round
            (layer as? CAShapeLayer)?.lineJoin = CAShapeLayerLineJoin.round
        }

        var iconColor: UIColor? {
            didSet {
                (layer as? CAShapeLayer)?.strokeColor = iconColor?.cgColor
            }
        }

        var iconPath: UIBezierPath? {
            didSet {
                (self.layer as? CAShapeLayer)?.path = iconPath?.cgPath
            }
        }
    }

    private lazy var startTimeThumb: ThumbView = {
        let view = ThumbView(frame: .zero)
        view.addGestureRecognizer(startThumbGesture)
        return view
    }()

    private lazy var endTimeThumb: ThumbView = {
        let view = ThumbView(frame: .zero)
        view.addGestureRecognizer(endThumbGesture)
        return view
    }()

    private lazy var seekTimeThumb: ThumbView = {
        let view = ThumbView(frame: .zero)
        view.addGestureRecognizer(seekThumbGesture)
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.backgroundColor = UIColor.white
        return view
    }()

    private lazy var startThumbGesture = UIPanGestureRecognizer(target: self, action: #selector(self.startThumbDidChange))
    private lazy var endThumbGesture = UIPanGestureRecognizer(target: self, action: #selector(self.endThumbDidChange))
    private lazy var seekThumbGesture = UIPanGestureRecognizer(target: self, action: #selector(self.seekThumbDidChange))

    private var startThumbBeginRect = CGRect.zero
    private var endThumbBeginRect = CGRect.zero
    private var seekThumbBeginRect = CGRect.zero

    @objc private func startThumbDidChange(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: contentView)

        seekTimeThumb.isHidden = true

        switch sender.state {
        case .began: startThumbBeginRect = startTimeThumb.frame
        default:
            let location = startThumbBeginRect.origin.x + translation.x
            let offset = min(location - thumbnailViewBounds.minX + thumbWidth, endTimeOffset)

            if offset > 0 {
                timeRange = CMTimeRange(start: time(offset: offset), end: timeRange.end)
                startTimeThumb.frame.origin.x = thumbnailViewBounds.minX + offset - thumbWidth
            }
            else {
                timeRange = CMTimeRange(start: .zero, end: timeRange.end)
                startTimeThumb.frame.origin.x = thumbnailViewBounds.minX + self.offset(time: .zero) - thumbWidth
            }
            seekTime = timeRange.start
            drawTimeRange()
            sendActions(for: .valueChanged)
        }

        switch sender.state {
        case .began, .changed: break
        default:
            sendActions(for: .scrollDidEnd)
            seekTimeThumb.isHidden = false
            seekTime(timeRange.start)
        }
    }

    @objc private func endThumbDidChange(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: contentView)

        seekTimeThumb.isHidden = true

        switch sender.state {
        case .began: endThumbBeginRect = endTimeThumb.frame
        default:
            let location = endThumbBeginRect.origin.x + translation.x
            let offset = max(location - thumbnailViewBounds.minX, startTimeOffset + thumbWidth)

            if offset < thumbnailViewBounds.width {
                timeRange = CMTimeRange(start: timeRange.start, end: time(offset: offset - thumbWidth))
                endTimeThumb.frame.origin.x = thumbnailViewBounds.minX + offset
            }
            else {
                timeRange = CMTimeRange(start: timeRange.start, end: duration)
                endTimeThumb.frame.origin.x = thumbnailViewBounds.minX + self.offset(time: duration) + thumbWidth
            }
            drawTimeRange()
            seekTime = timeRange.end
            sendActions(for: .valueChanged)
        }

        switch sender.state {
        case .began, .changed: break
        default:
            sendActions(for: .scrollDidEnd)
            seekTimeThumb.isHidden = false
            seekTime(timeRange.end)
        }
    }

    @objc private func seekThumbDidChange(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: contentView)
        switch sender.state {
        case .began: seekThumbBeginRect = seekTimeThumb.frame
        case .changed:
            let seekBounds = CGRect(origin: CGPoint(x: startTimeThumb.frame.maxX, y: seekThumbBeginRect.origin.y), size: CGSize(width: endTimeThumb.frame.minX - startTimeThumb.frame.maxX - seekTimeThumb.width, height: seekThumbBeginRect.height))
            var offset = seekThumbBeginRect.origin.x + translation.x
            if offset < seekBounds.minX {
                offset = seekBounds.minX
            }
            else if offset > seekBounds.maxX {
                offset = seekBounds.maxX
            }
            seekTimeThumb.frame.origin.x = offset

            seekTime = time(offset: offset - thumbnailViewBounds.minX, without: seekTimeThumb.width)
            sendActions(for: .valueChanged)
        default: break
        }
    }

    var hasChanged: Bool {
        return (duration.seconds - self.timeRange.duration.seconds) * 1000 > 0.1
    }

    private func drawTimeRange() {
        timeRangeControlBackgroundColor = hasChanged ? UIColor(rgb: 0xF7D349) : UIColor.black
        timeRangeControlTintColor = hasChanged ? UIColor.black : UIColor.white

        var timeRangeRect = timeRangeContentBounds

        if let _ = video {
            let startOffset = startTimeOffset
            let endOffset = endTimeOffset

            timeRangeRect.origin.x = timeRangeRect.minX + startOffset
            timeRangeRect.size.width = endOffset - startOffset + thumbWidth * 2
        }

        timeRangeView.frame = timeRangeRect

        startDimmedView.frame = CGRect(origin: thumbnailViewBounds.origin, size: CGSize(width: timeRangeRect.minX - thumbnailViewBounds.minX, height: thumbnailViewBounds.height))
        endDimmedView.frame = CGRect(origin: CGPoint(x: timeRangeRect.maxX, y: thumbnailViewBounds.origin.y), size: CGSize(width: thumbnailViewBounds.maxX - timeRangeRect.maxX, height: thumbnailViewBounds.height))
    }

    private var thumbWidth: CGFloat = 16
    func reloadData() {
        let insets = UIEdgeInsets(top: 10, left: 30, bottom: 10, right: 30)
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

        let timeRangeBounds = timeRangeContentBounds
        var startRect = timeRangeBounds
        startRect.size.width = thumbWidth
        startRect.origin.x = thumbnailViewBounds.minX + startTimeOffset - thumbWidth

        var endRect = timeRangeBounds
        endRect.size.width = thumbWidth
        endRect.origin.x = thumbnailViewBounds.minX + endTimeOffset + thumbWidth

        startTimeThumb.frame = startRect
        endTimeThumb.frame = endRect

        var seekRect = timeRangeBounds
        seekRect.size.width = 8
        seekRect.origin.x = startTimeThumb.frame.maxX
        seekRect.origin.y -= 1
        seekRect.size.height += 2
        seekTimeThumb.frame = seekRect

        let startIconPath = UIBezierPath()
        startIconPath.move(to: CGPoint(x: thumbWidth * 0.6, y: timeRangeBounds.height * 0.33))
        startIconPath.addLine(to: CGPoint(x: thumbWidth * 0.35, y: timeRangeBounds.height * 0.5))
        startIconPath.addLine(to: CGPoint(x: thumbWidth * 0.6, y: timeRangeBounds.height * 0.67))
        startTimeThumb.iconPath = startIconPath

        let endIconPath = UIBezierPath()
        endIconPath.move(to: CGPoint(x: thumbWidth * 0.35, y: timeRangeBounds.height * 0.33))
        endIconPath.addLine(to: CGPoint(x: thumbWidth * 0.6, y: timeRangeBounds.height * 0.5))
        endIconPath.addLine(to: CGPoint(x: thumbWidth * 0.35, y: timeRangeBounds.height * 0.67))
        endTimeThumb.iconPath = endIconPath

        self.drawTimeRange()
    }

    private var thumbnailViewBounds: CGRect {
        let insets = self.thumbnailCollectionView.contentInset
        return self.contentView.bounds.inset(by: insets)
    }

    private var timeRangeContentBounds: CGRect {
        let borderWidth = timeRangeBorderWidth
        return thumbnailViewBounds.inset(by: UIEdgeInsets(top: -borderWidth, left: -borderWidth, bottom: -borderWidth, right: -borderWidth))
    }

    private var startTimeOffset: CGFloat {
        return offset(time: timeRange.start, ratio: 0)
    }

    private var endTimeOffset: CGFloat {
        return offset(time: timeRange.end, ratio: 1)
    }

    private func time(offset: CGFloat) -> CMTime {
        return time(offset: offset, without: thumbWidth)
    }

    private func time(offset: CGFloat, without width: CGFloat) -> CMTime {
        guard duration != .zero else { return .zero }
        let ratio = (offset / (thumbnailViewBounds.width - width)).clamped(to: 0...1)
        return CMTimeMultiplyByFloat64(duration, multiplier: Float64(ratio))
    }

    private func offset(time: CMTime, ratio: CGFloat = 0) -> CGFloat {
        return (thumbnailViewBounds.width - thumbWidth) * (duration != .zero ? CGFloat(time.seconds / duration.seconds) : ratio)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let distanceFromStart = startTimeThumb.origin.distance(to: point)
        let distanceFromEnd = endTimeThumb.origin.distance(to: point)
        let distanceFromSeek = seekTimeThumb.origin.distance(to: point)

        let closestThumb: ThumbView
        if distanceFromStart < distanceFromEnd {
            if distanceFromStart < distanceFromSeek {
                closestThumb = startTimeThumb
            }
            else {
                closestThumb = seekTimeThumb
            }
        }
        else {
            if distanceFromEnd < distanceFromSeek {
                closestThumb = endTimeThumb
            }
            else {
                closestThumb = seekTimeThumb
            }
        }

        let hitView = super.hitTest(point, with: event)
        if let _ = hitView as? ThumbView {
            return closestThumb
        }
        return hitView
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
