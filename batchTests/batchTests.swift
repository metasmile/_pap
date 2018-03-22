//
//  batchTests.swift
//  batchTests
//
//  Created by BLACKGENE on 19/03/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import XCTest
@testable import batch

class batchTests: XCTestCase {
    override func setUp() {

        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func test(){}
    
    func test_SequenceOptionSet(){
        measure {
            XCTAssertTrue([PHAssetFinalizingOptions.delete].underestimatedCount==1)
        }
        XCTAssertTrue([PHAssetFinalizingOptions.delete, PHAssetFinalizingOptions.create].underestimatedCount==2)

        let iterableOptions:PHAssetFinalizingOptions = [.delete, .create]
        for option in iterableOptions{
            print("option == .create / "+String(describing: option == .create ))
            XCTAssertTrue(option == .create || option == .delete)
        }
    }
}


//TODO: >> CodeTestKit
class PHAssetsXCTestCase: XCTestCase {

    override func setUp() {
        super.setUp()

        let signal = AsyncSignal()
        signal.begin()

        var assetInfo:KeyPathWatcherInfo?
        assetInfo = PHAssets.fetched.watch(\.results) {
            XCTAssertTrue(assetInfo != nil)
            XCTAssertTrue(PHAssets.fetched.results != nil)
            signal.end()
        }

        PHAssets.fetched.load(with: .smartAlbum, subtype: .smartAlbumUserLibrary)

        signal.stopUntilEnd(timeout: DispatchTime.now() + 5.0)
    }
}
