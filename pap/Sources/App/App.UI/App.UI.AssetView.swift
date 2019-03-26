//
//  App.UI.AssetView.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 27..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import PhotosUI

internal class AppUIAssetOriginalBadgeLabel: RoundedView {
    lazy private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.white.withAlphaComponent(0.9)
        return label
    }()
    
    override func initialize() {
        super.initialize()
        cornerRadius = 2
        
        addSubview(titleLabel)
        
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
    }
    
    var text: String? {
        didSet {
            titleLabel.text = text
            titleLabel.sizeToFit()
            
            bounds.size = CGSize(width: titleLabel.width + 12, height: titleLabel.height + 4)
            titleLabel.center = CGPoint(x: width / 2, y: height / 2)
        }
    }
}

class AppUIAssetView: AssetView {
    private lazy var originalBadgeLabel: AppUIAssetOriginalBadgeLabel = {
        let label = AppUIAssetOriginalBadgeLabel()
        label.text = "Original".localized
        return label
    }()
    
    var originalBadgeTitle: String? {
        set {
            originalBadgeLabel.text = newValue
        }
        
        get {
            return originalBadgeLabel.text
        }
    }
    
    private lazy var processingView: UIView = {
        let view = UIView(frame: bounds)
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.light))
        view.addSubview(blurView)
        blurView.fitConstraints(to: view)
        
        return view
    }()
    
    var isProcessing: Bool = false {
        didSet {
            processingView.isHidden = !isProcessing
        }
    }
    
    func isProcessing(_ processing: Bool, animated: Bool) {
        guard animated else {
            isProcessing = processing
            return
        }
        
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.isProcessing = processing
        }, completion: nil)
    }
    
    fileprivate var editState: StateValueSet<ImageEditStateValue>?
    private var originalCIImage: CIImage?
    var originalImage: UIImage?
    var filteredImage: UIImage? {
        didSet {
            self.image = filteredImage ?? originalImage
        }
    }
    var originalImageForCompare: UIImage?
    
    fileprivate var livePhotoEditingQueue = DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility)
    fileprivate var livePhotoEditingContext: PHLivePhotoEditingContext?
    fileprivate var contentEditingInputRequestID: PHContentEditingInputRequestID?
    
    lazy var compareOriginalGesture: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(self.compareOriginalGestureDidChange))
    }()
    
    var preferredTransform: CGAffineTransform = .identity {
        didSet {
            imageView.transform = preferredTransform
            videoView.transform = preferredTransform
            livePhotoView.transform = preferredTransform
        }
    }
    
    var shouldEditImageAsStillImage: Bool {
        return asset?.imageType == .livePhoto && imageEditType == .stillImage
    }
    
    var shouldEditImageAsVideo: Bool {
        return asset?.imageType == .livePhoto && imageEditType == .notImage
    }
    
    var imageEditType: PHAssetImageType = .stillImage
    
    override func initialize() {
        super.initialize()
        
        accessoryView.addSubview(originalBadgeLabel)
        originalBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        originalBadgeLabel.centerXAnchor.constraint(equalTo: accessoryView.centerXAnchor).isActive = true
        originalBadgeLabel.topAnchor.constraint(equalTo: accessoryView.topAnchor, constant: 10).isActive = true
        originalBadgeLabel.widthAnchor.constraint(equalToConstant: originalBadgeLabel.boundsWidth).isActive = true
        originalBadgeLabel.heightAnchor.constraint(equalToConstant: originalBadgeLabel.boundsHeight).isActive = true
        
        originalBadgeLabel.isHidden = true
        
        addSubview(processingView)
        processingView.fitConstraints(to: self)
        processingView.isHidden = true
        
        compareOriginalGesture.minimumPressDuration = 0.3
        compareOriginalGesture.delegate = self
        self.addGestureRecognizer(compareOriginalGesture)
    }
    
    override func clearDrawing() {
        editState = nil
        
        originalImage = nil
        originalCIImage = nil
        originalImageForCompare = nil
        filteredImage = nil
        
        prepareProcessing()
        
        originalBadgeLabel.isHidden = true
        isProcessing = false
        
        super.clearDrawing()
    }
    
    func setAsset(_ asset: PHAsset, cancelDrawingIfNeeded cancellation: @escaping () -> Bool = { return false }, completion: (() -> Void)?) {
        super.setAsset(asset, cancelDrawingIfNeeded: cancellation, updatePreview: { (preview) in
            self.originalImage = preview
        }, completion: completion)
    }
    
    override func setImageAsset(_ asset: PHAsset, cancelDrawingIfNeeded cancellation: @escaping () -> Bool, completion: (() -> Void)?) {
        if shouldEditImageAsStillImage {
            DispatchQueue.main.async {
                completion?()
            }
        }
        else if shouldEditImageAsVideo {
            super.setVideoAsset(asset, cancelDrawingIfNeeded: cancellation, completion: completion)
        }
        else {
            super.setImageAsset(asset, cancelDrawingIfNeeded: cancellation, completion: completion)
        }
    }
    
    internal var editStateForPlayableAsset: StateValueSet<ImageEditStateValue>?
}

