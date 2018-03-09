//
//  PhotoEditViewController.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 10. 6..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit
import Hero
import AVFoundation
import Photos

protocol TransformEditViewControllerDelegate {
    func photoEditViewController(_ photoEditor: PhotoEditViewController, didFinishEditing editItem: StateValueSet<BatchAppPHAssetState>?, at indexPath: IndexPath?)
}

class PhotoEditViewController: AppDockViewController, UIScrollViewDelegate {
    @IBOutlet weak var photoZoomingView: UIScrollView!

    var delegate: TransformEditViewControllerDelegate?
    
    var zoomingContentView: UIView!
    var assetView: AssetView!
    var placeholderImage: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            assetView.image = placeholderImage
            layoutAssetView()
        }
    }
    var editItem = StateValueSet<BatchAppPHAssetState>()
    var placeholderView: UIView?
    var indexPathInBatch: IndexPath?
    
    var asset: PHAsset?
    var preferredTransform: CGAffineTransform = .identity
    
    var transitionID: String?

    let iOSStandardEditorBackgroundColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1)
    var actionItems: [UIPreviewActionItem]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit".localizedString

        view.backgroundColor = iOSStandardEditorBackgroundColor

        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = iOSStandardEditorBackgroundColor
        
        zoomingContentView = UIView(frame: view.bounds)
        photoZoomingView.addSubview(zoomingContentView)
        
        assetView = AssetView(frame: zoomingContentView.bounds)
        assetView.contentMode = .scaleAspectFit
        assetView.hero.id = transitionID
        zoomingContentView.addSubview(assetView)
        
        photoZoomingView.minimumZoomScale = 1
        photoZoomingView.maximumZoomScale = 4
        
//        editToolbar.borderColor = iOSStandardEditorBackgroundColor
//        editToolbar.toolbar.barStyle = .black
//        editToolbar.toolbar.tintColor = UIColor.white
//        editToolbar.toolbar.barTintColor = iOSStandardEditorBackgroundColor
        
        appDockView.barStyle = .black

        doneButton?.image = R.image.editDoneBarButton()
        
        assetView.preferredTransform = preferredTransform
        assetView.image = placeholderImage
        layoutAssetView()
        
        if let asset = asset {
            if asset.mediaType == .image {
                assetView.setImageAsset(asset, completion: { [unowned self] (image) in
                    self.assetView.image = image
                }, completionWithLivePhoto: { [unowned self] (livePhoto) in
                    self.assetView.livePhoto = livePhoto
                })
            }
            else if asset.mediaType == .video {
                assetView.setVideoAsset(asset, completion: { [unowned self] (playerItem) in
                    self.assetView.playerItem = playerItem
                    self.assetView.playVideoWithLooping()
                })
            }
        }


    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        BatchAppCenter.default.watch(\.currentIdentifier, id:"editor", options:[.new,.initial]) { appCenter, dict in

            appCenter.currentInstanceAs(TransformApp.self)?.config?.watch(\.transform, id:"editor\(TransformApp.info.identifier)") { (config, changed) in
                if let value = config.transform{
                    self.addTransformItem(value)
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        BatchAppCenter.default.currentInstanceAs(TransformApp.self)?.config?.unwatch(\.transform, forIds:["editor\(TransformApp.info.identifier)"])
        BatchAppCenter.default.unwatch(\.currentIdentifier, forIds:["editor"])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updatePreview()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParentViewController {
            placeholderView?.removeFromSuperview()
        }
    }
    
    // MARK: - Layout
    
    func layoutAssetView() {
        guard let asset = asset else { return }
        let preferredSize = asset.pixelSize.applying(preferredTransform).magnitude
        
        let boundingBox = UIEdgeInsetsInsetRect(photoZoomingView.bounds, UIEdgeInsets(top: safeAreaInsets.top, left: safeAreaInsets.left, bottom: appDockView.bounds.height, right: safeAreaInsets.right))

        let actualContentSize = preferredSize.applying(editItem.transform).magnitude.aspectFit(in: boundingBox.size)
        let contentSize = actualContentSize.applying(editItem.transform.inverted()).magnitude
        
        zoomingContentView.frame.size = contentSize
        
        assetView.frame.origin = .zero
        assetView.frame.size = contentSize
        photoZoomingView.contentSize = actualContentSize
        
        zoomingContentView.center = CGPoint(x: boundingBox.width / 2, y: boundingBox.height / 2)
        assetView.center = CGPoint(x: contentSize.width / 2, y: contentSize.height / 2)
    }
    
    // MARK: - Navigation Bar Actions
    
    private func addTransformItem(_ transformItem: BatchAppPHAssetState) {
        editItem.append(transformItem)
        
        updatePreview()
    }
    
    private func updatePreview(_ completion: (() -> Void)? = nil) {
        layoutAssetView()
        
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: {
            self.assetView.layer.transform = self.editItem.transform3d
        }) { (finished) in
            completion?()
        }
    }
    
    // MARK: - Tool Bar Actions
    
    override func cancelButtonDidTap(sender: Any) {
        editItem.reset()
        
        updatePreview { [unowned self] in
            self.delegate?.photoEditViewController(self, didFinishEditing: nil, at: self.indexPathInBatch)
        }
    }
    
    override func doneButtonDidTap(sender: Any) {
        assetView.layer.transform = CATransform3DIdentity
        assetView.transform = editItem.transform
        
        placeholderView?.transform = editItem.transform
        delegate?.photoEditViewController(self, didFinishEditing: self.editItem, at: self.indexPathInBatch)
    }
    
    // MARK: - UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomingContentView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        UIView.animateUsingSpring(duration: 0.5, delay: 0, animations: {
            scrollView.zoomScale = 1
        }, completion: nil)
    }
}

extension PhotoEditViewController {
    override var previewActionItems: [UIPreviewActionItem] {
        guard let actionItems = actionItems, actionItems.count > 0 else { return super.previewActionItems }
        return actionItems
    }
}
