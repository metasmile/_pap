//
//  PreviewView.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 6..
//  Copyright © 2017년 Stells. All rights reserved.
//

import UIKit
import Photos
import Crashlytics

protocol PreviewViewDelegate {
    func batchPreviewView(_ view: PreviewView, didSelectItemAt indexPath: IndexPath)
    func batchPreviewViewWillFinalize(_ view: PreviewView)

    func batchPreviewView(_ view: PreviewView, didUpdateProgress progress: Float)
    func batchPreviewViewWillCancelProgress(_ view: PreviewView)

    func batchPreviewViewWillBeginEdit(_ view: PreviewView)
    func batchPreviewViewDidEndEdit(_ view: PreviewView)
    func batchPreviewViewDidCancelEdit(_ view: PreviewView)
}

class PreviewView: CustomView {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeightLayout: NSLayoutConstraint!
    
    var delegate: PreviewViewDelegate?

    let appAssetsSelected = AppAssets.selected
    let _preferences = AppDockContentPreferences(height:44)

    override func initialize() {
        super.initialize()

        print("[i] BatchAppCenter.default.task.maxConcurrentCount: ", AppCenter.default.task.maxConcurrentCount)

        collectionViewHeightLayout.constant = _preferences.height
        
        collectionView.contentInset.top = 1
        collectionView.contentInset.bottom = 1
        collectionView.register(PreviewCollectionViewCell.self, forCellWithReuseIdentifier: "PreviewCollectionViewCell")
        updateCollectionViewAlignment(animated: false)
    }

    public func updatePreviews(animated: Bool = true, completion: (() -> Void)? = nil) {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.performBatchUpdates(nil) { _ in completion?() }

        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        for indexPath in visibleIndexPaths {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? PreviewCollectionViewCell else { continue }

            let appAsset = appAssetsSelected.at(indexPath.item)
            if appAsset.editState.hasChanges{
                cell.setImageEditItem(appAsset.editState, animated: animated)
            }
        }

        updateCollectionViewAlignment(animated: false)
    }

    public func reloadPreview(with height: CGFloat) {
        collectionViewHeightLayout.constant = height
        collectionView.layoutIfNeeded()
        
        collectionView.reloadData()
        collectionView.performBatchUpdates(nil) { _ in
            self.updateCollectionViewAlignment(animated: false)
        }
    }
}

extension PreviewView: AppDockContentView, AppDockContent {
    //AppDockContentDescribable
    var view: UIView {
        return self
    }
    var preferences: AppDockContentPreferable? {
        return _preferences
    }

    func reloadContent() {
        reloadPreview(with:_preferences.height)
    }

    func reloadContentThatFits(size:CGSize) {
        reloadPreview(with:size.height)
    }
}

extension PreviewView {
    @discardableResult
    func appendCollectionViewItem(with asset: PHAsset) -> IndexPath? {
        let prevCount = appAssetsSelected.count
        guard let insertedIndexPath = appAssetsSelected.put(with:asset) else {
            return nil
        }

        if appAssetsSelected.count>prevCount{
            self.collectionView.insertItems(at: [insertedIndexPath])
        }
        self.updateCollectionViewAlignment()
        self.collectionView.scrollToItem(at: insertedIndexPath, at: .centeredHorizontally, animated: true)

        return insertedIndexPath
    }

    func removeCollectionViewItem(with asset: PHAsset?) {
        guard let _asset = asset, let indexPath = appAssetsSelected.remove(for:_asset) else {
            return
        }

        collectionView.deleteItems(at: [indexPath])
        updateCollectionViewAlignment()

        if appAssetsSelected.count > 0 {
            let nearestItem = max(min(indexPath.item - 1, appAssetsSelected.count - 2), 0)
            collectionView.scrollToItem(at: IndexPath(item: nearestItem, section: 0), at: .centeredHorizontally, animated: true)
        }
    }