extension AppUIAssetView {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == compareOriginalGesture {
            if let _ = AppCenter.default.currentInstanceAs(PreviewProcessableApp.self) {
                return filteredImage != nil
            }
            else {
                return false
            }
        }
        else {
            return true
        }
    }
    
    @objc func compareOriginalGestureDidChange(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            showOriginal()
        case .ended, .cancelled:
            showFiltered()
        default: break
        }
    }
    
    private func showOriginal() {
        if height > originalBadgeLabel.height * 3 {
            originalBadgeLabel.isHidden = false
        }
        
        self.image = originalImageForCompare ?? originalImage
        stopAny()
        
        if !shouldEditImageAsStillImage, asset?.imageType == .livePhoto {
            self.livePhotoView.isHidden = true
        }
        else if asset?.mediaType == .video {
            self.videoView.isHidden = true
        }
    }
    
    private func showFiltered() {
        originalBadgeLabel.isHidden = true
        
        self.image = filteredImage
        
        if !shouldEditImageAsStillImage, asset?.imageType == .livePhoto {
            self.livePhotoView.isHidden = false
        }
        else if asset?.mediaType == .video {
            self.videoView.isHidden = false
        }
    }
}

//MARK: - Apply Edit State

extension AppUIAssetView {
    func applyEditState<T>(_ editState: StateValueSet<T>?) where T: ImageEditStateValue {
        self.editState = editState as? StateValueSet<ImageEditStateValue>
        applyFilter(editState)
    }
    
    private func prepareProcessing() {
        if let requestID = contentEditingInputRequestID {
            asset?.cancelContentEditingInputRequest(requestID)
            contentEditingInputRequestID = nil
        }
        
        livePhotoEditingContext?.cancel()
        livePhotoEditingContext = nil
    }
    
    fileprivate func applyFilter<T>(_ editState: StateValueSet<T>?) where T: ImageEditStateValue {
        guard let asset = asset else { return }
        
        stopAny()
        prepareProcessing()
        
        if originalCIImage == nil {
            originalCIImage = originalImage?.asCIImage
        }
        
        self.filteredImage = originalCIImage?.applyFilter(ciFilter: editState?.ciFilter).asUIImage
        
        if asset.imageType == .stillImage || previewMode {
            
        }
        else if !shouldEditImageAsStillImage, asset.imageType == .livePhoto {
            livePhotoView.isHidden = true
            editStateForPlayableAsset = editState as? StateValueSet<ImageEditStateValue>
        }
        else if asset.mediaType == .video, let video = playerItem?.asset {
            videoView.isHidden = true
            Timer.scheduledTimer(identifier: fileName() + #function + "media", withTimeInterval: 0) { timer in
                DispatchQueue.main.async {
                    self.videoView.isHidden = false
                    self.applyFilterToVideo(video: video, editState: editState)
                }
            }
        }
    }
    
