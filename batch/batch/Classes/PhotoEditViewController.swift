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

class PhotoEditViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var photoZoomingView: UIScrollView!
    
    var delegate: PhotoEditViewControllerDelegate?
    
    var imageView: UIImageView!
    var image: UIImage?
    var editItem = EditItem()
    var placeholderView: UIView?
    var indexPathInBatch: IndexPath?
    
    var transitionID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Edit"
        
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.heroID = transitionID
        photoZoomingView.addSubview(imageView)
        
        navigationController?.setToolbarHidden(false, animated: false)
        
        let toolBarItems = [
            UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(self.undoButtonDidTap)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Flip v", style: .plain, target: self, action: #selector(self.verticalFlipButtonDidTap)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Flip h", style: .plain, target: self, action: #selector(self.horizontalFlipButtonDidTap)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Rotate", style: .plain, target: self, action: #selector(self.rotationButtonDidTap)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneButtonDidTap))
        ]
        setToolbarItems(toolBarItems, animated: false)
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
            let scale = image.size.width / image.size.applying(editItem.transform).magnitude.width
            
            imageView.frame.size = image.size.aspectFit(in: photoZoomingView.bounds.size).applying(CGAffineTransform(scaleX: scale, y: scale))
            imageView.center = CGPoint(x: photoZoomingView.bounds.width / 2, y: photoZoomingView.bounds.height / 2)
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
    
    private func updatePreview() {
        updateImageViewLayout()
        
        toolbarItems?.first?.isEnabled = !editItem.transformItems.isEmpty
        
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: {
            self.imageView.layer.transform = self.editItem.transform3d
        }) { (finished) in
            
        }
    }
    
    // MARK: - Tool Bar Actions
    
    func horizontalFlipButtonDidTap(sender: Any) {
        addTransformItem(HorizontalFlipTransformItem())
    }
    
    func verticalFlipButtonDidTap(sender: Any) {
        addTransformItem(VerticalFlipTransformItem())
    }
    
    func rotationButtonDidTap(sender: Any) {
        addTransformItem(RotationTransformItem(degrees: 90))
    }
    
    func doneButtonDidTap(sender: Any) {
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
        return imageView
    }
}
