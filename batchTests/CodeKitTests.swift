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

    func test_ImageIO_Metadata(){

        if let data = Bundle(for: type(of: self)).bundleURL.appendingPathComponent("IMG_0679.JPG").asData{

            if let metadata = data.getMetadata(){
                XCTAssertNotNil(data.getMetadata())

                print(metadata[ImageMetadata.Dictionary.GPS])
                print(metadata[ImageMetadata.Dictionary.Exif])
                print(metadata[ImageMetadata.Dictionary.TIFF])

                for property in ImageMetadata.PropertyApple.GPS{

                    if let sampleValue = data.getMetadataValue(dictionary: ImageMetadata.Dictionary.GPS, property: property){
                        let sampleVoidValue = ImageMetadata.getVoidValue(sampleValue) ?? sampleValue

                        let updatedData = data.updateMetadata(with: metadata, dictionary: ImageMetadata.Dictionary.GPS, property: property, value: sampleVoidValue)
                        XCTAssertNotNil(updatedData.getMetadataValue(dictionary: ImageMetadata.Dictionary.GPS, property: property))
                        print(updatedData.getMetadataValue(dictionary: ImageMetadata.Dictionary.GPS, property: property))

                        let purgedData = data.purgeMetadata(with: metadata, dictionary:ImageMetadata.Dictionary.GPS, property:property)

                        if let purgedValue = purgedData.getMetadataValue(dictionary: ImageMetadata.Dictionary.GPS, property: property){
                            print("purged --- ", property, purgedValue, ImageMetadata.isValueVoid(purgedValue))

                            if !ImageMetadata.isValueVoid(purgedValue){
                                print("why?----")
                                print(purgedValue is String)
                                print(purgedValue is Int)
                                print(purgedValue is Double)
                                print(purgedValue is Float)
                                print(purgedValue is Date)
                                print(purgedValue is NSArray)
                            }

                        }else{
                            XCTFail("nil - purgedValue of \(property)")
                        }

                    }else{
                        print("sampleValue of \(property) is nil")
                    }
                }

                //undefined sheme -> purge all
                let purgedData2 = data.purgeMetadata(with: metadata, for: nil)
                XCTAssertNotNil(purgedData2.getMetadataValue(dictionary: ImageMetadata.Dictionary.GPS, property: ImageMetadata.Property.GPSLongitude))
            }

        }else{
            XCTFail()
        }
    }

    func test_GIFDataRepresentation(){

        if let data = Bundle(for: type(of: self)).bundleURL.appendingPathComponent("bath01.gif").asData{
            XCTAssertNotNil(UIImage.animatedImageWithGIFData(data))
            XCTAssertNotNil(UIImageGIFRepresentation(UIImage.animatedImageWithGIFData(data)!, duration: 0, repeatCount: 0))
        }else{
            XCTFail()
        }

    }
}