    func removeAllCollectionViewItems() {
        let indexPaths = (0..<appAssetsSelected.count).map({ IndexPath(item: $0, section: 0) })

        appAssetsSelected.removeAll()
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

extension PreviewView {

    //TODO: remove dependencies and export from previewview
    @discardableResult
    func runBatchProcessing() -> Bool {
        let targetSection = 0 //TODO: previously support multiple sections

        guard let app = AppCenter.default.current, collectionView.numberOfItems(inSection: targetSection) > 0 else {
            assert(false, "selected app does not exist.")
            return false
        }

        //TODO: append dynamically more items where Set(EditItems) - Set(alreadyqueued Items) BatchAppCenter.default.task.query(by:_)
        delegate?.batchPreviewViewWillBeginEdit(self)

        collectionView.scrollToItem(at: IndexPath(item: 0, section: targetSection), at: .centeredHorizontally, animated: true)

        //TODO: BatchAppCenter.default.task.append immediatly from UI action instead of using "EditItems"

        for i in 0..<appAssetsSelected.count{
            AppCenter.default.task.append(request: AppTaskRequest(app, appAssetsSelected.at(i)))
        }
        AppCenter.default.task.perform(createTaskReaction())
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchProgressChanged), name: RemoteSourceFetchNotification.Name.progressChanged, object: nil)

        return true
    }

    public func createTaskReaction() -> AppTaskReaction{
        let reaction = AppTaskReaction()

        reaction.when(progress:{ response, progress, remained, completed in
            assert(response.info.state != .completed || response.info.state == .completed && response.result != nil, "task state is .completed but result is nil")

            let requestedParam = response.request.param as? PHAssetItem<AppValue>
            let totalCount = remained.count+completed.count

            assert(totalCount>0, "totalCount == 0 but progress has started")
            if totalCount == 0{
                return
            }

            if response.info.state == .cancelled {
                self.delegate?.batchPreviewViewWillCancelProgress(self)
                return
            }

            if response.info.state != .completed {
                // all - (cancelled + completed)
                return
            }

            //completed
            self.delegate?.batchPreviewView(self, didUpdateProgress: progress)

            guard let param = requestedParam
                , let index = param.indexPath else {
                return
            }

            let numberOfItems = self.collectionView.numberOfItems(inSection: index.section)
            if numberOfItems == 0{
                return
            }

            // it is possible totalCount != numberOfItems (e.g. if an item was runtime-removed while progress as batch tasks)
            let destItem = Int(Float(totalCount-1)*progress).clamped(to: 0...numberOfItems-1)

            //TODO: confirm - https://fabric.io/jessi/ios/apps/com.stells.batch/issues/5aca0f2936c7b23527e26e8a?time=last-thirty-days
            self.collectionView.scrollToItem(at: IndexPath(item: destItem, section: index.section), at: .centeredHorizontally, animated: true)


        }).will(finish: { resultsByApps, respondables in

            self.delegate?.batchPreviewViewWillFinalize(self)


        }).did(finish: { resultsByApps, respondables in
            assert(!AppCenter.default.isAppRunning)

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

        return reaction
    }
    
    @objc func fetchProgressChanged(sender: NSNotification) {
    }
    
    func cancelBatchProcessing() {
        assert(AppCenter.default.isAppRunning)

        AppCenter.default.task.cancel()

        delegate?.batchPreviewViewDidCancelEdit(self)
    }
}

extension PreviewView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return appAssetsSelected.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreviewCollectionViewCell", for: indexPath) as! PreviewCollectionViewCell
        cell.setEditItemForPreview(appAssetsSelected.at(indexPath.item), at: indexPath)
        return cell
    }
}

extension PreviewView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return !AppCenter.default.isAppRunning
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.batchPreviewView(self, didSelectItemAt: indexPath)
    }
}

extension PreviewView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let asset = appAssetsSelected.at(indexPath.item).asset

        let contentInset = collectionView.contentInset
        
        let contentSize = UIEdgeInsetsInsetRect(CGRect(origin: .zero, size: CGSize(width: collectionViewHeightLayout.constant, height: collectionViewHeightLayout.constant)), contentInset).size
        let boundingSize = CGSize(width: contentSize.height, height: contentSize.height)
        let photoSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight).aspectFit(in: boundingSize)
        let cellSize = photoSize.applying(appAssetsSelected.at(indexPath.item).editState.transform).magnitude
        
        return CGSize(width: cellSize.width, height: floor(contentSize.height))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
}
