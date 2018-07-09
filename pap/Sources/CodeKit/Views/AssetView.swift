//
//  AssetView.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 11. 27..
//  Copyright © 2017년 Stells. All rights reserved.
//
// STAssetView can draw following media:
// - image
// - video
// - live photo
// - images

import UIKit
import Photos
import AVFoundation
import PhotosUI
import SwiftyGif

class AssetView: UIView {
    lazy var accessoryView: UIView = {
        return UIView(frame: CGRect(origin: .zero, size: frame.size))
    }()
    
    lazy fileprivate var imageLayer: CALayer = {
        return CALayer()
    }()
    lazy fileprivate var videoLayer: AVPlayerLayer = {
        return AVPlayerLayer()
    }()
    lazy fileprivate var livePhotoView: PHLivePhotoView = {
        return PHLivePhotoView(frame: CGRect(origin: .zero, size: frame.size))
    }()
    lazy fileprivate var gifImageView: UIImageView = {
        return UIImageView(frame: CGRect(origin: .zero, size: frame.size))
    }()
    
    var previewMode: Bool = false
    var preferredTransform: CGAffineTransform = .identity {
        didSet {
            imageLayer.transform = CATransform3DMakeAffineTransform(preferredTransform)
            videoLayer.transform = CATransform3DMakeAffineTransform(preferredTransform)
            livePhotoView.transform = preferredTransform
            gifImageView.transform = preferredTransform
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
    
    func initialize() {
        layer.addSublayer(imageLayer)
        layer.addSublayer(videoLayer)
        addSubview(livePhotoView)
        addSubview(gifImageView)
        
        addSubview(accessoryView)
        accessoryView.fitConstraints(to: self)
        
        videoLayer.player = AVPlayer()
        
        livePhotoView.isHidden = true
        livePhotoView.delegate = self
        
        gifImageView.isHidden = true
        
        imageRequestOptions = defaultImageRequestOptions
        videoRequestOptions = defaultVideoRequestOptions
        livePhotoRequestOptions = defaultLivePhotoRequestOptions
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let disableActionsToRestore = CATransaction.disableActions()
        CATransaction.setDisableActions(true)
        imageLayer.frame = bounds
        videoLayer.frame = bounds
        livePhotoView.frame = bounds
        gifImageView.frame = bounds
        CATransaction.setDisableActions(disableActionsToRestore)
    }
    
    override var contentMode: UIViewContentMode {
        didSet {
            livePhotoView.contentMode = contentMode
            gifImageView.contentMode = contentMode
            
            switch contentMode {
            case .scaleAspectFill:
                imageLayer.contentsGravity = kCAGravityResizeAspectFill
                videoLayer.contentsGravity = kCAGravityResizeAspectFill
                videoLayer.videoGravity = .resizeAspectFill
            default:
                imageLayer.contentsGravity = kCAGravityResizeAspect
                videoLayer.contentsGravity = kCAGravityResizeAspect
                videoLayer.videoGravity = .resizeAspect
            }
        }
    }
    
    // MARK: Asset
    
    fileprivate static let imageManager = PHImageManager()
    fileprivate var imageRequestID: PHImageRequestID?
    
    var asset: PHAsset? {
        didSet {
            if oldValue != asset {
                clearDrawing()
            }
        }
    }
    
    func clearDrawing() {
        cancelCurrentImageRequest()
        
        isLivePhotoPlaying = false
        livePhotoView.isHidden = true
        gifImageView.isHidden = true
        imageLayer.contents = nil
        stopAny()
        
        image = nil
        playerItem = nil
        livePhoto = nil
    }
    
    fileprivate func cancelCurrentImageRequest() {
        if let imageRequestID = imageRequestID {
            AssetView.imageManager.cancelImageRequest(imageRequestID)
        }
        self.imageRequestID = nil
    }
    
    // MARK: Image Request Options
    
    private var defaultImageRequestOptions: PHImageRequestOptions {
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isNetworkAccessAllowed = true
        imageRequestOptions.isSynchronous = false
        imageRequestOptions.deliveryMode = .opportunistic
        imageRequestOptions.resizeMode = .fast
        imageRequestOptions.progressHandler = { progress, error, stop, info in
            
        }
        return imageRequestOptions
    }
    var imageRequestOptions: PHImageRequestOptions?
    
    private var defaultVideoRequestOptions: PHVideoRequestOptions {
        let videoRequestOptions = PHVideoRequestOptions()
        videoRequestOptions.isNetworkAccessAllowed = true
        videoRequestOptions.deliveryMode = .automatic
        videoRequestOptions.progressHandler = { progress, error, stop, info in
            
        }
        return videoRequestOptions
    }
    var videoRequestOptions: PHVideoRequestOptions?
    
    private var defaultLivePhotoRequestOptions: PHLivePhotoRequestOptions {
        let livePhotoRequestOptions = PHLivePhotoRequestOptions()
        livePhotoRequestOptions.deliveryMode = .opportunistic
        livePhotoRequestOptions.isNetworkAccessAllowed = true
        livePhotoRequestOptions.progressHandler = { progress, error, stop, info in
            
        }
        return livePhotoRequestOptions
    }
    var livePhotoRequestOptions: PHLivePhotoRequestOptions?
    
    // MARK: Media type
    
    var image: UIImage? {
        didSet {
            updateImageContents(image)
        }
    }
    
    func imageDidLoad(image: UIImage) {}
    
    var playerItem: AVPlayerItem? {
        didSet {
            videoLayer.player?.replaceCurrentItem(with: playerItem)
        }
    }
    
    func videoDidLoad(video: AVAsset?) {}
    
    var livePhoto: PHLivePhoto? {
        didSet {
            livePhotoView.livePhoto = livePhoto
        }
    }
    
    func livePhotoDidLoad(livePhoto: PHLivePhoto?) {}
    
    var gifImage: UIImage? {
        didSet {
            if let image = gifImage {
                gifImageView.setGifImage(image)
            }
            else {
                gifImageView.clear()
            }
        }
    }
    
    func imageDataDidLoad(data: Data?) {}
    
    // MARK: Video
    
    var isVideoPlaying: Bool {
        return videoLayer.player?.rate != 0
    }
    
    var seekTime: CMTime {
        return playerItem?.currentTime() ?? kCMTimeZero
    }
    
    fileprivate var playerLoopingObserver: Any?
    
    // MARK: Live Photo
    
    open var isLivePhotoPlaying: Bool = false
}

extension AssetView: UIGestureRecognizerDelegate {}

//MARK: - Draw asset

extension AssetView {
    func setAsset(_ asset: PHAsset, cancelDrawingIfNeeded cancellation: @escaping () -> Bool = { return false }, updatePreview: ((UIImage?) -> Void)? = nil, completion: (() -> Void)? = nil) {
        previewMode = false
        self.asset = asset
        
        loadImage(for: asset) { (image) in
            updatePreview?(image)
            
            DispatchQueue.main.async { [weak self] in
                guard !cancellation() else { return }
                
                self?.image = image
                
                if asset.imageType == .stillImage {
                    completion?()
                }
            }
        }
        
        if asset.mediaType == .image {
            setImageAsset(asset, cancelDrawingIfNeeded: cancellation, completion: completion)
        }
        else if asset.mediaType == .video {
            setVideoAsset(asset, cancelDrawingIfNeeded: cancellation, completion: completion)
        }
    }

    private func setImageAsset(_ asset: PHAsset, cancelDrawingIfNeeded cancellation: @escaping () -> Bool = { return false }, completion: (() -> Void)? = nil) {
        if asset.imageType == .livePhoto {
            livePhotoView.isHidden = false
            
            loadImage(for: asset) { (image) in
                DispatchQueue.main.async { [weak self] in
                    self?.image = image
                }
            }
            
            loadLivePhoto(for: asset) { [weak self] livePhoto in
                guard !cancellation() else { return }
                
                DispatchQueue.main.async { [weak self] in
                    self?.livePhoto = livePhoto
                    completion?()
                }
            }
        }
        else if asset.imageType == .animatedGIF {
            gifImageView.isHidden = false
            
            loadImage(for: asset) { (image) in
                DispatchQueue.main.async { [weak self] in
                    self?.image = image
                }
            }
            
            loadImageData(for: asset) { [weak self] data in
                guard !cancellation(), let data = data else { return }
                
                DispatchQueue.main.async { [weak self] in
                    self?.gifImage = UIImage(gifData: data)
                    completion?()
                }
            }
        }
    }
    
    private func setVideoAsset(_ asset: PHAsset, cancelDrawingIfNeeded cancellation: @escaping () -> Bool = { return false }, completion: (() -> Void)? = nil) {
        self.asset = asset
        
        loadImage(for: asset) { (image) in
            DispatchQueue.main.async { [weak self] in
                self?.image = image
            }
        }
        
        loadVideo(for: asset) { [weak self] playerItem in
            guard !cancellation() else { return }
            
            DispatchQueue.main.async { [weak self] in
                self?.playerItem = playerItem
                completion?()
            }
        }
    }
}

extension AssetView {
    func setThumbnailAsset(_ asset: PHAsset, cancelDrawingIfNeeded cancellation: @escaping () -> Bool = { false }, completion: ((UIImage?) -> Void)? = nil) {
        previewMode = true
        self.asset = asset
        
        loadImage(for: asset) { [weak self] image in
            DispatchQueue.main.async { [weak self] in
                guard !cancellation() else { return }
                
                if let completion = completion {
                    completion(image)
                }
                else {
                    self?.image = image
                }
            }
        }
    }
}

extension AssetView {
    private func updateImageContents(_ image: UIImage?) {
        let disabledActions = CATransaction.disableActions()
        CATransaction.setDisableActions(true)
        imageLayer.contents = image?.cgImage
        CATransaction.setDisableActions(disabledActions)
    }
}

//MARK: - Load media from asset

extension AssetView {
    fileprivate func loadImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let targetBounds = AVMakeRect(aspectRatio: asset.pixelSize, insideRect: bounds)
        let targetScale: CGFloat = UIScreen.main.nativeScale
        let targetSize = CGSize(width: targetBounds.width * targetScale, height: targetBounds.height * targetScale)
        imageRequestID = AssetView.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: imageRequestOptions) { [weak self] (image, info) in
            guard (info?[PHImageResultIsDegradedKey] as? Bool) != true else { return }
            if let image = image {
                self?.imageDidLoad(image: image)
            }
            completion(image)
        }
    }
    
