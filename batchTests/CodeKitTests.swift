//
// Created by BLACKGENE on 30/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import XCTest
@testable import batch

class CodeKitTests: XCTestCase {
    override func setUp() {

        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_numerics(){
        XCTAssertTrue(remap(1, 0, 2, 0, 4) == 2)
        XCTAssertTrue(remap(1, 0, 2, 0, -4) == -2)
        XCTAssertTrue(remap(0.5, 0, 1, 0, 0.5) == 0.25)
        XCTAssertTrue(remap(1, 0, -2, 0, 4) == -2)
        XCTAssertTrue(remap(-1, 0, -2, 0, 4) == 2)
        XCTAssertTrue(remap(0, -2, 2, 0, 4) == 2)

        XCTAssertTrue(normalize(3,0,6) == 0.5)
        XCTAssertTrue(remapClamp(3, 0, 2, 0, 4) == 4)
        XCTAssertTrue(remapClamp(-2.1, -2, 2, -8, 4) == -8)

        XCTAssertTrue(15.clamped(to: 0...10) == 10)
        XCTAssertTrue(3.0.clamped(to: 0.0...10.0) == 3.0)
        XCTAssertTrue("a".clamped(to: "g"..."y") == "g")
    }

    func test_ImageIO_Metadata_update(){

        if let data = Bundle(for: type(of: self)).bundleURL.appendingPathComponent("IMG_0679.JPG").asData{

            if let metadata = data.getMetadata(){
                XCTAssertNotNil(data.getMetadata())

                //specific purge
                let dictionary = ImageMetadata.Dictionary.Exif
                for property in ImageMetadata.PropertyApple.Exif{
                    if let sampleValue = data.getMetadataValue(dictionary: dictionary, property: property){
                        let sampleVoidValue = ImageMetadata.getVoidValue(sampleValue) ?? sampleValue

                        let updatedData = data.updateMetadata(with: metadata, dictionary: dictionary, property: property, value: sampleVoidValue)
                        XCTAssertNotNil(updatedData.getMetadataValue(dictionary: dictionary, property: property))

                    }else{
                        print("sampleValue of \(property) is nil")
                    }
                }


            }

        }else{
            XCTFail()
        }
    }

    func test_ImageIO_Metadata_purge(){

        if let data = Bundle(for: type(of: self)).bundleURL.appendingPathComponent("IMG_0679.JPG").asData{

            if let metadata = data.getMetadata(){
                XCTAssertNotNil(data.getMetadata())

                let collectingPurgedData = data.purgeMetadata(with: metadata, for: ImageMetadata.Collection.DefaultSensitivity)
                print("collectingPurgedData")
                print(collectingPurgedData.getMetadata())

                let dictionary = ImageMetadata.Dictionary.Exif
//                print(metadata[ImageMetadata.Dictionary.GPS])
//                print(metadata[ImageMetadata.Dictionary.Exif])
//                print(metadata[ImageMetadata.Dictionary.TIFF])
                for property in ImageMetadata.PropertyApple.Exif{

                    if let sampleValue = data.getMetadataValue(dictionary: dictionary, property: property){
                        let sampleVoidValue = ImageMetadata.getVoidValue(sampleValue) ?? sampleValue

                        let purgedData = data.purgeMetadata(with: metadata, dictionary:dictionary, property:property)

                        if let purgedValue = purgedData.getMetadataValue(dictionary: dictionary, property: property){
                            let purged = ImageMetadata.isValueVoid(purgedValue)

                            if purged{
                                print(property, "purged")
                            }else{
                                print(property, sampleValue, "->", purgedValue, "->", ImageMetadata.getVoidValue(sampleValue))
                            }

//                            print("purged ", purged, property, sampleValue, "->", purgedValue)
//
//                            if !purged{
//                                print("purged failed ----")
//                                print(purgedValue is String)
//                                print(purgedValue is Int)
//                                print(purgedValue is Double)
//                                print(purgedValue is Float)
//                                print(purgedValue is Date)
//                                print(purgedValue is NSArray)
//                            }

                        }else{
                            print(property, "already-nil")
                        }

                    }else{
//                        print("sampleValue of \(property) is nil")
                    }
                }


            }

        }else{
            XCTFail()
        }
    }

    func test_GIFDataRepresentation(){

        if let data = Bundle(for: type(of: self)).bundleURL.appendingPathComponent("bath01.gif").asData{
            XCTAssertNotNil(UIImage.animatedImageWithGIFData(data))
            XCTAssertNotNil(UIImageGIFRepresentation(UIImage.animatedImageWithGIFData(data)!, duration: 0, loopCount: 0))
        }else{
            XCTFail()
        }

    }

    func test_CodableEnumUserDefaults(){
        var defaults:TestAppDefaults = Defaults(userDefaults:UserDefaults())

        XCTAssertEqual(defaults.valueWithCustomCodableType.from, .video)

        defaults.valueWithCustomCodableType = CustomCodableType(from: .livephoto, to:.video)

        XCTAssertEqual(defaults.valueWithCustomCodableType.from, .livephoto)

        defaults.valueWithCustomCodableType = CustomCodableType(from: .video, to: .livephoto)

    }
}


import DefaultsKit

protocol TestAppDefaults: AppDefaults{
    var valueWithCustomCodableType: CustomCodableType {get set}
}

extension Defaults: TestAppDefaults {
    var valueWithCustomCodableType: CustomCodableType {
        set { set(newValue) }
        get { return get(or:CustomCodableType(from: .video, to: .livephoto)) }
    }
}

enum CustomDecodableEnum: Int, Decodable{
    case any
    case video
    case livephoto
    case gif
    case burst
    case timelapse
}

struct CustomCodableType: Codable {
    var from:CustomDecodableEnum
    var to:CustomDecodableEnum

    private enum CodingKeys: Int, CodingKey {
        case from
        case to
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(from.rawValue, forKey: .from)
        try container.encode(to.rawValue, forKey: .to)
    }
}