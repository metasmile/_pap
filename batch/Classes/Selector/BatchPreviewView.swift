//
//  BatchPreviewView.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 6..
//  Copyright © 2017년 Stells. All rights reserved.
//

import UIKit
import Photos
import Crashlytics

protocol BatchPreviewViewDelegate {
    func batchPreviewView(_ view: BatchPreviewView, didSelectItemAt indexPath: IndexPath)
    func batchPreviewViewWillBeginExport(_ view: BatchPreviewView)

    func batchPreviewView(_ view: BatchPreviewView, didUpdateProgress progress: Float)
    func batchPreviewViewDidCancelProgress(_ view: BatchPreviewView)

    func batchPreviewViewWillBeginEdit(_ view: BatchPreviewView)
    func batchPreviewViewDidEndEdit(_ view: BatchPreviewView)
    func batchPreviewViewDidCancelEdit(_ view: BatchPreviewView)
}

class BatchPreviewView: CustomView {
    @IBOutlet weak var collectionView: UICollectionView!
    fileprivate (set) var assetItems = [PHAssetItem<BatchAppPHAssetState>]()
    var delegate: BatchPreviewViewDelegate?

    var hasChanges: Bool {
        return assetItems.map({ $0.editState.hasChanges }).contains(true)
    }
    
    var isProcessing: Bool {
        return BatchAppCenter.default.task.count > 0
    }
    
    override func initialize() {
        super.initialize()

        print("[i] BatchAppCenter.default.task.maxConcurrentCount: ", BatchAppCenter.default.task.maxConcurrentCount)
        
        collectionView.register(PreviewCollectionViewCell.self, forCellWithReuseIdentifier: "PreviewCollectionViewCell")
        updateCollectionViewAlignment(animated: false)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: super.intrinsicContentSize.width, height: 44)
    }
}

extension BatchPreviewView {
    func addTransformItem(_ transformItem: BatchAppPHAssetState) {
        guard !isProcessing else { return }
        
        for item in assetItems {
            item.editState.append(transformItem)
        }
        
        updatePreviews()
    }
    
    func resetTransformItems() {
        guard !isProcessing else { return }
        
        for item in assetItems {
            item.editState.reset()
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
            cell.setImageEditItem(self.assetItems[indexPath.item].editState, animated: animated)
        }
        
        updateCollectionViewAlignment(animated: false)
    }
}

extension BatchPreviewView{
    func appendCollectionViewItem(with asset: PHAsset) -> IndexPath? {
        guard let insertedIndexPath = putAssetItem(for:asset) else {
            return nil
        }

        self.collectionView.insertItems(at: [insertedIndexPath])
        self.updateCollectionViewAlignment()
        self.collectionView.scrollToItem(at: insertedIndexPath, at: .centeredHorizontally, animated: true)

        return insertedIndexPath
    }

    func removeCollectionViewItem(with asset: PHAsset?) {
        guard let _asset = asset, let indexPath = removeAssetItem(for:_asset) else {
            return
        }

        collectionView.deleteItems(at: [indexPath])
        updateCollectionViewAlignment()

        if assetItems.count > 0 {
            let nearestItem = max(min(indexPath.item - 1, assetItems.count - 2), 0)
            collectionView.scrollToItem(at: IndexPath(item: nearestItem, section: 0), at: .centeredHorizontally, animated: true)
        }
    }

    func removeAllCollectionViewItems() {
        let indexPaths = (0..<assetItems.count).map({ IndexPath(item: $0, section: 0) })

        assetItems.removeAll()
        collectionView.deleteItems(at: indexPaths)
        updateCollectionViewAlignment()
    }

    func updateCollectionViewAlignment(animated: Bool = true) {
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

    func reloadCollectionViewItems() {
        updatePreviews()
    }
}

extension BatchPreviewView {

    @discardableResult
    func putAssetItem(for asset: PHAsset) -> IndexPath? {

        guard let item = createAssetItem(for:asset) else{
            return nil
        }

        var insertedIndex = -1

        if let _indexOfAsset = assetItems.index(where: { $0.asset == asset }){
            assetItems[_indexOfAsset] = item
            insertedIndex = _indexOfAsset

        }else{
            insertedIndex = assetItems.count
            assetItems.append(item)
        }

        let currentSection = 0 //TODO: collectionView.currentSection
        let insertedIndexPath = IndexPath(item: insertedIndex, section: currentSection)

        item.indexPath = insertedIndexPath

        return insertedIndexPath
    }

