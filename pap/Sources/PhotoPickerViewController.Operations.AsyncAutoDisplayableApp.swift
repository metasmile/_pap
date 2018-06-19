//
// Created by BLACKGENE on 18.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


private struct AsyncAutoSelectionQueue {

    fileprivate static let dispatchQueue = DispatchQueue(label: "com.stells.internal."+#file, qos: .utility)

    //INFO: controlQueue must be higher than dispatchQueue for its priority
    fileprivate static let controlQueue =  DispatchQueue.main

    //INFO: Access all following properties only with dispatchQueue when write
    fileprivate static let indexPathQueue = ItemQueue<IndexPath>()

    //INFO: Write 'canceled' must be a dispatchqueue that has earlier QoS than .utility
    fileprivate static var canceled = false

}

extension PhotoPickerViewController{

    public func enqueueAutoSelectionIfNeeded(){
        guard let _ = AppCenter.default.currentInstanceAs(PhotoPickerCollectionViewAsyncAutoDisplayableApp.self) else {
            cancelPendingAutoSelectionIfNeeded()
            return
        }

        for indexPath in self.photoCollectionView.indexPathsForVisibleItems
            where self.collectionView(self.photoCollectionView, shouldSelectItemAt: indexPath)
                    && self.photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == false{

            AsyncAutoSelectionQueue.dispatchQueue.async{
                if false == AsyncAutoSelectionQueue.indexPathQueue.enqueued(where:{ $0 == indexPath }){
                    AsyncAutoSelectionQueue.indexPathQueue.enqueue(indexPath)
                }
            }
        }
    }

    public func cancelPendingAutoSelectionIfNeeded(){
        AsyncAutoSelectionQueue.controlQueue.async{
            if AsyncAutoSelectionQueue.indexPathQueue.count == 0{
                return
            }
            AsyncAutoSelectionQueue.canceled = true
        }
    }

    public func performAutoSelectionIfNeeded(includingCurrentVisibleItems:Bool=false){
        guard let interactableApp = AppCenter.default.currentInstanceAs(PhotoPickerCollectionViewAsyncAutoDisplayableApp.self) else {
            cancelPendingAutoSelectionIfNeeded()
            return
        }

        if includingCurrentVisibleItems {
            self.enqueueAutoSelectionIfNeeded()
        }

        let signal = AsyncSignal()

        func performNext() {
            AsyncAutoSelectionQueue.dispatchQueue.async {
                guard let indexPath = AsyncAutoSelectionQueue.indexPathQueue.dequeue() else {
                    return
                }

                var autoSelect = false

                if let asset = PHAssets.fetched.asset(at: indexPath)
                , let item = AppAssets.selected.at(unsafeIndex:indexPath.item) ?? AppAsset.create(for:asset) {

                    autoSelect = .visible == interactableApp.shouldAutoSelectAsynchronously(item: item, signal)
                }

                if AsyncAutoSelectionQueue.canceled{
                    AsyncAutoSelectionQueue.indexPathQueue.dequeueAll()
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

        AsyncAutoSelectionQueue.controlQueue.async {
            AsyncAutoSelectionQueue.canceled = false
            performNext()
        }
    }
}