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
    var batchRequest: BatchEditSequenceRequest?
    
    var hasChanges: Bool {
        return batchEditItems.map({ $0.editItem.hasChanges }).contains(true)
    }
    
    var isProcessing: Bool {
        return batchRequest != nil
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
//        batchEditItem.indexPath = indexPath

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

let TaskManager = AppTaskManager.shared(6)

extension BatchPreviewView {
    func runBatchProcessing() {
        guard batchRequest == nil else { return }
        
        delegate?.batchPreviewViewWillBeginEdit(self)
        
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)


        //TODO: TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP
        batchEditItems.forEach { item in
            TaskManager.append(request: AppTaskRequest(TransformApp.self, item) { res, cancel in
                print(item)
            })
        }

        let reaction = AppTaskReaction()
        reaction.when { result, progress, respondables, respondables1 in
            print("------------- progress",progress)

            let _result = result.results.first?.result

            print(_result)

//            guard let _result = result.results.first?.result as? TransformAppTaskResult else{
////                , let _resultIndexPath = _result.indexPath else {
//                assert(false)
//                return
//            }

//            guard self.isProcessing else { return }
            DispatchQueue.main.async { [unowned self] in
                self.delegate?.batchPreviewView(self, didUpdateProgress: progress)
//                self.collectionView.scrollToItem(at: _resultIndexPath, at: .centeredHorizontally, animated: true)
            }

        }
        reaction.when { resultsByApps, allResults, respondables in
            print(allResults)
            let results = allResults as! [TransformAppTaskResult]

//            guard let results = allResults as! [TransformAppTaskResult] else {
//                return
//            }

//            guard self.isProcessing else { return }

            DispatchQueue.main.async { [unowned self] in
                self.delegate?.batchPreviewViewWillBeginExport(self)
            }

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
                    self.batchRequest = nil
                }
            })


        }
        TaskManager.perform(reaction)
        //TODO: TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP


        //TODO: Original
//        batchRequest = BatchEditSequenceRequest()
//        batchRequest?.perform(batchEditItems.map({ BatchEditRequest($0) }), { (progress, idx) in
//            guard self.isProcessing else { return }
//            DispatchQueue.main.async { [unowned self] in
//                self.delegate?.batchPreviewView(self, didUpdateProgress: progress)
//
//                guard let item = idx, item + 1 < self.batchEditItems.count else { return }
//                self.collectionView.scrollToItem(at: IndexPath(item: item + 1, section: 0), at: .centeredHorizontally, animated: true)
//            }
//        }) { (results) in
//            guard self.isProcessing else { return }
//
//            DispatchQueue.main.async { [unowned self] in
//                self.delegate?.batchPreviewViewWillBeginExport(self)
//            }
//
//            PHPhotoLibrary.shared().performChanges({
//                for result in results {
//                    PHAssetChangeRequest(for: result.asset).contentEditingOutput = result.contentEditingOutput
//                }
//            }, completionHandler: { (success, info) in
//                DispatchQueue.main.async { [unowned self] in
//                    if success {
//                        self.delegate?.batchPreviewViewDidEndEdit(self)
//                    }
//                    else {
//                        self.delegate?.batchPreviewViewDidCancelEdit(self)
//                    }
//                    self.batchRequest = nil
//                }
//            })
//        }
    }
    
    func cancelBatchProcessing() {
        batchRequest?.cancel()
        batchRequest = nil
        
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
