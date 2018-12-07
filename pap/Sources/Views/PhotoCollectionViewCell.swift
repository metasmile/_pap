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

fileprivate class PhotoCollectionViewCellImages {
    private(set) lazy var LivePhotoIconImage = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
    private(set) lazy var BurstIconImage = R.image.cell_icon_burst()
    private(set) lazy var GIFIconImage = R.image.cell_icon_gif()
    private(set) lazy var PanoramaIconImage = R.image.cell_icon_pano()
    private(set) lazy var DepthIconImage = R.image.cell_icon_depth()
    private(set) lazy var RAWIconImage = R.image.appUICameraRawPhoto()

    static let CellImage = PhotoCollectionViewCellImages()
}

class PhotoCollectionViewCell: CustomCollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    //TODO: wrap a view as a decorationrenderview later
    @IBOutlet weak var selectionView: UIView!

    @IBOutlet weak var imageViewWidth: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var decorationView: UIView!

    @IBOutlet weak var cellIconAsLabel: UILabel!
    @IBOutlet weak var cellIconAsImageView: UIImageView!
    
    var selectionCheckView: CheckMark!

    private var imageViewSize: CGSize = .zero {
        didSet {
            imageViewWidth.constant = imageViewSize.width
            imageViewHeight.constant = imageViewSize.height
            
            layoutIfNeeded()
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
//        selectionCheckView.checkedColor = colorTheme == .dark ? colorTheme.objectBackgroundColor : nil
        selectionCheckView.backgroundColor = UIColor.clear

        selectionView.addSubview(selectionCheckView)
        selectionView.backgroundColor = UIColor(white: 1, alpha: 0.25)
        
        let checkmarkSize = selectionCheckView.bounds.size
        let checkmarkmargin:CGFloat = 2.0
        
        selectionCheckView.translatesAutoresizingMaskIntoConstraints = false
        selectionCheckView.widthAnchor.constraint(equalToConstant: checkmarkSize.width).isActive = true
        selectionCheckView.heightAnchor.constraint(equalToConstant: checkmarkSize.height).isActive = true
        selectionCheckView.bottomAnchor.constraint(equalTo: selectionView.bottomAnchor, constant: -checkmarkmargin).isActive = true
        selectionCheckView.trailingAnchor.constraint(equalTo: selectionView.trailingAnchor, constant: -checkmarkmargin).isActive = true
        
        imageView.accessibilityIgnoresInvertColors = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.image = nil
        indexPath = nil
        decorationView.isHidden = true
        
        if let imageRequestId = imageRequestId {
            PhotosManager.default.cachingImageManager.cancelImageRequest(imageRequestId)
        }
        imageRequestId = nil
    }

    func setAsset(_ asset: PHAsset, cachingOption: PHAssetRequestOption, at indexPath: IndexPath) {
        self.imageContentMode = cachingOption.contentMode
        self.indexPath = indexPath

        prepareForDisplay(with: asset)

        imageRequestId = PhotosManager.default.cachingImageManager.requestImage(for: asset, option: cachingOption) { [weak self] (image, info) in
            guard self?.indexPath == indexPath else { return }
            DispatchQueue.main.async{
                self?.imageView.image = image
                self?.updateDecorationContents(with: asset)
                self?.imageRequestId = nil
            }
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
            contentView.alpha = isEnabled ? 1 : 0.4
        }
    }

    private func updateSelectionState(){
        selectionCheckView.checked = isSelected
        selectionCheckView.visible = isEnabled

        if isEnabled{
            selectionView.visible = isSelected
        } else{
            selectionView.visible = true
        }

        if selectionView.visible{
            selectionView.backgroundColor = UIColor(white: 1, alpha: isEnabled ? 0.25: 0.5)
        }
    }
    
    // MARK: - Prepare rendering
    
    private func prepareForDisplay(with asset: PHAsset) {
        updateImageViewContentMode()
        
        let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)

        //TODO: (maybe calculation with "0" can be a cause of NaN from AVMakeRect(aspectRatio ) investigate and remove this line. https://console.firebase.google.com/u/0/project/batch-photos/crashlytics/app/ios:com.stells.batch/issues/5bdf4175f8b88c29638e515b?time=last-seven-days&sessionId=5418048137684eaca48a977aeed73aa1_DNE_0_v2
        imageViewSize = (imageContentMode == .aspectFit && imageSize.minLength > 0 ? AVMakeRect(aspectRatio: imageSize, insideRect: bounds.inset(by: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))) : bounds).size
    }
    
    private func updateDecorationContents(with asset: PHAsset) {
        //duration label
        cellIconAsLabel.isHidden = asset.mediaType != .video
        if !cellIconAsLabel.isHidden{
            let format = PhotoCollectionViewCell.durationLabelFormat
            if asset.duration > 3600 {
                format.allowedUnits.insert(.hour)
            }
            
            let milliseconds = asset.duration.truncatingRemainder(dividingBy: 60) / 60
            cellIconAsLabel.text = PhotoCollectionViewCell.durationLabelFormat.string(from: asset.duration + ceil(milliseconds))
        }

        //badge icon
        var iconAsImage:UIImage? // 46
        if asset.mediaSubtypes.contains(.photoLive){
            iconAsImage = PhotoCollectionViewCellImages.CellImage.LivePhotoIconImage
        }
        else if asset.imageType == .animatedGIF{
            iconAsImage = PhotoCollectionViewCellImages.CellImage.GIFIconImage
        }
        else if asset.imageType == .burst{
            iconAsImage = PhotoCollectionViewCellImages.CellImage.BurstIconImage
        }
        else if asset.mediaSubtypes.contains(.photoDepthEffect){
            iconAsImage = PhotoCollectionViewCellImages.CellImage.DepthIconImage
        }
        else if asset.mediaSubtypes.contains(.photoPanorama){
            iconAsImage = PhotoCollectionViewCellImages.CellImage.PanoramaIconImage
        }
        //TOOD: find some way to access directly e.g. using pattern of physical file path. impossible currently.
//        else if asset.hasRawImage {
//            iconAsImage = PhotoCollectionViewCellImages.CellImage.RAWIconImage
//        }
        self.cellIconAsImageView.isHidden = iconAsImage == nil
        self.cellIconAsImageView.image = iconAsImage
        self.decorationView.isHidden = self.cellIconAsLabel.isHidden && self.cellIconAsImageView.isHidden
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
