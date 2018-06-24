//
// Created by BLACKGENE on 18.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public enum PhotoPickerCollectionViewAsyncSelection: Int{
    case none
    case visible
}

public protocol PhotoPickerCollectionViewAsyncAutoDisplayableApp: App{
    func shouldAutoSelectAsynchronously(item:AppAsset, _ async:AsyncSignal) -> PhotoPickerCollectionViewAsyncSelection
}

//TODO: add PhotoPickerCollectionViewAutoDisplayableApp - simple sync version