//
// Created by BLACKGENE on 20/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//


import XCTest
import Photos
@testable import batch

class ExifGhostAppTests: PHAssetsXCTestCase {

    override func setUp() {

        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    // https://stackoverflow.com/questions/44517834/modifing-metadata-from-existing-phasset-seems-not-working

    func test_exifHasExists(){

        let async = AsyncSignal()
        async.begin()

        if let numberOfSection = PHAssets.fetched.results?.count, numberOfSection > 0, let numberOfItemsInSection = PHAssets.fetched.results?[numberOfSection - 1].count, numberOfItemsInSection > 0 {
            let latestIndexPath = IndexPath(item: numberOfItemsInSection - 1, section: numberOfSection - 1)

            let latestAsset = PHAssets.fetched.asset(at: latestIndexPath)
            print(latestAsset)

            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.isNetworkAccessAllowed = true
            latestAsset?.requestContentEditingInput(with: options, completionHandler: { (input , info) in
                if let url = input?.fullSizeImageURL{
                    let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)
                    let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource!, 0, nil) as Dictionary?
                    print(metadata)
                }
                async.end()
            })
        }
        async.stopUntilEnd()

    }
    
}