    fileprivate func loadVideo(for asset: PHAsset, completion: @escaping (AVPlayerItem?) -> Void) {
        imageRequestID = AssetView.imageManager.requestAVAsset(forVideo: asset, options: videoRequestOptions) { [weak self] (video, audioMix, info) in
            guard (info?[PHImageResultIsDegradedKey] as? Bool) != true else { return }
            self?.videoDidLoad(video: video)
            if let video = video {
                let playerItem = AVPlayerItem(asset: video)
                playerItem.audioMix = audioMix
                completion(playerItem)
            }
            else {
                completion(nil)
            }
        }
    }
    
    fileprivate func loadLivePhoto(for asset: PHAsset, completion: @escaping (PHLivePhoto?) -> Void) {
        let targetSize = CGSize(width: bounds.width * UIScreen.main.nativeScale, height: bounds.height * UIScreen.main.nativeScale)
        imageRequestID = AssetView.imageManager.requestLivePhoto(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: livePhotoRequestOptions, resultHandler: { [weak self] (livePhoto, info) in
            guard (info?[PHImageResultIsDegradedKey] as? Bool) != true else { return }
            self?.livePhotoDidLoad(livePhoto: livePhoto)
            completion(livePhoto)
        })
    }
    
    fileprivate func loadImageData(for asset: PHAsset, completion: @escaping (Data?) -> Void) {
        imageRequestID = AssetView.imageManager.requestImageData(for: asset, options: imageRequestOptions, resultHandler: { [weak self] (data, uti, orientation, info) in
            guard (info?[PHImageResultIsDegradedKey] as? Bool) != true else { return }
            self?.imageDataDidLoad(data: data)
            completion(data)
        })
    }
}

