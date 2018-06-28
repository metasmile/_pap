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
        label.textColor = UIColor.white.withAlphaComponent(0.5)
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
    
    fileprivate var editState: StateValueSet<ImageEditStateValue>?
    var originalImage: UIImage? {
        didSet {
            self.image = originalImage
        }
    }
    var filteredImage: UIImage? {
        didSet {
            self.image = filteredImage
        }
    }
    
    override var playerItem: AVPlayerItem? {
        didSet {
            applyEditState(editState)
        }
    }
    
    override var livePhoto: PHLivePhoto? {
        didSet {
            applyEditState(editState)
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
        
        let compareOriginalGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.compareOriginalGestureDidChange))
        compareOriginalGesture.minimumPressDuration = 0.3
        compareOriginalGesture.delegate = self
        self.addGestureRecognizer(compareOriginalGesture)
    }
    
    override func clearDrawing() {
        super.clearDrawing()
        
        editState = nil
        originalImage = nil
        filteredImage = nil
        originalBadgeLabel.isHidden = true
    }
    
    override func imageDidLoad(image: UIImage?) {
        originalImage = image
    }
}

extension AppUIAssetView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return filteredImage != nil
    }
    
    @objc func compareOriginalGestureDidChange(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            self.image = originalImage
            if height > originalBadgeLabel.height * 3 {
                originalBadgeLabel.isHidden = false
            }
        case .ended, .cancelled:
            self.image = filteredImage
            originalBadgeLabel.isHidden = true
        default: break
        }
    }
}

//MARK: - Apply Edit State

extension AppUIAssetView {
    func applyEditState<T>(_ editState: StateValueSet<T>?) where T: ImageEditStateValue {
        self.editState = editState as? StateValueSet<ImageEditStateValue>
        
        DispatchQueue.main.async { [weak self] in
            guard self?.editState == editState else { return }
            self?.applyFilter(editState)
        }
    }
    
    fileprivate func applyFilter<T>(_ editState: StateValueSet<T>?) where T: ImageEditStateValue {
        if asset?.mediaType == .image || previewMode {
            applyImageFilter(ciFilter: editState?.ciFilter)
        }
        else if asset?.mediaType == .video {
            if let filter = editState?.ciFilter {
                playerItem?.videoComposition = playerItem?.asset.applyFilter(filter)
            }
            else if let mode = editState?.stabilizationMode {
                playerItem?.videoComposition = playerItem?.asset.stabilize(with: mode)
            }
        }
    }
    
    func applyImageFilter(ciFilter: CIFilter?) {
        self.filteredImage = ciFilter != nil ? originalImage?.applyFilter(ciFilter: ciFilter) : nil
        
//        if asset?.mediaSubtypes.contains(.photoLive) == true {
//
//        }
//        else {
//            updateImageContents(image?.applyFilter(ciFilter: ciFilter))
//        }
    }
}
