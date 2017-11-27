//
//  STAssetView.swift
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

class STAssetView: UIView {
    fileprivate var imageLayer: CALayer
    fileprivate var videoLayer: AVPlayerLayer
    
    var preferredTransform: CGAffineTransform = .identity {
        didSet {
            videoLayer.transform = CATransform3DMakeAffineTransform(preferredTransform)
        }
    }
    
    override init(frame: CGRect) {
        imageLayer = CALayer()
        videoLayer = AVPlayerLayer()
        
        super.init(frame: frame)
        
        layer.addSublayer(imageLayer)
        layer.addSublayer(videoLayer)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        imageLayer = CALayer()
        videoLayer = AVPlayerLayer()
        
        super.init(coder: aDecoder)
        
        layer.addSublayer(imageLayer)
        layer.addSublayer(videoLayer)
        
        initialize()
    }
    
    fileprivate func initialize() {
        videoLayer.player = AVPlayer()
        
        imageRequestOptions = defaultImageRequestOptions
        videoRequestOptions = defaultVideoRequestOptions
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.setDisableActions(true)
        imageLayer.frame = bounds
        videoLayer.frame = bounds
        CATransaction.setDisableActions(false)
    }
    
    override var contentMode: UIViewContentMode {
        didSet {
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
            if let asset = asset {
                setAsset(asset)
            }
            else {
                clearDrawing()
            }
        }
    }
    
    fileprivate func clearDrawing() {
        cancelCurrentImageRequest()
        
        imageLayer.contents = nil
        pause()
        
        image = nil
        playerItem = nil
    }
    
    fileprivate func cancelCurrentImageRequest() {
        if let imageRequestID = imageRequestID {
            STAssetView.imageManager.cancelImageRequest(imageRequestID)
        }
        self.imageRequestID = nil
    }
    
    // MARK: Image Request Options
    
    private var defaultImageRequestOptions: PHImageRequestOptions {
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isNetworkAccessAllowed = true
        imageRequestOptions.isSynchronous = false
        imageRequestOptions.deliveryMode = .opportunistic
        imageRequestOptions.resizeMode = .exact
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
    
    // MARK: Media type
    
    var image: UIImage? {
        didSet {
            imageLayer.contents = image?.cgImage
        }
    }
    
    var playerItem: AVPlayerItem? {
        didSet {
            videoLayer.player?.replaceCurrentItem(with: playerItem)
        }
    }
    
    // MARK: Video
    
    var isPlaying: Bool {
        return videoLayer.player?.rate != 0
    }
    
    var seekTime: CMTime {
        return playerItem?.currentTime() ?? kCMTimeZero
    }
    
    fileprivate var playerLoopingObserver: Any?
}

//MARK: - Draw asset

extension STAssetView {
    func setAsset(_ asset: PHAsset, cancelDrawingIfNeeded cancellation: @escaping () -> Bool = { return false }, completion: ((Any?) -> Void)? = nil) {
        if asset.mediaType == .image {
            setImageAsset(asset, cancelDrawingIfNeeded: cancellation, completion: completion)
        }
        else if asset.mediaType == .video {
            setVideoAsset(asset, cancelDrawingIfNeeded: cancellation, completion: completion)
        }
    }
    
    func setImageAsset(_ asset: PHAsset, cancelDrawingIfNeeded cancellation: @escaping () -> Bool = { return false }, completion: ((UIImage?) -> Void)? = nil) {
        if asset.mediaSubtypes == .photoLive {
            
        }
        else {
            loadImage(for: asset) { [weak self] image in
                guard !cancellation() else {
                    self?.cancelCurrentImageRequest()
                    return
                }
                
                DispatchQueue.main.async { [weak self] in
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
    
    func setVideoAsset(_ asset: PHAsset, cancelDrawingIfNeeded cancellation: @escaping () -> Bool = { return false }, completion: ((AVPlayerItem?) -> Void)? = nil) {
        loadVideo(for: asset) { [weak self] playerItem in
            guard !cancellation() else {
                self?.cancelCurrentImageRequest()
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                if let completion = completion {
                    completion(playerItem)
                }
                else {
                    self?.playerItem = playerItem
                }
            }
        }
    }
}

//MARK: - Load media from asset

extension STAssetView {
    fileprivate func loadImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let targetSize = CGSize(width: bounds.width * UIScreen.main.nativeScale, height: bounds.height * UIScreen.main.nativeScale)
        imageRequestID = STAssetView.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: imageRequestOptions) { (image, info) in
            completion(image)
        }
    }
    
    fileprivate func loadVideo(for asset: PHAsset, completion: @escaping (AVPlayerItem?) -> Void) {
        imageRequestID = STAssetView.imageManager.requestAVAsset(forVideo: asset, options: videoRequestOptions) { (video, audioMix, info) in
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
}

extension STAssetView {
    func play() {
        guard !isPlaying else { return }
        videoLayer.player?.play()
    }
    
    func playWithLooping() {
        play()
        addVideoLooping()
    }
    
    func start(to seekTime: CMTime = kCMTimeZero) {
        guard !isPlaying else { return }
        seek(to: seekTime)
        videoLayer.player?.play()
    }
    
    func pause() {
        guard isPlaying else { return }
        videoLayer.player?.pause()
        removeVideoLooping()
    }
    
    func stop() {
        pause()
        seek(to: kCMTimeZero)
    }
    
    func seek(to: CMTime, toleranceBefore: CMTime = kCMTimeZero, toleranceAfter: CMTime = kCMTimeZero) {
        playerItem?.seek(to: to, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
    }
    
    private func addVideoLooping() {
        if let playerItem = playerItem {
            playerLoopingObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: OperationQueue.main, using: { [weak self] (notification) in
                self?.start(to: kCMTimeZero)
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
