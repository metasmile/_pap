//
//  ApplicationTests.swift
//  batchTests
//
//  Created by BLACKGENE on 19/03/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import XCTest
@testable import pap

class batchTests: XCTestCase {
    override func setUp() {

        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func test(){}

    private struct TestingSequenceOptionSet: SequenceOptionSet {
        static let modify = TestingSequenceOptionSet(rawValue: 1 << 0)
        static let create = TestingSequenceOptionSet(rawValue: 1 << 1)
        static let delete = TestingSequenceOptionSet(rawValue: 1 << 2)
        static let share = TestingSequenceOptionSet(rawValue: 1 << 3)

        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    func test_SequenceOptionSet(){
        measure {
            XCTAssertTrue([TestingSequenceOptionSet.delete].count==1)
        }
        XCTAssertTrue([TestingSequenceOptionSet.delete, TestingSequenceOptionSet.create].count==2)

        let iterableOptions:TestingSequenceOptionSet = [.delete, .create]
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
}



public protocol TransformAppDefaults: AppDefaults{
    var transform:Int? {set get}
}

extension Defaults: TransformAppDefaults {
    public var transform: Int? {
        set{ set(newValue) } get{ return get() }
    }
}


//TODO: >> CodeTestKit
class PHAssetsXCTestCase: XCTestCase {

    override func setUp() {
        super.setUp()

        let signal = AsyncSignal()
        signal.begin()

        
        var assetInfo:PropertyWatcherInfo?
        assetInfo = PHAssets.fetched.watch(\.results) {
            XCTAssertTrue(assetInfo != nil)
            XCTAssertTrue(PHAssets.fetched.results != nil)
            signal.end()
        }

        PHAssets.fetched.load(with: .smartAlbum, subtype: .smartAlbumUserLibrary)

        signal.waitUntilEnd(timeout: DispatchTime.now() + 5.0)
    }
}
