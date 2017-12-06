//
// Created by BLACKGENE on 05/12/2017.
// Copyright (c) 2017 Stells. All rights reserved.
//

import UIKit
import Photos

class PhotoPickerDetailViewController: UIViewController {

    var asset: PHAsset?
    var actionItems:[UIPreviewActionItem]?

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

            let w = self.view.bounds.width
            var f = assetView.frame
            f.size = CGSize(width: w, height: w/(asset.size.width/asset.size.height))

            assetView.frame = f
            assetView.asset = asset

            self.preferredContentSize = assetView.bounds.size

            assetView.playAny()
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
