//
// Created by BLACKGENE on 12/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos


public final class BatchAppAssets: NSObject {
    typealias AssetType = PHAssetItem<BatchAppTransformValue>
    public static let shared = BatchAppAssets()

    private var  _items = [AssetType]()

    var count:Int{
        return  _items.count
    }

    var hasChanges: Bool {
        return  _items.first(where: { $0.editState.hasChanges }) != nil
    }

    func stateChanged(for assets:[AssetType]?=nil) -> [AssetType]? {
       let targets = assets == nil ? _items : Array(Set(_items).intersection(assets!))
        return targets.filter { $0.editState.hasChanges }
    }

    func by(_ asset:PHAsset?) -> AssetType?{
        return  _items.first(where: { $0.asset == asset })
    }

    func at(_ index:Int) -> AssetType{
        return  _items[index]
    }

    func index(of assetItem:AssetType) -> Int?{
        return  _items.index(of: assetItem)
    }

    @discardableResult
    func put(for asset: PHAsset) -> IndexPath? {

        guard let item = create(for:asset) else{
            return nil
        }

        var insertedIndex = -1

        if let _indexOfAsset =  _items.index(where: { $0.asset == asset }){
            _items[_indexOfAsset] = item
            insertedIndex = _indexOfAsset

        }else{
            insertedIndex =  _items.count
            _items.append(item)
        }

        let currentSection = 0 //TODO: collectionView.currentSection
        let insertedIndexPath = IndexPath(item: insertedIndex, section: currentSection)

        item.indexPath = insertedIndexPath

        return insertedIndexPath
    }

    func create(for asset: PHAsset) -> AssetType? {
        guard let app = BatchAppCenter.default.current else { return nil }

        if let itemType = app.paramType as? PHAssetParamable.Type
        , let item = itemType.init(asset) as? AssetType{
            return item

        } else{
            assert(false, "[!] Unable to create, or does not implement yet for param type of \(app.info.appType)")
            return nil
        }
    }

    func remove(for asset: PHAsset) -> IndexPath? {
        guard let item = _items.index(where: { $0.asset == asset }) else {
            return nil
        }

        _items.remove(at: item)

        return IndexPath(item: item, section: 0)
    }

    func removeAll(){
        _items.removeAll()
    }

    func reloadAll() {
        for item in _items {
            put(for: item.asset)
        }
    }

    func appendValue(_ item: BatchAppTransformValue, `for`:[AssetType]?=nil) {
        for e in `for` ??  _items {
            e.editState.append(item)
        }
    }

    func resetValues(forItems:[AssetType]?=nil) {
        for e in forItems ??  _items {
            e.editState.reset()
        }
    }

}