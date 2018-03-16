//
//  PhotoCollectionViewCell.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 8..
//  Copyright © 2017년 Stells. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class PhotoCollectionViewCell: CustomCollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    //TODO: wrap a view as a decorationrenderview later
    @IBOutlet weak var selectionView: UIView!

    @IBOutlet weak var selectionViewWidth: NSLayoutConstraint!
    @IBOutlet weak var selectionViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var decorationView: UIView!

    @IBOutlet weak var durationLabelForVideo: UILabel!
    @IBOutlet weak var iconForLivePhotos: UIImageView!
    
    var selectionCheckView: CheckMark!
    
    private var selectionViewSize: CGSize = .zero {
        didSet {
            selectionViewWidth.constant = selectionViewSize.width
            selectionViewHeight.constant = selectionViewSize.height
        }
    }
    
    static var durationLabelFormat: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        formatter.collapsesLargestUnit = false
        return formatter
    }
    
    var indexPath: IndexPath?
    var imageRequestId: PHImageRequestID?
    var imageContentMode = PHImageContentMode.aspectFit
    
    override func initialize() {
        super.initialize()
        
        selectionCheckView = CheckMark(frame: CGRect(origin: .zero, size: CGSize(width: 28, height: 28)))
        selectionCheckView.backgroundColor = UIColor.clear
        
        selectionView.addSubview(selectionCheckView)
        selectionView.backgroundColor = UIColor(white: 1, alpha: 0.25)
        
        iconForLivePhotos.image = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isSelected = false
        
        imageView.image = nil
        indexPath = nil
        
        if let imageRequestId = imageRequestId {
            PHPhotoLibraryManager.cachingImageManager.cancelImageRequest(imageRequestId)
        }
        imageRequestId = nil
    }

    func setAsset(_ asset: PHAsset, at indexPath: IndexPath) {
        self.indexPath = indexPath
        prepareForDisplay(with: asset)
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.resizeMode = .fast
        
        let targetSizeScale = UIScreen.main.scale
        let targetSize = CGSize(width: imageView.bounds.size.width*targetSizeScale, height: imageView.bounds.size.height*targetSizeScale)
        
        imageRequestId = PHPhotoLibraryManager.cachingImageManager.requestImage(for: asset, targetSize: targetSize, contentMode: imageContentMode, options: requestOptions) { [weak self] (image, info) in
            DispatchQueue.main.async { [weak self] in
                guard self?.indexPath == indexPath else { return }
                self?.imageView.image = image
            }
            self?.imageRequestId = nil
        }
    }
    
    override var isSelected: Bool {
        didSet {
            selectionCheckView.checked = isSelected
            selectionView.visible = isSelected
        }
    }

    public var isEnabled:Bool = false {
        didSet{
            selectionCheckView.visible = isEnabled
            selectionView.visible = !isEnabled
            selectionView.backgroundColor = UIColor(white: 1, alpha: isEnabled ? 0.25: 0.5)
        }
    }
    
    // MARK: - Prepare rendering
    
    private func prepareForDisplay(with asset: PHAsset) {
        updateImageViewContentMode()
        
        let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        selectionViewSize = (imageContentMode == .aspectFit ? AVMakeRect(aspectRatio: imageSize, insideRect: imageView.bounds) : imageView.bounds).size
        
        let checkmarkSize = selectionCheckView.bounds.size
        let checkmarkmargin:CGFloat = 2.0
        selectionCheckView.frame = CGRect(origin: CGPoint(x: selectionViewSize.height-checkmarkSize.width-checkmarkmargin, y: selectionViewSize.width-checkmarkSize.height-checkmarkmargin), size: checkmarkSize)
        
        //duration label
        durationLabelForVideo.isHidden = asset.mediaType != .video
        if !durationLabelForVideo.isHidden{
            durationLabelForVideo.text = PhotoCollectionViewCell.durationLabelFormat.string(from: asset.duration)
        }
        
        //live photo icon
        iconForLivePhotos.isHidden = !asset.mediaSubtypes.contains(.photoLive)
        
        decorationView.isHidden = durationLabelForVideo.isHidden && iconForLivePhotos.isHidden
    }
    
    private func updateImageViewContentMode() {
        switch imageContentMode {
        case .aspectFill:
            imageView.contentMode = .scaleAspectFill
        default:
            imageView.contentMode = .scaleAspectFit
        }
    }
}
