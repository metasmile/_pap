//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public class SourceItem<SourceableProtocols>: BindableObject<SourceItem.conformsSourceables>{
    public typealias conformsSourceables = SourceableProtocols
    public var source: conformsSourceables?{
        get{
            return self.bindedObject
        }
    }
}

public class ImageSourceItem: SourceItem<ImageSourceable & DataSourceable & RemoteSourceable>{}

public class RemoteDataSourceItem: SourceItem<DataSourceable & RemoteSourceable>{}

public class PhotosSourceItem: SourceItem<ImageSourceable & PHAssetSourceable>{}