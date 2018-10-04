//
// Created by BLACKGENE on 2018-10-04.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

extension PHAssets{

    public func search(reverse:Bool=false, searchHandler:((Int, PHAsset, inout Bool) -> Bool)) -> [PHAsset]{
        var searchedResult = [PHAsset]()
        var shouldBreak = false
        for r in (reverse ? results?.reversed() : results) ?? [] where shouldBreak == false{
            let indexes = Array((0 ..< r.count))
            for i in (reverse ? indexes.reversed() : indexes) where searchHandler(i, r[i], &shouldBreak){
                searchedResult.append(r[i])
                if shouldBreak{
                    break
                }
            }
        }
        return searchedResult
    }

    public func searchFirst(searchHandler:((Int, PHAsset) -> Bool)) -> PHAsset?{
        return self.search(reverse: false, searchHandler:{ i, asset, shouldBreak in
            let searched = searchHandler(i, asset)
            shouldBreak = searched
            return searched
        }).nilEmpty?.first
    }

    public func searchLast(searchHandler:((Int, PHAsset) -> Bool)) -> PHAsset?{
        return self.search(reverse: true, searchHandler:{ i, asset, shouldBreak in
            let searched = searchHandler(i, asset)
            shouldBreak = searched
            return searched
        }).nilEmpty?.first
    }

}