    func createAssetItem(for asset: PHAsset) -> PHAssetItem<BatchAppPHAssetState>? {
        guard let app = BatchAppCenter.default.current else { return nil }

        if let itemType = app.paramType as? PHAssetParamable.Type
        , let item = itemType.init(asset) as? PHAssetItem<BatchAppPHAssetState>{
            return item

        } else{
            assert(false, "[!] Unable to create, or does not implement yet for param type of \(app.info.appType)")
            return nil
        }
    }

    func removeAssetItem(for asset: PHAsset) -> IndexPath? {
        guard let item = assetItems.index(where: { $0.asset == asset }) else {
            return nil
        }

        assetItems.remove(at: item)

        return IndexPath(item: item, section: 0)
    }

    func reloadAllAssetItems() {
        for item in self.assetItems {
            putAssetItem(for: item.asset)
        }
    }
}

extension BatchPreviewView {

    @discardableResult
    func runBatchProcessing() -> Bool {
        let targetSection = 0 //TODO: previously support multiple sections

        guard let app = BatchAppCenter.default.current, collectionView.numberOfItems(inSection: targetSection) > 0 else {
            assert(false, "selected app does not exist.")
            return false
        }

        //TODO: append dynamically more items where Set(EditItems) - Set(alreadyqueued Items) BatchAppCenter.default.task.query(by:_)
        delegate?.batchPreviewViewWillBeginEdit(self)

        collectionView.scrollToItem(at: IndexPath(item: 0, section: targetSection), at: .centeredHorizontally, animated: true)
true
        //TODO: BatchAppCenter.default.task.append immediatly from UI action instead of using "EditItems"
        assetItems.forEach { item in
            BatchAppCenter.default.task.append(request: AppTaskRequest(app, item))
        }

        let reaction = AppTaskReaction()

        reaction.when(progress:{ response, progress, remained, completed in
            assert(response.info.state != .completed || response.info.state == .completed && response.result != nil, "task state is .completed but result is nil")

            let requestedParam = response.request.param as? PHAssetItem<BatchAppPHAssetState>
            let totalCount = remained.count+completed.count

            switch (response.info.state) {
                case .completed:
                    self.delegate?.batchPreviewView(self, didUpdateProgress: progress)

                    if let param = requestedParam, let index = param.indexPath {
                        self.collectionView.scrollToItem(at: IndexPath(item: Int(Float(totalCount-1)*progress), section: index.section), at: .centeredHorizontally, animated: true)
                    }

                case .cancelled:
                    self.delegate?.batchPreviewViewDidCancelProgress(self)

                default: break
            }

        }).will(finish: { resultsByApps, respondables in

            self.delegate?.batchPreviewViewWillBeginExport(self)


        }).did(finish: { resultsByApps, respondables in
            assert(!self.isProcessing)

            self.delegate?.batchPreviewViewDidEndEdit(self)

            //log
            for (app, results) in resultsByApps{
                for r in results{
                    if let e = r.info.error{
                        Crashlytics.sharedInstance().recordError(e, withAdditionalUserInfo: [
                            "app.identifier":app.identifier
                            ,"task.state": "\(r.info.state)"
                        ])
                    }
                }
            }
        })

        BatchAppCenter.default.task.perform(reaction)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchProgressChanged), name: RemoteSourceFetchNotification.Name.progressChanged, object: nil)

        return true
    }
    
    @objc func fetchProgressChanged(sender: NSNotification) {
        print(sender.userInfo?[RemoteSourceFetchNotification.UserInfo.Key.progress])
    }
    
    func cancelBatchProcessing() {
        assert(self.isProcessing)

        BatchAppCenter.default.task.cancel()

        delegate?.batchPreviewViewDidCancelEdit(self)
    }
}

extension BatchPreviewView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreviewCollectionViewCell", for: indexPath) as! PreviewCollectionViewCell
        cell.setEditItemForPreview(assetItems[indexPath.item], at: indexPath)
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
        let asset = assetItems[indexPath.item].asset

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
        let cellSize = photoSize.applying(assetItems[indexPath.item].editState.transform).magnitude
        return CGSize(width: cellSize.width, height: contentSize.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
}
