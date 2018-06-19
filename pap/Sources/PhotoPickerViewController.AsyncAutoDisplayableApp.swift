//
// Created by BLACKGENE on 18.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


private struct AsyncAutoSelectionQueue {

    fileprivate static let dispatchQueue = DispatchQueue(label: "com.stells.internal."+#file, qos: .utility)

    //INFO: Access all following properties only with dispatchQueue when write
    fileprivate static let indexPathQueue = ItemQueue<IndexPath>()
    fileprivate static let signalQueue = ItemQueue<AsyncSignal>()

    //INFO: Write 'canceled' must be a dispatchqueue that has earlier QoS than .utility
    fileprivate static var canceled = false

}

extension PhotoPickerViewController{

    public func enqueueAutoSelectionForVisibleItemsIfAppNeeds(){
        self.enqueueAutoSelectionForVisibleItems()
    }

    private func enqueueAutoSelectionForVisibleItems(){
        guard let _ = AppCenter.default.currentInstanceAs(PhotoPickerCollectionViewAsyncAutoDisplayableApp.self) else {
            cancelPendingAutoSelectionForVisibleItems()
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

    public func cancelPendingAutoSelectionForVisibleItems(){
        DispatchQueue.global(qos: .default).async(flags:.barrier){
            if AsyncAutoSelectionQueue.indexPathQueue.count == 0{
                return
            }
            AsyncAutoSelectionQueue.canceled = true
        }
    }

    public func performAutoSelectionForVisibleItemsIfAppNeeds(includingCurrentVisibleItems:Bool=false){
        guard let interactableApp = AppCenter.default.currentInstanceAs(PhotoPickerCollectionViewAsyncAutoDisplayableApp.self) else {
            cancelPendingAutoSelectionForVisibleItems()
            return
        }

        if includingCurrentVisibleItems {
            self.enqueueAutoSelectionForVisibleItems()
        }

        func performNext() {
            AsyncAutoSelectionQueue.dispatchQueue.async {
                if let indexPath = AsyncAutoSelectionQueue.indexPathQueue.dequeue() {
                    let signal = AsyncSignal()
                    AsyncAutoSelectionQueue.signalQueue.enqueue(signal)

                    if let asset = PHAssets.fetched.asset(at: indexPath){
                        if let item = AppAssets.selected.at(unsafeIndex:indexPath.item) ?? AppAsset.create(for:asset) {
                            if .visible == interactableApp.shouldAutoSelectAsynchronously(item:item, signal){
                                DispatchQueue.main.async{
                                    self.selectCollectionViewItem(at: indexPath, animated: false)
                                }
                            }
                        }
                    }
                }

                if AsyncAutoSelectionQueue.canceled{
                    AsyncAutoSelectionQueue.canceled = false
                    AsyncAutoSelectionQueue.signalQueue.dequeueAll()
                    AsyncAutoSelectionQueue.indexPathQueue.dequeueAll()
                    return
                }

                performNext()
            }
        }

        performNext()
    }
}