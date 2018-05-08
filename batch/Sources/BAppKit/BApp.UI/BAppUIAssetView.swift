//
//  BAppUIAssetView.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 27..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import PhotosUI

class BAppUIAssetView: AssetView {
    fileprivate var editState: StateValueSet<ImageEditStateValue>?
    
    override var image: UIImage? {
        didSet {
            applyEditState(editState)
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
    
    override func clearDrawing() {
        super.clearDrawing()
        
        editState = nil
    }
}

//MARK: - Apply Edit State

extension BAppUIAssetView {
    func applyEditState<T>(_ editState: StateValueSet<T>?) where T: ImageEditStateValue {
        self.editState = editState as? StateValueSet<ImageEditStateValue>
        
        applyFilter(editState)
    }
    
    fileprivate func applyFilter<T>(_ editState: StateValueSet<T>?) where T: ImageEditStateValue {
        if asset?.mediaType == .image || previewMode {
            applyImageFilter(ciFilter: editState?.ciFilter)
        }
        else if asset?.mediaType == .video {
            if let mode = editState?.stabilizationMode {
                playerItem?.videoComposition = playerItem?.asset.stabilize(with: mode, clamp: editState?.stabilizationClamp ?? 0)
            }
            else {
                playerItem?.videoComposition = playerItem?.asset.applyFilter(editState?.ciFilter)
            }
        }
    }
    
    fileprivate func applyImageFilter(ciFilter: CIFilter?) {
        if asset?.mediaSubtypes.contains(.photoLive) == true {
            
        }
        else {
            updateImageContents(image?.applyFilter(ciFilter: ciFilter))
        }
    }
}
