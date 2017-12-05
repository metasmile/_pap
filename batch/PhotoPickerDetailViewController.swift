//
// Created by BLACKGENE on 05/12/2017.
// Copyright (c) 2017 Stells. All rights reserved.
//

import UIKit
import Photos

class PhotoPickerDetailViewController: UIViewController {

    private lazy var imageView: STAssetView = {
        let assetView = STAssetView()
        assetView.contentMode = .scaleAspectFit
        assetView.translatesAutoresizingMaskIntoConstraints = false
        return assetView
    }()

    var asset: PHAsset? {
        didSet {

            if asset != nil{
                imageView.setAsset(asset!, cancelDrawingIfNeeded: { [weak self] in
                    return false
                })
            }

        }
    }

    // MARK: - Private Properties

    fileprivate let imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    fileprivate let messageInsets = UIEdgeInsets(top: 32, left: 14, bottom: 0, right: 16)
    fileprivate let textInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

    fileprivate lazy var bubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.blue
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    fileprivate lazy var messageView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    fileprivate lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Detail"

        // Configure view
        view.backgroundColor = UIColor.white

        // Compose child views
        bubbleView.addSubview(textLabel)
        messageView.addSubview(imageView)
        messageView.addSubview(bubbleView)
        view.addSubview(messageView)

        // Attach the message view

        NSLayoutConstraint(
                item: messageView,
                attribute: .top,
                relatedBy: .equal,
                toItem: topLayoutGuide,
                attribute: .bottom,
                multiplier: 1,
                constant: messageInsets.top).isActive = true

        // Attach the image view
        imageView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        imageView.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)

        imageView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true

        // Attach the bubble view
        bubbleView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8).isActive = true
    }
}
