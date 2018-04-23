//
// Created by BLACKGENE on 12/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public typealias AppAsset = PHAssetItem<ImageEditStateValue>

//TODO: internal / locally collect
public final class AppAssets: NSObject {
    public static let selected = AppAssets()

    private var _items = [AppAsset]()
    private var _itemsAssets = [PHAsset]()

    public let currentSection:Int = 0

    private override init(){}

    var count:Int{
        return  _items.count
    }

    var indices:CountableRange<Int>{
        return _items.indices
    }

    var hasChanges: Bool {
        return  _items.first(where: { $0.editState.hasChanges }) != nil
    }

    func stateChanged(for assets:[AppAsset]?=nil) -> [AppAsset]? {
       let targets = assets == nil ? _items : Array(Set(_items).intersection(assets!))
        return targets.filter { $0.editState.hasChanges }
    }

    func by(_ asset:PHAsset) -> AppAsset?{
        if let index = _itemsAssets.index(of: asset){
            return _items[index]
        }
        return nil
    }

    func at(_ index:Int) -> AppAsset {
        return  _items[index]
    }

    func at(unsafeIndex:Int) -> AppAsset? {
        if self.indices.contains(unsafeIndex){
            return _items[unsafeIndex]
        }
        return nil
    }

    func index(of assetItem: AppAsset) -> Int?{
        return  _items.index(of: assetItem)
    }

    @discardableResult
    func put(with asset: PHAsset) -> IndexPath? {
        guard let item = AppAsset.create(for:asset) else{
            return nil
        }

        var nextIndex = 0

        if let _indexOfAsset = _itemsAssets.index(of:asset){
            _items[_indexOfAsset] = item
            nextIndex = _indexOfAsset

        }else{
            nextIndex =  _items.count
            _items.append(item)
            _itemsAssets.append(item.asset)
        }

        let insertedIndexPath = IndexPath(item: nextIndex, section: currentSection)

        item.indexPath = insertedIndexPath

        return insertedIndexPath
    }

    @discardableResult
    func remove(for asset: PHAsset) -> IndexPath? {
        guard let index = _itemsAssets.index(of:asset) else {
            return nil
        }

        _items.remove(at: index)
        _itemsAssets.remove(at: index)

        return IndexPath(item: index, section: currentSection)
    }

    func removeAll(){
        _items.removeAll()
        _itemsAssets.removeAll()
    }

    func reloadAll() {
        for item in _items {
            put(with: item.asset)
        }
    }

    func appendValue(_ item: ImageEditStateValue, `for`:[AppAsset]?=nil) {
        for e in `for` ??  _items {
            e.editState.append(item)
        }
    }

    func resetValues(forItems:[AppAsset]?=nil) {
        for e in forItems ??  _items {
            e.editState.reset()
        }
    }

}
