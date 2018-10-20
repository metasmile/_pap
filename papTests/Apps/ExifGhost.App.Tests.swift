//
// Created by BLACKGENE on 20/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//


import XCTest
import Photos
@testable import pap

private class MetaDataLoader {


    static func fetchPhotoMetadata(data: Data) -> [String: Any]? {
        guard let selectedImageSourceRef = CGImageSourceCreateWithData(data as CFData, nil),
              let imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(selectedImageSourceRef, 0, nil) as? [String: Any] else {
            return nil
        }
        return imagePropertiesDictionary
    }
}


class ExifGhostAppAppTests: PHAssetsXCTestCase {

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
    }
}
