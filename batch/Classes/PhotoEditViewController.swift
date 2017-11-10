//
//  PhotoEditViewController.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 10. 6..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit
import Hero

protocol PhotoEditViewControllerDelegate {
    func photoEditViewController(_ photoEditor: PhotoEditViewController, didFinishEditing editItem: EditItem?, at indexPath: IndexPath?)
}

class PhotoEditViewController: EditToolbarViewController, UIScrollViewDelegate {
    @IBOutlet weak var photoZoomingView: UIScrollView!
    @IBOutlet weak var editToolbar: FloatingToolbar!
    
    var delegate: PhotoEditViewControllerDelegate?
    
    var zoomingContentView: UIView!
    var imageView: UIImageView!
    var image: UIImage?
    var editItem = EditItem()
    var placeholderView: UIView?
    var indexPathInBatch: IndexPath?
    
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
        
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.heroID = transitionID
        zoomingContentView.addSubview(imageView)
        
        photoZoomingView.minimumZoomScale = 1
        photoZoomingView.maximumZoomScale = 4
        
        editToolbar.borderColor = iOSStandardEditorBackgroundColor
        editToolbar.toolbar.barStyle = .black
        editToolbar.toolbar.tintColor = UIColor.white
        editToolbar.toolbar.barTintColor = iOSStandardEditorBackgroundColor
        
        editToolbar.toolbarItems = editToolbarItems
        
        doneButton?.image = UIImage(named: "Edit Done Bar Button")
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
    
    func updateImageViewLayout() {
        if let image = image {
            let boundingBox = UIEdgeInsetsInsetRect(photoZoomingView.bounds, UIEdgeInsets(top: safeAreaInsets.top, left: safeAreaInsets.left, bottom: safeAreaInsets.bottom + editToolbar.bounds.height, right: safeAreaInsets.right))
            
            let actualContentSize = image.size.applying(editItem.transform).magnitude.aspectFit(in: boundingBox.size)
            let contentSize = actualContentSize.applying(editItem.transform.inverted()).magnitude
            
            zoomingContentView.frame.size = contentSize
            
            imageView.frame.origin = .zero
            imageView.frame.size = contentSize
            photoZoomingView.contentSize = actualContentSize
            
            zoomingContentView.center = CGPoint(x: boundingBox.width / 2, y: boundingBox.height / 2)
            imageView.center = CGPoint(x: contentSize.width / 2, y: contentSize.height / 2)
        }
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
        updateImageViewLayout()
        
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: {
            self.imageView.layer.transform = self.editItem.transform3d
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
            
            self.dismiss(animated: true, completion: {
                self.placeholderView?.removeFromSuperview()
            })
        }
    }
    
    override func doneButtonDidTap(sender: Any) {
        imageView.layer.transform = CATransform3DIdentity
        imageView.transform = editItem.transform
        
        placeholderView?.transform = editItem.transform
        delegate?.photoEditViewController(self, didFinishEditing: self.editItem, at: self.indexPathInBatch)
        
        dismiss(animated: true, completion: {
            self.placeholderView?.removeFromSuperview()
        })
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

