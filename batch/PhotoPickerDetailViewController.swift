//
// Created by BLACKGENE on 05/12/2017.
// Copyright (c) 2017 Stells. All rights reserved.
//

import UIKit
import Photos

class PhotoPickerDetailViewController: UIViewController {

    var asset: PHAsset?
//    {
//        didSet {
//            if let asset = asset {
//                assetView.asset = asset
//            }
//        }
//    }

    private lazy var assetView: STAssetView = {
        let assetView = STAssetView()
        assetView.contentMode = .scaleAspectFill
        assetView.translatesAutoresizingMaskIntoConstraints = false
        return assetView
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Detail"

        if let asset = asset {
            let w = self.view.bounds.width
            assetView.frame = CGRect(x:0, y:0, width: w, height: w/(asset.size.width/asset.size.height))
            assetView.asset = asset
        }

        view.addSubview(assetView)

        self.preferredContentSize = assetView.bounds.size

        assetView.playAny()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        assetView.stopAny()
    }

    override var previewActionItems: [UIPreviewActionItem] {
        return [UIPreviewAction(title: "Add This Item", style: .default) { action, controller in

        }]
    }
}
