//
//  BatchPreviewView.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 6..
//  Copyright © 2017년 Stells. All rights reserved.
//

import UIKit
import Photos

protocol BatchPreviewViewDelegate {
    func batchPreviewView(_ view: BatchPreviewView, didSelectItemAt indexPath: IndexPath)
    func batchPreviewViewWillBeginExport(_ view: BatchPreviewView)
    func batchPreviewView(_ view: BatchPreviewView, didUpdateProgress progress: Float)
    func batchPreviewViewWillBeginEdit(_ view: BatchPreviewView)
    func batchPreviewViewDidEndEdit(_ view: BatchPreviewView)
    func batchPreviewViewDidCancelEdit(_ view: BatchPreviewView)
}

class BatchPreviewView: CustomView {
    @IBOutlet weak var collectionView: UICollectionView!
    fileprivate (set) var batchEditItems = [TransformAppEditItem]()
    var delegate: BatchPreviewViewDelegate?

    let TaskManager = AppTaskManager.shared(4)
    
    var hasChanges: Bool {
        return batchEditItems.map({ $0.editItem.hasChanges }).contains(true)
    }
    
    var isProcessing: Bool {
        return TaskManager.count > 0
    }
    
    override func initialize() {
        super.initialize()
        
        collectionView.register(PreviewCollectionViewCell.self, forCellWithReuseIdentifier: "PreviewCollectionViewCell")
        updateAlignment(animated: false)
    }
}

extension BatchPreviewView {
    func addTransformItem(_ transformItem: TransformItem) {
        guard !isProcessing else { return }
        
        for batchEditItem in batchEditItems {
            batchEditItem.editItem.addTransformItem(transformItem)
        }
        
        updatePreviews()
    }
    
    func resetTransformItems() {
        guard !isProcessing else { return }
        
        for batchEditItem in batchEditItems {
            batchEditItem.editItem.resetTransforms()
        }
        
        updatePreviews()
    }
    
    private func updatePreviews(animated: Bool = true, completion: (() -> Void)? = nil) {
//        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
//        let visibleIndexPath = collectionView.indexPathForItem(at: CGPoint(x: visibleRect.midX, y: visibleRect.midY)) ?? collectionView.indexPathsForVisibleItems.last
        
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.performBatchUpdates({
            
        }) { (finished) in
//            guard let indexPath = visibleIndexPath, animated == true else { completion?(); return }
//            self.collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: false)
            completion?()
        }
        
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        for indexPath in visibleIndexPaths {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? PreviewCollectionViewCell else { continue }
            cell.setImageEditItem(self.batchEditItems[indexPath.item].editItem, animated: animated)
        }
        
        updateAlignment(animated: false)
    }
}

