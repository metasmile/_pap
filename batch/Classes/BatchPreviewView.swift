//
//  BatchPreviewView.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 6..
//  Copyright © 2017년 Stells. All rights reserved.
//

import UIKit
import Photos

class BatchPreviewView: CustomView {
    @IBOutlet weak var collectionView: UICollectionView!
    fileprivate var batchEditItems = [BatchEditItem]()
    
    override func initialize() {
        super.initialize()
        
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCollectionViewCell")
        collectionView.allowsSelection = false
        updateAlignment(animated: false)
    }
}

extension BatchPreviewView {
    func addBatchEditItem(with asset: PHAsset?) {
        let indexPath = IndexPath(item: batchEditItems.count, section: 0)
        
        let batchEditItem = BatchEditItem()
        batchEditItem.asset = asset
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
}

extension BatchPreviewView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return batchEditItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        if let asset = batchEditItems[indexPath.item].asset {
            cell.imageContentMode = .aspectFit
            cell.setAsset(asset, at: indexPath)
        }
        return cell
    }
}

extension BatchPreviewView: UICollectionViewDelegate {
    
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
        return 0
    }
}
