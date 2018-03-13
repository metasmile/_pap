//
// Created by BLACKGENE on 12/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public typealias AppAsset = PHAssetItem<AppValue>

public final class AppAssets: NSObject {
    public static let fetched = AppAssets()
    public static let selected = AppAssets()

    private var  _items = [AppAsset]()

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
        return  _items.first(where: { $0.asset == asset })
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

    func create(for asset: PHAsset) -> AppAsset? {
        guard let app = AppCenter.default.current else { return nil }

        if let itemType = app.paramType as? PHAssetParamable.Type
        , let item = itemType.init(asset) as? AppAsset {
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
            put(with: item.asset)
        }
    }

    func appendValue(_ item: AppValue, `for`:[AppAsset]?=nil) {
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