//
// Created by BLACKGENE on 18.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


private struct IndexPathsForVisibleItems {
    fileprivate static var queue = ItemQueue<IndexPath>()
    fileprivate static var dispatchQueue = DispatchQueue(label: "com.stells.IndexPathsForVisibleItems")
}

extension PhotoPickerViewController{

    public func enqueueVisibleItemsToAsyncSelect(){
        IndexPathsForVisibleItems.dispatchQueue.async{
            self._enqueueVisibleItemsToAsyncSelect()
        }
    }

    private func _enqueueVisibleItemsToAsyncSelect(){
        guard let _ = AppCenter.default.currentInstanceAs(PhotoPickerCollectionViewAsyncAutoDisplayableApp.self) else {
            IndexPathsForVisibleItems.queue.dequeueAll()
            return
        }

        for indexPath in self.photoCollectionView.indexPathsForVisibleItems
            where self.collectionView(self.photoCollectionView, shouldSelectItemAt: indexPath)
                    && self.photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == false{

            if false == IndexPathsForVisibleItems.queue.enqueued(where:{ $0 == indexPath }){
                IndexPathsForVisibleItems.queue.enqueue(indexPath)
            }
        }
    }


    public func selectAsyncQueuedVisibleItems(includingCurrentVisibleItems:Bool=false){
        IndexPathsForVisibleItems.dispatchQueue.async{
            guard let interactableApp = AppCenter.default.currentInstanceAs(PhotoPickerCollectionViewAsyncAutoDisplayableApp.self) else {
                IndexPathsForVisibleItems.queue.dequeueAll()
                return
            }

            if includingCurrentVisibleItems {
                self._enqueueVisibleItemsToAsyncSelect()
            }

            let signal = AsyncSignal()

            while let indexPath = IndexPathsForVisibleItems.queue.dequeue(){
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
        }
    }
}