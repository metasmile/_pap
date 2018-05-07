//
// Created by BLACKGENE on 20/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//


import XCTest
import Photos
@testable import batch

private class MetaDataLoader {


    static func fetchPhotoMetadata(data: Data) -> [String: Any]? {
        guard let selectedImageSourceRef = CGImageSourceCreateWithData(data as CFData, nil),
              let imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(selectedImageSourceRef, 0, nil) as? [String: Any] else {
            return nil
        }
        return imagePropertiesDictionary
    }
}


class ExifGhostAppTests: PHAssetsXCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // https://stackoverflow.com/questions/25715280/how-to-preserve-original-photo-metadata-when-editing-phassets
    // https://stackoverflow.com/questions/44517834/modifing-metadata-from-existing-phasset-seems-not-working
    // https://github.com/LQi2009/LQHEICToJPG/blob/b12abed6a7574a3fd7b93bb082af08d676284364/LQHEICToJPG/LQHEICToJPG/LQModifyImageType.swift

    let imageManager = PHImageManager.default()

    func test_exifWrite() {
        XCTAssertTrue(true)

        let async = AsyncSignal()
        async.begin()

        //TODO: PHAsset async procedures does not work in XCTest
        if let numberOfSection = PHAssets.fetched.results?.count, numberOfSection > 0, let numberOfItemsInSection = PHAssets.fetched.results?[numberOfSection - 1].count, numberOfItemsInSection > 0 {
            let latestIndexPath = IndexPath(item: numberOfItemsInSection - 1, section: numberOfSection - 1)

            if let latestAsset = PHAssets.fetched.asset(at: latestIndexPath){

                let url = "temp.jpg".asURLInTemporaryDirectory
                latestAsset.writeJPEGRepresentation(to: url, transformMetadata: { dictionary in
                    var metadata = dictionary
                    print(metadata)
                    metadata.removeValue(forKey: kCGImagePropertyGPSDictionary as String)
                    return metadata

                }, completion: { succeed in
                    print("succeed ------------- ", succeed)
                    print(url.asMetadataFromCIImage)
                    async.end()
                })

            }
        }
        async.waitUntilEnd(timeout: DispatchTime.now()+10.0)
    }
}
