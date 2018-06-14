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

class AppUIAssetView: AssetView {
    fileprivate var editState: StateValueSet<ImageEditStateValue>?
    var originalImage: UIImage?
    
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
    
    override func clearDrawing() {
        super.clearDrawing()
        
        editState = nil
        originalImage = nil
    }
    
    override func imageDidLoad(image: UIImage?) {
        originalImage = image
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
        self.image = originalImage?.applyFilter(ciFilter: ciFilter)
//        if asset?.mediaSubtypes.contains(.photoLive) == true {
//
//        }
//        else {
//            updateImageContents(image?.applyFilter(ciFilter: ciFilter))
//        }
    }
}
