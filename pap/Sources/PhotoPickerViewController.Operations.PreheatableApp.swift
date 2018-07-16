//
// Created by BLACKGENE on 18.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


private struct PreheatingQueue {

    fileprivate static let dispatchQueue = DispatchQueue(label: "com.stells.internal.dispatchQueue"+#file, qos: .utility)

    //INFO: controlQueue must be higher than dispatchQueue for its priority
    fileprivate static let controlQueue =  DispatchQueue(label: "com.stells.internal.controlQueue"+#file, qos: .userInteractive)

    //INFO: Access all following properties only with dispatchQueue when write
    fileprivate static let indexPathItemQueue = ItemQueue<IndexPath>()

    //INFO: Write 'canceled' must be a dispatchqueue that has earlier QoS than .utility
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
                if false == PreheatingQueue.indexPathItemQueue.enqueued(where:{ $0 == indexPath }){
                    PreheatingQueue.indexPathItemQueue.enqueue(indexPath)
                }
            }
        }
    }

    public func cancelPreheatingIfNeeded(){
        PreheatingQueue.controlQueue.async{
            if PreheatingQueue.indexPathItemQueue.count == 0{
                return
            }
            PreheatingQueue.indexPathItemQueue.dequeueAll()
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
                guard let indexPath = PreheatingQueue.indexPathItemQueue.dequeue() else {
                    return
                }

                var autoSelect = false

                if let asset = PHAssets.fetched.asset(at: indexPath)
                , let item = AppAssets.selected.at(unsafeIndex:indexPath.item) ?? AppAsset.create(for:asset) {

                    if let finishAction = interactableApp.performPreheating(item: item, signal) as? UICollectionViewPreheatableAppFinishAction {
                        autoSelect = finishAction == .selectItem
                    }

                }

                if PreheatingQueue.canceled{
                    PreheatingQueue.indexPathItemQueue.dequeueAll()
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
        }

        PreheatingQueue.dispatchQueue.async {
            performNext()
        }
    }
}