//
// Created by BLACKGENE on 30/0??3/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import XCTest
import MobileCoreServices
@testable import pap

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


    func test_ImageIO_Metadata_isPurged() {

        if let data = Bundle(for: type(of: self)).bundleURL.appendingPathComponent("IMG_0679.JPG").asData {

            XCTAssertNotNil(data.getMetadata())

            if let metadata = data.getMetadata() {

                XCTAssertFalse(metadata.isPurgedMetadata(for: ImageMetadata.Collection.DefaultSensitivity))

                let collectingPurgedData = data.purgeMetadata(with: metadata, for: ImageMetadata.Collection.DefaultSensitivity)

                if let exitedData = collectingPurgedData.getMetadata() {
                    XCTAssertTrue(exitedData.isPurgedMetadata(for: ImageMetadata.Collection.DefaultSensitivity))
                }
            }

        } else {
            XCTFail()
        }
    }


    func test_ImageIO_Metadata_purge(){

        if let data = Bundle(for: type(of: self)).bundleURL.appendingPathComponent("IMG_0679.JPG").asData{

            XCTAssertNotNil(data.getMetadata())

            if let metadata = data.getMetadata(){

                XCTAssertFalse(metadata.isPurgedMetadata(for: ImageMetadata.Collection.DefaultSensitivity))

                let collectingPurgedData = data.purgeMetadata(with: metadata, for: ImageMetadata.Collection.DefaultSensitivity)

                let dictionary = ImageMetadata.Dictionary.Exif
//                print(metadata[ImageMetadata.Dictionary.GPS])
//                print(metadata[ImageMetadata.Dictionary.Exif])
//                print(metadata[ImageMetadata.Dictionary.TIFF])
                for property in ImageMetadata.PropertyApple.GPS{

                    if let sampleValue = data.getMetadataValue(dictionary: dictionary, property: property){
                        let sampleVoidValue = ImageMetadata.getVoidValue(sampleValue) ?? sampleValue

                        let purgedData = data.purgeMetadata(with: metadata, dictionary:dictionary, property:property)

                        if let purgedValue = purgedData.getMetadataValue(dictionary: dictionary, property: property){
                            let purged = ImageMetadata.isValueVoid(purgedValue)

                            if purged{
                                print(property, "hided")
                            }else{
                                print(property, sampleValue, "->", ImageMetadata.getVoidValue(sampleValue))
                            }

//                            print("purged ", hided, property, sampleValue, "->", purgedValue)
//
//                            if !purged{
//                                print("hided failed ----")
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
                        print("sampleValue of \(property) is nil")
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
        var defaults:TestAppDefaults = Defaults(suiteName:"sdfsdfds") as! TestAppDefaults

        XCTAssertEqual(defaults.valueWithCustomCodableType.from, .video)

        defaults.valueWithCustomCodableType = CustomCodableType(from: .livephoto, to:.video)

        XCTAssertEqual(defaults.valueWithCustomCodableType.from, .livephoto)

        defaults.valueWithCustomCodableType = CustomCodableType(from: .video, to: .livephoto)

    }

    func test_UTI_Equality() {

        let uti1 = UTI(rawValue: kUTTypePDF as String)
        let uti2 = UTI.pdf
        let uti3 = UTI.rtf

        XCTAssertTrue(uti1 == uti2)
        XCTAssertTrue(uti2 == uti1)
        XCTAssertFalse(uti1 == uti3)
        XCTAssertFalse(uti2 == uti3)
    }

    func test_UTI_Conformance() {

        let uti1 = UTI.text
        let uti2 = UTI.rtf
        let uti3 = UTI.directory

        XCTAssertTrue( uti2.conforms(to: uti1) )
        XCTAssertFalse( uti1.conforms(to: uti2) )
        XCTAssertFalse( uti1.conforms(to: uti3) )
    }

    func test_UTI_Tags() {

        let uti1 = UTI.pdf

        var uti2 = UTI(withExtension: "pdf")
        XCTAssertTrue( uti1 == uti2 )

        uti2 = UTI(withMimeType: "application/pdf")
        XCTAssertTrue( uti1 == uti2 )

#if os(macOS)
        uti2 = UTI(withPBType: NSPDFPboardType) // Note: NSPasteboardTypePDF doesn't work
        XCTAssertTrue( uti1 == uti2 )

        uti2 = UTI(withOSType: "PDF ")
        XCTAssertTrue( uti1 == uti2 )
#endif

        XCTAssertEqual(uti1.fileExtension, uti2.fileExtension)
        XCTAssertEqual(uti1.mimeType, uti2.mimeType)

#if os(macOS)
        XCTAssertEqual(uti1.pbType, uti2.pbType)
        XCTAssertEqual(uti1.osType, uti2.osType)
#endif
    }

    func test_UTI_Dynamic() {

        XCTAssertFalse(UTI.pdf.isDynamic)

        XCTAssertTrue(UTI(withExtension: "random_unknown_value_xxxxx").isDynamic)
    }


    func test_tempURL() {

        print(UTI.jpeg.fileExtension)

        let url = FileURL.temp("identifier", UTI.jpeg, group: "groupname")

        let diffUrl = FileManager.default.temporaryDirectory.appendingPathComponent("groupname").appendingPathComponent("identifier").appendingPathExtension(UTI.jpeg.fileExtension!)

        XCTAssertTrue(url.absoluteString == diffUrl.absoluteString)
        XCTAssertTrue(UTI(withURL: FileURL.temp("identifier.jpg", nil, group: "groupname")) == UTI.jpeg)
        XCTAssertTrue(UTI(withURL: FileURL.temp("identifier.jpg", nil, group: "groupname2")) == UTI.jpeg)
        XCTAssertTrue(UTI(withURL: FileURL.temp("identifier.jpeg", nil, group: "groupname")) == UTI.jpeg)

        XCTAssertTrue(UTI(withURL: FileURL.temp("identifier", nil)).isDynamic)
        XCTAssertTrue(UTI(withURL: FileURL.temp("identifier", UTI.jpeg)) == UTI.jpeg)

        XCTAssertTrue(UTI(withExtension: "jpg") == UTI.jpeg)
        XCTAssertTrue(UTI(withExtension: "jpeg") == UTI.jpeg)

        XCTAssertTrue(FileCollectableURL.matchedInTemp("identifier", nil, group: "groupname").count == 0)

        XCTAssertTrue(FileCollectableURL.matchedInTemp("identifier.jpg", nil, group: "groupname").count==1)

        XCTAssertTrue(FileCollectableURL.matchedInTemp("identifier.jpg", nil, group: "groupname2").count==1)

        XCTAssertTrue(FileCollectableURL.matchedInTemp("identifier.jpg", nil, group: nil).count==2)

        XCTAssertTrue(FileCollectableURL.matchedInTemp(nil, nil, group: "groupname").count==3)

        XCTAssertTrue(FileCollectableURL.matchedInTemp("identifier", nil).count==1)

        XCTAssertTrue(FileCollectableURL.matchedInTemp("identifier.jpg", nil).count==2)

        FileURL.temp("file.png", nil) // -> file.png
        FileURL.temp("file.png", UTI.png) // -> file.png.png
        FileURL.temp("file", nil) // -> file
        FileURL.temp("file", UTI.png) // -> file.png

        FileURL.temp("file", UTI.png, group:"ggg") // -> ggg/file.png
        FileURL.temp("file.png", nil, group:"ggg") // -> ggg/file.png
        FileURL.temp("file", nil, group:"ggg") // -> ggg/file

        XCTAssertTrue(FileCollectableURL.matchedInTemp("file.png", nil).count==4)
        XCTAssertTrue(FileCollectableURL.matchedInTemp("file.png",  UTI.png).count==1)

        XCTAssertTrue(FileCollectableURL.matchedInTemp("file",  UTI.png, group:"ggg").count==2)
        XCTAssertTrue(FileCollectableURL.matchedInTemp("file.png",  nil, group:"ggg").count==2)
        XCTAssertTrue(FileCollectableURL.matchedInTemp(nil,  nil, group:"ggg").count==3)

        XCTAssertTrue(FileCollectableURL.matchedInTemp(nil,  UTI.png).count==5)
        XCTAssertTrue(FileCollectableURL.matchedInTemp("file",  UTI.png).count==4)
        XCTAssertTrue(FileCollectableURL.matchedInTemp("file",  nil).count==2)

        FileURL.temp("AssetIO.LivePhoto", group:fileName())
        XCTAssertTrue(FileCollectableURL.matchedInTemp("AssetIO.LivePhoto", group:fileName()).count==1)


        let groupname = "sd<>*fdf!:=?.@34ㄹㅎsd.fds.gif"
        FileURL.temp("file", UTI.gif, group: groupname)
        XCTAssertTrue(FileCollectableURL.matchedInTemp("file.gif", group:groupname).count==1)
        XCTAssertTrue(FileCollectableURL.matchedInTemp("file", UTI.gif, group:groupname).count==1)
        XCTAssertTrue(FileCollectableURL.matchedInTemp("file", UTI.gif).count==1)
        XCTAssertTrue(FileCollectableURL.matchedInTemp("file", UTI.gif, group:"BBBB").count==0)
        XCTAssertTrue(FileCollectableURL.matchedInTemp(nil, group:groupname).count==1)


//          FileURL.discardMatchedTemporaryURLs(nil)
        FileCollectableURL.discardAll()
        XCTAssertTrue(FileCollectableURL.matchedInTemp(nil).count == 0)

        XCTAssertTrue(FileURL.fileAndQueuePrivateGroup()=="CodeKitTests_com.apple.main-thread")
        XCTAssertTrue(FileURL.filePrivateGroup()=="CodeKitTests")
        XCTAssertTrue(FileURL.queuePrivateGroup()=="com.apple.main-thread")

        XCTAssertTrue(UTI(withURL: FileURL.temp("\(UUID().uuidString)_TimeLapseVideo", UTI.quickTimeMovie, group:FileURL.fileAndQueuePrivateGroup()))==UTI.quickTimeMovie)

        XCTAssertTrue(FileURL.temp("\(UUID().uuidString)_TimeLapseVideo", UTI.quickTimeMovie, group:FileURL.fileAndQueuePrivateGroup()).pathExtension=="mov")


        print(FileURL.glob(FileURL.tempBase.path+"/*"))
        print(FileURL.glob(FileURL.tempBase.path+"/*.jpg"))
        print(FileURL.glob(FileURL.tempBase.path+"/*.png"))
    }
}



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
