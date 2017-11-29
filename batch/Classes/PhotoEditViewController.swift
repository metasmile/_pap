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

protocol PhotoEditViewControllerDelegate {
    func photoEditViewController(_ photoEditor: PhotoEditViewController, didFinishEditing editItem: EditItem?, at indexPath: IndexPath?)
}

class PhotoEditViewController: EditToolbarViewController, UIScrollViewDelegate {
    @IBOutlet weak var photoZoomingView: UIScrollView!
    @IBOutlet weak var editToolbar: FloatingToolbar!
    
    var delegate: PhotoEditViewControllerDelegate?
    
    var zoomingContentView: UIView!
    var assetView: STAssetView!
    var image: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            updateAssetViewLayout()
        }
    }
    var editItem = EditItem()
    var placeholderView: UIView?
    var indexPathInBatch: IndexPath?
    
    var asset: PHAsset?
    var preferredTransform: CGAffineTransform = .identity
    
    var transitionID: String?

    let iOSStandardEditorBackgroundColor = UIColor(red:0.11, green:0.11, blue:0.11, alpha:1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Edit".localizedString

        view.backgroundColor = iOSStandardEditorBackgroundColor

        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = iOSStandardEditorBackgroundColor
        
        zoomingContentView = UIView(frame: view.bounds)
        photoZoomingView.addSubview(zoomingContentView)
        
        assetView = STAssetView(frame: zoomingContentView.bounds)
        assetView.contentMode = .scaleAspectFit
        assetView.heroID = transitionID
        zoomingContentView.addSubview(assetView)
        
        photoZoomingView.minimumZoomScale = 1
        photoZoomingView.maximumZoomScale = 4
        
        editToolbar.borderColor = iOSStandardEditorBackgroundColor
        editToolbar.toolbar.barStyle = .black
        editToolbar.toolbar.tintColor = UIColor.white
        editToolbar.toolbar.barTintColor = iOSStandardEditorBackgroundColor
        
        editToolbar.toolbarItems = editToolbarItems
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = doneButton
        
        doneButton?.image = UIImage(named: "Edit Done Bar Button")
        
        assetView.preferredTransform = preferredTransform
        
        if let asset = asset {
            if asset.mediaType == .image {
                assetView.setImageAsset(asset, completion: { [unowned self] (image) in
                    self.image = image?.applyTransform(self.preferredTransform)
                    self.assetView.image = self.image
                }, completionWithLivePhoto: { [unowned self] (livePhoto) in
                    self.assetView.livePhoto = livePhoto
                })
            }
            else if asset.mediaType == .video {
                assetView.setVideoAsset(asset, completion: { [unowned self] (playerItem) in
                    self.assetView.playerItem = playerItem
                    self.assetView.playWithLooping()
                })
            }
        }
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
    
    func updateAssetViewLayout() {
        guard let image = image else { return }
        
        let boundingBox = UIEdgeInsetsInsetRect(photoZoomingView.bounds, UIEdgeInsets(top: safeAreaInsets.top, left: safeAreaInsets.left, bottom: safeAreaInsets.bottom + editToolbar.bounds.height, right: safeAreaInsets.right))
        
        let actualContentSize = image.size.applying(editItem.transform).magnitude.aspectFit(in: boundingBox.size)
        let contentSize = actualContentSize.applying(editItem.transform.inverted()).magnitude
        
        zoomingContentView.frame.size = contentSize
        
        assetView.frame.origin = .zero
        assetView.frame.size = contentSize
        photoZoomingView.contentSize = actualContentSize
        
        zoomingContentView.center = CGPoint(x: boundingBox.width / 2, y: boundingBox.height / 2)
        assetView.center = CGPoint(x: contentSize.width / 2, y: contentSize.height / 2)
        
        assetView.image = image
    }
    
    // MARK: - Navigation Bar Actions
    
    func undoButtonDidTap(sender: Any) {
        guard !editItem.transformItems.isEmpty else { return }
        editItem.transformItems.removeLast()
        
        updatePreview()
    }
    
    private func addTransformItem(_ transformItem: TransformItem) {
        editItem.addTransformItem(transformItem)
        
        updatePreview()
    }
    
    private func updatePreview(_ completion: (() -> Void)? = nil) {
        updateAssetViewLayout()
        
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: {
            self.assetView.layer.transform = self.editItem.transform3d
        }) { (finished) in
            completion?()
        }
    }
    
    // MARK: - Tool Bar Actions
    
    override func horizontalFlipButtonDidTap(sender: Any) {
        addTransformItem(HorizontalFlipTransformItem())
    }
    
    override func verticalFlipButtonDidTap(sender: Any) {
        addTransformItem(VerticalFlipTransformItem())
    }
    
    override func rotationLeftButtonDidTap(sender: Any) {
        addTransformItem(RotationTransformItem(degrees: -90))
    }
    
    override func rotationRightButtonDidTap(sender: Any) {
        addTransformItem(RotationTransformItem(degrees: 90))
    }
    
    override func cancelButtonDidTap(sender: Any) {
        editItem.transformItems.removeAll()
        
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

