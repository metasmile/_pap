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
    
    var originalLivePhoto: PHLivePhoto?
    var filteredLivePhoto: PHLivePhoto? {
        didSet {
            self.livePhoto = filteredLivePhoto ?? originalLivePhoto
        }
    }
    
    override var playerItem: AVPlayerItem? {
        didSet {
            applyEditState(editState)
        }
    }
    
    lazy var compareOriginalGesture: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(self.compareOriginalGestureDidChange))
    }()
    
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
        
        originalLivePhoto = nil
        filteredLivePhoto = nil
        
        originalBadgeLabel.isHidden = true
        isProcessing = false
        
        super.clearDrawing()
    }
    
    override func livePhotoDidLoad(livePhoto: PHLivePhoto?) {
        originalLivePhoto = livePhoto
    }
}

extension AppUIAssetView {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == compareOriginalGesture {
            return filteredImage != nil || filteredLivePhoto != nil
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
        
        if asset?.imageType == .stillImage || previewMode {
            self.image = originalImage
        }
        else if asset?.imageType == .livePhoto {
            self.livePhoto = originalLivePhoto
        }
    }
    
    private func showFiltered() {
        originalBadgeLabel.isHidden = true
        
        if asset?.imageType == .stillImage || previewMode {
            self.image = filteredImage
        }
        else if asset?.imageType == .livePhoto {
            self.livePhoto = filteredLivePhoto
        }
    }
}

//MARK: - Apply Edit State

extension AppUIAssetView {
    func applyEditState<T>(_ editState: StateValueSet<T>?) where T: ImageEditStateValue {
        self.editState = editState as? StateValueSet<ImageEditStateValue>
        applyFilter(editState)
    }
    
    fileprivate func applyFilter<T>(_ editState: StateValueSet<T>?) where T: ImageEditStateValue {
        guard let asset = asset else { return }
        if asset.imageType == .stillImage || previewMode {
            self.filteredImage = originalImage?.applyFilter(ciFilter: editState?.ciFilter)
        }
        else if asset.imageType == .livePhoto {
            if let filter = editState?.ciFilter {
                self.isProcessing(true, animated: false)
                
                asset.requestContentEditingInput(with: nil, completionHandler: { (input, info) in
                    guard let input = input else { return }
                    let editingContext = PHLivePhotoEditingContext(livePhotoEditingInput: input)
                    editingContext?.frameProcessor = { [weak self] frame, error in
                        guard self?.editState == editState else {
                            editingContext?.cancel()
                            return nil
                        }
                        return frame.image.applyFilter(ciFilter: filter)
                    }
                    
                    editingContext?.prepareLivePhotoForPlayback(withTargetSize: asset.pixelSize, options: nil, completionHandler: { (livePhoto, error) in
                        self.isProcessing(false, animated: true)
                        
                        self.filteredLivePhoto = livePhoto
                    })
                })
            }
            else if self.livePhoto != originalLivePhoto {
                self.filteredLivePhoto = nil
            }
        }
        else if asset.mediaType == .video {
            if let filter = editState?.ciFilter {
                playerItem?.videoComposition = playerItem?.asset.applyFilter(filter)
            }
            else if let mode = editState?.stabilizationMode {
                playerItem?.videoComposition = playerItem?.asset.stabilize(with: mode)
            }
        }
    }
}
