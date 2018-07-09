//
//  AppUIAssetView.swift
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
    
    private lazy var processingView: UIView = {
        let view = UIView(frame: bounds)
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.light))
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
        
        UIView.transition(with: processingView, duration: 0.3, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.isProcessing = processing
        }, completion: nil)
    }
    
    fileprivate var editState: StateValueSet<ImageEditStateValue>?
    var originalImage: UIImage?
    var filteredImage: UIImage? {
        didSet {
            self.image = filteredImage ?? originalImage
        }
    }
    
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
        filteredImage = nil
        
        preferredTransform = .identity
        layer.transform = CATransform3DIdentity
        
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
}

extension AppUIAssetView {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == compareOriginalGesture {
            return filteredImage != nil
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
        
        self.image = originalImage
        stopAny()
        
        if asset?.imageType == .livePhoto {
            self.livePhotoView.isHidden = true
        }
        else if asset?.mediaType == .video {
            self.videoView.isHidden = true
        }
    }
    
    private func showFiltered() {
        originalBadgeLabel.isHidden = true
        
        self.image = filteredImage
        
        if asset?.imageType == .livePhoto {
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
        
        prepareProcessing()
        
        self.filteredImage = originalImage?.applyFilter(ciFilter: editState?.ciFilter)
        
        if asset.imageType == .stillImage || previewMode {
            
        }
        else if asset.imageType == .livePhoto {
            if let filter = editState?.ciFilter {
                self.isProcessing(true, animated: true)
                
                asset.requestContentEditingInput(with: nil, completionHandler: { [weak self] (input, info) in
                    guard let input = input else { return }
                    
                    self?.livePhotoEditingContext = PHLivePhotoEditingContext(livePhotoEditingInput: input)
                    self?.livePhotoEditingContext?.frameProcessor = { frame, error in
                        return frame.image.applyFilter(ciFilter: filter)
                    }
                    
                    self?.livePhotoEditingContext?.prepareLivePhotoForPlayback(withTargetSize: asset.pixelSize, options: nil, completionHandler: { [weak self] (livePhoto, error) in
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
        else if asset.mediaType == .video {
            if let filter = editState?.ciFilter {
                playerItem?.videoComposition = playerItem?.asset.applyFilter(filter)
            }
            else if let mode = editState?.stabilizationMode {
                playerItem?.videoComposition = playerItem?.asset.stabilize(with: mode)
            }
            playAny()
        }
    }
}