extension AssetView {
    // Abs
    @objc func playAny() {
        guard let asset = asset else { return }

        if asset.mediaSubtypes.contains(.photoLive) {
            self.playLivePhoto()
        }
        else if asset.mediaType == .video {
            self.playVideo()
        }
    }

    func stopAny() {
        guard let asset = asset else { return }

        if asset.mediaSubtypes.contains(.photoLive) {
            self.stopLivePhoto()
        }
        else if asset.mediaType == .video {
            self.stopVideo()
        }
    }

    //Live PHAsset
    func playLivePhoto() {
        guard !isLivePhotoPlaying else { return }
        livePhotoView.startPlayback(with: .full)
    }

    func stopLivePhoto() {
        guard isLivePhotoPlaying else { return }
        livePhotoView.stopPlayback()
    }

    //Videos

    func playVideo() {
        guard !isVideoPlaying else { return }
        videoLayer.player?.play()
    }
    
    func playVideoWithLooping() {
        playVideo()
        addVideoLooping()
    }
    
    func startVideo(to seekTime: CMTime = kCMTimeZero) {
        guard !isVideoPlaying else { return }
        seekVideo(to: seekTime)
        videoLayer.player?.play()
    }
    
    func pauseVideo() {
        guard isVideoPlaying else { return }
        videoLayer.player?.pause()
        removeVideoLooping()
    }
    
    func stopVideo() {
        pauseVideo()
        seekVideo(to: kCMTimeZero)
    }
    
    func seekVideo(to: CMTime, toleranceBefore: CMTime = kCMTimeZero, toleranceAfter: CMTime = kCMTimeZero, completionHandler: ((Bool) -> Void)? = nil) {
        playerItem?.seek(to: to, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: completionHandler)
    }
    
    private func addVideoLooping() {
        if let playerItem = playerItem {
            playerLoopingObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: OperationQueue.main, using: { [weak self] (notification) in
                self?.startVideo(to: kCMTimeZero)
            })
        }
    }
    
    private func removeVideoLooping() {
        if let observer = playerLoopingObserver {
            NotificationCenter.default.removeObserver(observer, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
        playerLoopingObserver = nil
    }
}

// Live Photo

extension AssetView: PHLivePhotoViewDelegate {
    func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        isLivePhotoPlaying = true
    }
    
    func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        isLivePhotoPlaying = false
    }
}
