//
// Created by BLACKGENE on 18.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

private struct PreheatingQueue {

    fileprivate static let dispatchQueue = DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility)

    //INFO: controlQueue must be higher than dispatchQueue for its priority
    fileprivate static let controlQueue =  DispatchQueue.main

    //INFO: Access all following properties. MUST ACCESS ONLY WITH <<PreheatingQueue.dispatchQueue>> WHEN WRITE
    fileprivate static let indexPathQueue = ItemQueue<IndexPath>()
    fileprivate static var identifierSet = Set<String>()

    //INFO: Write 'canceled'. MUST ACCESS ONLY WITH a queue faster than <<PreheatingQueue.dispatchQueue>> WHEN WRITE
    fileprivate static var canceled = false

}

extension PhotoPickerViewController{

    public func enqueuePreheatingIfNeeded(){
        guard let _ = AppCenter.default.currentInstanceAs(PreheatableApp.self) else {
            cancelPreheatingIfNeeded()
            return
        }

        for indexPath in self.photoCollectionView.indexPathsForVisibleItems
            where self.shouldSelectPhoto(at: indexPath)
                    && self.photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == false{

            PreheatingQueue.dispatchQueue.async{
                guard let asset = PHAssets.fetched.asset(at: indexPath)
                , false == PreheatingQueue.identifierSet.contains(asset.localIdentifier) else{
                    return
                }
                PreheatingQueue.identifierSet.insert(asset.localIdentifier)
                PreheatingQueue.indexPathQueue.enqueue(indexPath)
            }
        }
    }

    public func cancelPreheatingIfNeeded(){
        PreheatingQueue.controlQueue.async{
            PreheatingQueue.canceled = true
        }
    }

    public func performPrefetchIfNeeded(includingCurrentVisibleItems:Bool=false){
        guard let _ = AppCenter.default.currentInstanceAs(PreheatableApp.self) else {
            cancelPreheatingIfNeeded()
            return
        }

        if includingCurrentVisibleItems {
            self.enqueuePreheatingIfNeeded()
        }

        let signal = AsyncSignal()

        let didPerformInCurrentCapturedCycle = PreheatingQueue.indexPathQueue.count>0

        func performNext() {
            PreheatingQueue.dispatchQueue.async {
                guard let preheatingApp = AppCenter.default.currentInstanceAs(PreheatableApp.self) else {
                    self.cancelPreheatingIfNeeded()
                    return
                }

                guard let indexPath = PreheatingQueue.indexPathQueue.dequeue()
                , let asset = PHAssets.fetched.asset(at: indexPath) else {
                    if didPerformInCurrentCapturedCycle {
                        preheatingApp.didFinishCurrentPreheatingCycle()
                    }
                    return
                }
                PreheatingQueue.identifierSet.remove(asset.localIdentifier)

                //prefetchedImage
                let cachingOptions = self.collectionViewCurrentAllCachingImageRequestOptions(self.photoCollectionView, at: indexPath)

                //performPreheating
                var autoSelect = false
                let item = PHAssetItem(asset: asset, indexPath: indexPath, requestIDs: nil, cachingRequestOptions: cachingOptions)

                if let finishAction = autoreleasepool(invoking:{ preheatingApp.performPreheating(item: item, signal) }) as? UICollectionViewPreheatableAppFinishAction {
                    autoSelect = finishAction == .selectItem
                }
                
                if PreheatingQueue.canceled{
                    PreheatingQueue.identifierSet.removeAll()
                    PreheatingQueue.indexPathQueue.dequeueAll()
                    preheatingApp.didCancelPreheating()
                    return
                }

                //select
                if autoSelect{
                    DispatchQueue.main.async{
                        self.selectCollectionViewItem(at: indexPath, animated: false)
                    }
                }

                performNext()
            }
        }

        PreheatingQueue.controlQueue.async {
            PreheatingQueue.canceled = false
        }

        performNext()
    }
}