    override func playAny() {
        if let asset = asset, let editState = editStateForPlayableAsset {
            editStateForPlayableAsset = nil
            
            if !shouldEditImageAsStillImage, asset.imageType == .livePhoto {
                livePhotoView.isHidden = false
                self.applyFilterToLivePhoto(asset: asset, editState: editState)
            }
            else if asset.mediaType == .video, let video = playerItem?.asset {
                videoView.isHidden = false
                self.applyFilterToVideo(video: video, editState: editState)
            }
        }
        else {
            super.playAny()
        }
    }
}

extension AppUIAssetView {
    fileprivate func applyFilterToLivePhoto<T>(asset: PHAsset, editState: StateValueSet<T>?) where T: ImageEditStateValue {
        if editState?.ciFilter != nil || editState?.stabilizationMode != nil {
            self.isProcessing(true, animated: true)
            
            let targetSize = bounds.size
            
            contentEditingInputRequestID = asset.requestContentEditingInput(with: nil, completionHandler: { [weak self] (input, info) in
                guard let input = input else { return }
                
                let app = AppCenter.default.currentInstanceAs(PhotoEditorViewControllerDelegatableApp.self)
                app?.photoEditorWillBeginProcessing()
                
                self?.livePhotoEditingContext?.cancel()
                
                self?.livePhotoEditingContext = PHLivePhotoEditingContext(livePhotoEditingInput: input)
                
                var referenceImage: CIImage?
                self?.livePhotoEditingContext?.frameProcessor = { frame, error in
                    return autoreleasepool {
                        if let filter = editState?.ciFilter {
                            return frame.image.applyFilter(ciFilter: filter)
                        }
                        else if let mode = editState?.stabilizationMode {
                            let result: CIImage
                            if let image = referenceImage {
                                result = frame.image.stabilize(with: image, mode: mode)
                            }
                            else {
                                result = frame.image
                            }
                            referenceImage = frame.image
                            return result
                        }
                        else {
                            return frame.image
                        }
                    }
                }
                
                self?.livePhotoEditingContext?.prepareLivePhotoForPlayback(withTargetSize: targetSize, options: [PHLivePhotoEditingOption.shouldRenderAtPlaybackTime.rawValue: true], completionHandler: { [weak self] (livePhoto, error) in
                    app?.photoEditorWillEndProcessing()
                    
                    guard let livePhoto = livePhoto, error == nil else { return }
                    
                    self?.isProcessing(false, animated: true)
                    
                    self?.livePhoto = livePhoto
                    self?.playAny()
                })
            })
        }
        else {
            playAny()
        }
    }
}

extension AppUIAssetView {
    fileprivate func applyFilterToVideo<T>(video: AVAsset, editState: StateValueSet<T>?) where T: ImageEditStateValue {
        guard let videoTrack = video.tracks(withMediaType: .video).first else { return }
        
        let composition = AVMutableComposition()
        let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        if (try? videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: video.duration), of: videoTrack, at: CMTime.zero)) == nil, let compositionTrack = videoCompositionTrack {
            composition.removeTrack(compositionTrack)
        }
        
        videoCompositionTrack?.preferredTransform = videoTrack.preferredTransform
        
        if let audioTrack = video.tracks(withMediaType: .audio).first, let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            if (try? compositionTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: video.duration), of: audioTrack, at: CMTime.zero)) == nil {
                composition.removeTrack(compositionTrack)
            }
        }
        
        stopAny()
        
        if let item = editState?.playerItem(with: composition) {
            playerItem = item
        }
        else if let filter = editState?.ciFilter {
            playerItem = AVPlayerItem(asset: composition)
            playerItem?.videoComposition = composition.applyFilter(filter)
        }
        else if let mode = editState?.stabilizationMode {
            playerItem = AVPlayerItem(asset: composition)
            playerItem?.videoComposition = composition.stabilize(with: mode)
        }
        else {
            playerItem = AVPlayerItem(asset: composition)
        }
        seekVideo(to: .zero)
        playAny()
    }
}
