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

    func test_appDomainedDefaults(){

        let testVersion = "test version"
        AppCenter.default.current = TransformApp.self

        var appDefaults = (AppCenter.default.current as? PersistableApp.Type)?.defaults

        //instance
        XCTAssertNotNil(appDefaults)
        XCTAssertNotNil(appDefaults as? TransformAppDefaults)

        //setter test
        appDefaults?.touchedVersion = testVersion
        XCTAssertTrue((appDefaults as? TransformAppDefaults)?.touchedVersion == testVersion)
        if let tapp = appDefaults as? TransformAppDefaults{
            var _tapp = tapp
            _tapp.transform = 1
        }
        XCTAssertTrue((appDefaults as? TransformAppDefaults)?.transform == 1)

        //sandboxing
        AppCenter.default.current = RevertApp.self
        let appDefaults2 = (AppCenter.default.current as? PersistableApp.Type)?.defaults
        XCTAssertNotNil(appDefaults2)
    }

    func test_GIFDataRepresentation(){

        let data = "bath01.gif".asBundlePath.asURL!.asData!

        XCTAssertNotNil(UIImage.animatedImageWithGIFData(data))
        XCTAssertNotNil(UIImageGIFRepresentation(UIImage.animatedImageWithGIFData(data)!, duration: 0, repeatCount: 0))
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