extension BatchPreviewView {
    func addBatchEditItem(with asset: PHAsset?) {
        guard !batchEditItems.contains(where: { $0.asset == asset }) else { return }
        
        let indexPath = IndexPath(item: batchEditItems.count, section: 0)

        let batchEditItem = TransformAppEditItem()
        batchEditItem.asset = asset
        batchEditItem.indexSection = (indexPath.item, indexPath.section)

        batchEditItems.append(batchEditItem)

        collectionView.insertItems(at: [indexPath])
        updateAlignment()
        
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    func removeBatchEditItem(with asset: PHAsset?) {
        guard let item = batchEditItems.index(where: { $0.asset == asset }) else { return }
        
        let indexPath = IndexPath(item: item, section: 0)
        
        batchEditItems.remove(at: item)
        collectionView.deleteItems(at: [indexPath])
        updateAlignment()
        
        if batchEditItems.count > 0 {
            let nearestItem = max(min(item - 1, batchEditItems.count - 2), 0)
            collectionView.scrollToItem(at: IndexPath(item: nearestItem, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    
    func removeAllBatchEditItems() {
        let indexPaths = (0..<batchEditItems.count).map({ IndexPath(item: $0, section: 0) })
        
        batchEditItems.removeAll()
        collectionView.deleteItems(at: indexPaths)
        updateAlignment()
    }
    
    func updateAlignment(animated: Bool = true) {
        collectionView.collectionViewLayout.prepare()
        let contentWidth = collectionView.collectionViewLayout.collectionViewContentSize.width
        var contentInset = collectionView.contentInset
        if contentWidth > collectionView.bounds.width {
            contentInset.left = 0
            contentInset.right = 0
        }
        else {
            let inset = (collectionView.bounds.width - contentWidth) / 2
            contentInset.left = inset
            contentInset.right = inset
        }
        
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.collectionView.contentInset = contentInset
            }
        }
        else {
            collectionView.contentInset = contentInset
        }
    }
    
    func reloadBatchEditItems() {
        updatePreviews()
    }
}

extension BatchPreviewView {
    func runBatchProcessing() {

        //TODO: append dynamically more items where Set(batchEditItems) - Set(alreadyqueued Items) TaskManager.query(by:_)
        delegate?.batchPreviewViewWillBeginEdit(self)
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)

        //TODO: TaskManager.append immediatly from UI action instead of using "batchEditItems"
        batchEditItems.forEach { item in
            TaskManager.append(request: AppTaskRequest(TransformApp.self, item))
        }

        let reaction = AppTaskReaction().when { response, progress, remained, completed in
            guard let _ = response.result as? TransformAppTaskRespondable else{
                assert(false,"Result item type is wrong.")
                return
            }

            let requestedParam = response.request.param as? TransformAppEditItem
            let totalCount = remained.count+completed.count

            self.delegate?.batchPreviewView(self, didUpdateProgress: progress)

            if let param = requestedParam, let (_index, _section) = param.indexSection {
                self.collectionView.scrollToItem(at: IndexPath(item: Int(Float(totalCount-1)*progress), section: _section), at: .centeredHorizontally, animated: true)
            }

        }.when { resultsByApps, respondables in
            assert(!self.isProcessing)

            let results = respondables.flatMap { $0.result as? TransformAppTaskRespondable }

            self.delegate?.batchPreviewViewWillBeginExport(self)

            PHPhotoLibrary.shared().performChanges({
                for result in results {
                    PHAssetChangeRequest(for: result.asset).contentEditingOutput = result.contentEditingOutput
                }
            }, completionHandler: { (success, info) in
                DispatchQueue.main.async { [unowned self] in
                    if success {
                        self.delegate?.batchPreviewViewDidEndEdit(self)
                    }
                    else {
                        self.delegate?.batchPreviewViewDidCancelEdit(self)
                    }
                }
            })
        }

        TaskManager.perform(reaction)
    }
    
    func cancelBatchProcessing() {
        assert(self.isProcessing)

        TaskManager.cancel()

        delegate?.batchPreviewViewDidCancelEdit(self)
    }
}

extension BatchPreviewView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return batchEditItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreviewCollectionViewCell", for: indexPath) as! PreviewCollectionViewCell
        cell.setBatchEditItemForPreview(batchEditItems[indexPath.item], at: indexPath)
        return cell
    }
}

extension BatchPreviewView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return !isProcessing
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.batchPreviewView(self, didSelectItemAt: indexPath)
    }
}

extension BatchPreviewView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let asset = batchEditItems[indexPath.item].asset else { return .zero }
        let contentInset: UIEdgeInsets
        if #available(iOS 11.0, *) {
            contentInset = collectionView.adjustedContentInset
        }
        else {
            contentInset = collectionView.contentInset
        }
        
        let contentSize = UIEdgeInsetsInsetRect(collectionView.bounds, contentInset).size
        let boundingSize = CGSize(width: contentSize.height, height: contentSize.height)
        let photoSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight).aspectFit(in: boundingSize)
        let cellSize = photoSize.applying(batchEditItems[indexPath.item].editItem.transform).magnitude
        return CGSize(width: cellSize.width, height: contentSize.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
}
