//
// Created by BLACKGENE on 18.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


private struct PreheatingQueue {

    fileprivate static let dispatchQueue = DispatchQueue(label: "com.stells.internal."+#file, qos: .utility)

    //INFO: controlQueue must be higher than dispatchQueue for its priority
    fileprivate static let controlQueue =  DispatchQueue.main

    //INFO: Access all following properties. MUST ACCESS ONLY WITH <<PreheatingQueue.dispatchQueue>> WHEN WRITE
    fileprivate static let indexPathQueue = ItemQueue<IndexPath>()

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
            where self.collectionView(self.photoCollectionView, shouldSelectItemAt: indexPath)
                    && self.photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == false{

            PreheatingQueue.dispatchQueue.async{
                if false == PreheatingQueue.indexPathQueue.enqueued(where:{ $0 == indexPath }){
                    PreheatingQueue.indexPathQueue.enqueue(indexPath)
                }
            }
        }
    }

    public func cancelPreheatingIfNeeded(){
        PreheatingQueue.controlQueue.async{
            PreheatingQueue.canceled = true
        }
    }

    public func performPrefetchIfNeeded(includingCurrentVisibleItems:Bool=false){
        guard let interactableApp = AppCenter.default.currentInstanceAs(PreheatableApp.self) else {
            cancelPreheatingIfNeeded()
            return
        }

        if includingCurrentVisibleItems {
            self.enqueuePreheatingIfNeeded()
        }

        let signal = AsyncSignal()

        func performNext() {
            PreheatingQueue.dispatchQueue.async {
                guard let indexPath = PreheatingQueue.indexPathQueue.dequeue() else {
                    return
                }

                var autoSelect = false

                if let asset = PHAssets.fetched.asset(at: indexPath)
                , let item = AppAssets.selected.at(unsafeIndex:indexPath.item) ?? AppAsset.create(for:asset) {
                    if let finishAction = autoreleasepool(invoking:{ interactableApp.performPreheating(item: item, signal) }) as? UICollectionViewPreheatableAppFinishAction {
                        autoSelect = finishAction == .selectItem
                    }
                }

                if PreheatingQueue.canceled{
                    PreheatingQueue.indexPathQueue.dequeueAll()
                    return
                }

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
            performNext()
        }
    }
}