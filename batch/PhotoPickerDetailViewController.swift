//
// Created by BLACKGENE on 05/12/2017.
// Copyright (c) 2017 Stells. All rights reserved.
//

import UIKit
import Photos

class PhotoPickerDetailViewController: UIViewController {

    var asset: PHAsset?
    var actionItems:[UIPreviewActionItem]?
    var batchEditItem: BatchEditItem?

    private lazy var assetView: STAssetView = {
        let assetView = STAssetView()
        assetView.contentMode = .scaleAspectFill
        assetView.translatesAutoresizingMaskIntoConstraints = false
        return assetView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Detail".localizedString

        if let asset = asset {
            view.addSubview(assetView)
            
            let preferredTransform = batchEditItem?.editItem.transform ?? .identity
            let actualContentSize = asset.size.applying(preferredTransform).magnitude.aspectFit(in: view.bounds.size)
            let contentSize = asset.size.aspectFit(in: view.bounds.size)
            
            assetView.frame.origin = .zero
            assetView.frame.size = contentSize
            
            assetView.center = CGPoint(x: actualContentSize.width / 2, y: actualContentSize.height / 2)
            
            assetView.preferredTransform = preferredTransform
            assetView.asset = asset
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
