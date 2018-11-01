//
// Created by BLACKGENE on 23.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


public protocol CacheableApp: App{}

public protocol PHAssetCacheableApp: CacheableApp{
    var needsCachingRequestOptions:[PHAssetRequestOption]? {get}
}