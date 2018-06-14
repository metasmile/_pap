//
// Created by BLACKGENE on 05/12/2017.
// Copyright (c) 2017 Stells. All rights reserved.
//

import UIKit
import Photos

class PhotoPickerDetailViewController: UIViewController {
    var assetItem: PHAssetItem<ImageEditStateValue>?
    var placeholderImage: UIImage?
    var actionItems:[UIPreviewActionItem]?
    
    private lazy var assetView: AppUIAssetView = {
        let assetView = AppUIAssetView()
        assetView.contentMode = .scaleAspectFit
        assetView.translatesAutoresizingMaskIntoConstraints = false
        return assetView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Detail".localized

        if let asset = assetItem?.asset {
            view.addSubview(assetView)

            let preferredTransform = assetItem?.editState.transform ?? .identity
            let preferredSize = asset.pixelSize
            
            let boundingSize = preferredSize.width > preferredSize.height ? view.bounds.size.applying(preferredTransform).magnitude : view.bounds.size
            
            let actualContentSize = preferredSize.applying(preferredTransform).magnitude.aspectFit(in: boundingSize)
            let contentSize = preferredSize.aspectFit(in: boundingSize)
            
            assetView.frame.origin = .zero
            assetView.frame.size = contentSize
            
            assetView.center = CGPoint(x: actualContentSize.width / 2, y: actualContentSize.height / 2)
            
            assetView.image = placeholderImage
            assetView.preferredTransform = preferredTransform
            
            assetView.setAsset(asset, completion: {
                self.assetView.applyEditState(self.assetItem?.editState)
            })
            assetView.playAny()
            
            self.preferredContentSize = actualContentSize
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        assetView.stopAny()
    }

    override var previewActionItems: [UIPreviewActionItem] {
        guard let actionItems = actionItems, actionItems.count > 0 else { return super.previewActionItems }
        return actionItems
    }
}
