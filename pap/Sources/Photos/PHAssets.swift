//
// Created by BLACKGENE on 14/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public final class PHAssets: NSObject, KeyPathWatchable {
    public static let fetched = PHAssets()

    private let syncQueue = DispatchQueue(label: #file, qos: .userInteractive)

    @objc dynamic
    private var _collections: PHFetchResult<PHAssetCollection>?
    public private(set) var collections: PHFetchResult<PHAssetCollection>?{
        set{
            syncQueue.async(flags:.barrier){
                self._collections = newValue
            }
        }
        get{
            return syncQueue.sync{
                return self._collections
            }
        }
    }

    @objc dynamic
    private var _results: [PHFetchResult<PHAsset>]?
    public private(set) var results: [PHFetchResult<PHAsset>]?{
        set{
            syncQueue.async(flags:.barrier){
                self._results = newValue
            }
        }
        get{
            return syncQueue.sync{
                return self._results
            }
        }
    }

    private override init() {}

    public func asset(at indexPath: IndexPath) -> PHAsset? {
        return results?[safe: indexPath.section]?[indexPath.item]
    }

    public func isContained(section:Int) -> Bool{
        return results?.indices.contains(section) ?? false
    }

    public func indexPath(of asset: PHAsset?) -> IndexPath? {
        guard let asset = asset else { return nil }
        return results?.enumerated().compactMap({
            let item = $0.element.index(of: asset)
            guard item != NSNotFound else { return nil }
            return IndexPath(item: item, section: $0.offset)
        }).first
    }

    @discardableResult
    public func update(result:PHFetchResult<PHAsset>, at section:Int) -> Bool{
        if isContained(section: section){
            results?[section] = result
            return true
        }
        return false
    }
    
    public func load(from collection: PHAssetCollection) {
        let options = PHFetchOptions()
        
        self.results = [PHAsset.fetchAssets(in: collection, options: options)]
    }
    
    public func load(with collectionType: PHAssetCollectionType = .smartAlbum, subtype collectionSubType: PHAssetCollectionSubtype = .smartAlbumUserLibrary, completion:(() -> Void)?=nil) {
        let options = PHFetchOptions()

        self.collections = PHAssetCollection.fetchAssetCollections(with: collectionType, subtype: collectionSubType, options: nil)
        var results = [PHFetchResult<PHAsset>]()

        self.collections?.enumerateObjects({ (collection, idx, stop) in
            results.append(PHAsset.fetchAssets(in: collection, options: options))
        })

        self.results = results
    }

    public func unload(){
        collections = nil
        results = nil
    }
}
