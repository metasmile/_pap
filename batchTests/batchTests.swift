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
