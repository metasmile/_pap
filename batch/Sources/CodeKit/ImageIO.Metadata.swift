//
// Created by BLACKGENE on 12/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import ImageIO
import MobileCoreServices

extension ImageMetadata{
    private static let VoidDateFormatter = DateFormatter()
    private static let VoidDateTimeFormats = [
        "yyyy:MM:dd hh:mm:ss",
        "yyyy:MM:dd",
        "hh:mm:ss"
    ]
    private static let VoidDirectionValues = [
        "W":"E", "E":"W", "N":"S", "S":"N"
    ]
    private static let VoidTimeStamp = "00:00:00"
    private static let VoidSingleUpperCaseString = "X"
    private static let VoidAnyString = "-"

    static func getVoidValue(_ value:Any) -> Any?{
        if value is Double{
            return Double()
        }
        if value is Float{
            return Float()
        }
        if value is Int{
            return 0
        }
        if value is String{
            let val = value as! String

            // null timestamp
            if val == VoidTimeStamp{
                return val
            }

            // date
            for format in VoidDateTimeFormats {
                VoidDateFormatter.dateFormat = format
                if let _ = VoidDateFormatter.date(from: val){
                    return VoidDateFormatter.string(from: Date(timeIntervalSinceReferenceDate: 0))
                }
            }

            // check uppercase and single
            if val.count==1 && val != val.lowercased(){
                if VoidDirectionValues[val] == nil{
                    return VoidSingleUpperCaseString
                }else{
                    return VoidDirectionValues[val]
                }
            }

            return VoidAnyString
        }
        if value is NSArray{
            let val = value as! NSArray

            // fill void value
            if val.count>0{
                return val.compactMap { element -> Any? in
                    return getVoidValue(element)
                }
            }

            return NSArray()
        }
        if value is NSDictionary{
            let val = value as! NSDictionary

            if let keys = val.allKeys as? [NSCopying]{
                return NSDictionary(objects: val.allValues.compactMap { value -> Any? in
                    return getVoidValue(value)
                }, forKeys: keys)
            }
            return [VoidAnyString:VoidAnyString]
        }

        print("[i] Void value is not defined yet: ")
        return nil
    }

    static func isValueVoid(_ value:Any) -> Bool{
        if let voidValue = getVoidValue(value){
            if isEqualAny(type: Double.self, value1: voidValue, value2: value){}
            else if isEqualAny(type: Float.self, value1: voidValue, value2: value){}
            else if isEqualAny(type: Int.self, value1: voidValue, value2: value){}
            else if isEqualAny(type: String.self, value1: voidValue, value2: value){}
            else if isEqualAny(type: Date.self, value1: voidValue, value2: value){}
            else if isEqualAny(type: NSArray.self, value1: voidValue, value2: value){}
            else if isEqualAny(type: NSDictionary.self, value1: voidValue, value2: value){}
            else{
                return false
            }
            return true
        }
        return false
    }
}

extension Data {
    func getMetadata() -> [String: Any]? {
        let imageSource = CGImageSourceCreateWithData(self as CFData, nil)
        if let imageSource = imageSource {
            let options: [String: Any] = [kCGImageSourceShouldCache as String: false]
            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, options as CFDictionary)

            return imageProperties as? [String: Any]
        } else {
            print("failed to read metadata")
            return nil
        }
    }

    func getMetadataValue(dictionary:String?=nil, property:String) -> Any? {
        if let d = dictionary, let dictionaryItemDict = getMetadata()?[d] as? [String: Any]{
            return dictionaryItemDict[property]
        }
        return nil
    }

    func setMetadata(with metadata:[String:Any]) -> Data{
        let source = CGImageSourceCreateWithData(self as CFData, nil)!
        let imageData = CFDataCreateMutable(nil, 0)!
        let destination = CGImageDestinationCreateWithData(imageData, kUTTypeJPEG, 1, nil)!
        CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)
        CGImageDestinationFinalize(destination)

        return imageData as Data
    }

    @discardableResult
    func updateMetadata(with metadata:[String:Any], dictionary:String, property:String, value:Any?) -> Data {
        #if DEBUG
        if value == nil{
            print("[!] WARNING: Value is nil, means that remove property itself, but it cannot be guaranteed to remove while actually handling on OS.")
        }
        #endif
        return setMetadata(with: metadata.updateMetadata(dictionary: dictionary, property: property, value: value))
    }

    func purgeMetadata(with metadata:[String:Any], dictionary:String, property:String) -> Data {
        return setMetadata(with: metadata.purgeMetadata(dictionary: dictionary, property: property))
    }

    func purgeMetadata(with metadata:[String:Any], for collection: ImageMetadataPropertyCollection?) -> Data {
        return setMetadata(with: metadata.purgeMetadata(for: collection))
    }

    func setMetadata(with metadata:[String:Any], comment: String?, software: String?) -> Data {
        let newMetadata = metadata.changeMetadata(with: nil, comment: comment, software: software, exifOrientation: nil)

        return setMetadata(with: newMetadata)
    }

    func setMetadata(with metadata:[String:Any], comment: String?, software: String?, exifOrientation: CGImagePropertyOrientation?) -> Data {
        let newMetadata = metadata.changeMetadata(with: nil, comment: comment, software: software, exifOrientation: exifOrientation)
        return setMetadata(with: newMetadata)
    }

    func changeMetadata(metadata: [String: Any], imageSize: CGSize?, comment: String?, software: String?, exifOrientation: CGImagePropertyOrientation?) -> [String: Any] {
        var newMetadata = metadata
        var exifdata = metadata[ImageMetadata.Dictionary.Exif] as? [String: Any]
        var tiffdata = metadata[ImageMetadata.Dictionary.TIFF] as? [String: Any]
        if exifdata == nil {
            exifdata = [String:Any]()
        }
        if tiffdata == nil {
            tiffdata = [String:Any]()
        }

        if let imageSize = imageSize {
            newMetadata.updateValue(imageSize.width, forKey: ImageMetadata.PixelWidth )
            newMetadata.updateValue(imageSize.height, forKey: ImageMetadata.PixelHeight )
            exifdata!.updateValue(imageSize.width, forKey: ImageMetadata.Property.ExifPixelXDimension )
            exifdata!.updateValue(imageSize.height, forKey: ImageMetadata.Property.ExifPixelYDimension )
        }

        if let comment = comment {
            exifdata!.updateValue(comment, forKey: ImageMetadata.Property.ExifUserComment )
        }

        if let software = software {
            tiffdata!.updateValue(software, forKey: ImageMetadata.Property.TIFFSoftware )
        }

        if let exifOrientation = exifOrientation {
            newMetadata.updateValue(exifOrientation.rawValue, forKey: ImageMetadata.Orientation)
            tiffdata!.updateValue(exifOrientation.rawValue, forKey: ImageMetadata.Property.TIFFOrientation )
        }

        newMetadata.updateValue(exifdata!, forKey: ImageMetadata.Dictionary.Exif )
        newMetadata.updateValue(tiffdata!, forKey: ImageMetadata.Dictionary.TIFF )

        return newMetadata
    }
}

extension Dictionary{

    @discardableResult
    func updateMetadata(dictionary:String?=nil, property:String, value:Any?) -> [String:Any] {
        var newMetadata = self as! [String:Any]

        if let dictionary = dictionary, let data = newMetadata[dictionary] as? [String:Any]{
            var data = data
            if value == nil{
                data.removeValue(forKey: property)
            }else{
                data[property] = value
            }
            newMetadata[dictionary] = data
        }else{
            if value == nil{
                newMetadata.removeValue(forKey: property)
            }else{
                newMetadata[property] = value
            }
        }

        return newMetadata
    }

    func purgeMetadata(dictionary:String?=nil, property:String) -> [String:Any] {
        let metadata = self as! [String:Any]
        if let dictionary = dictionary, let dictionarydata = metadata[dictionary] as? [String:Any]{
            if let value = dictionarydata[property]{
                return updateMetadata(dictionary: dictionary, property: property, value: ImageMetadata.getVoidValue(value) ?? value)
            }
        }
        if let rootValue = metadata[property]{
            return updateMetadata(dictionary: dictionary, property: property, value: ImageMetadata.getVoidValue(rootValue) ?? rootValue)
        }
        return metadata
    }

    func purgeMetadata(for properties: ImageMetadataPropertyCollection?) -> [String:Any] {
        let gotMetadata = self as! [String:Any]

        var purgedMetadata = gotMetadata

        for (rootProperty, _) in gotMetadata {
            // purge for keys in specific collection
            if let original_kv = gotMetadata[rootProperty] as? [String:Any]
            , let collection = properties
            , let target_k = collection[rootProperty]{
                for p in target_k{
                    if let v = original_kv[p]{
                        purgedMetadata = purgedMetadata.updateMetadata(dictionary: rootProperty, property: p, value: ImageMetadata.getVoidValue(v) ?? v)
                    }
                }
            }else{
                // undefined specific collection -> purge all if possible
                if let properties = gotMetadata[rootProperty] as? [String:Any]{
                    for (p, v) in properties{
                        purgedMetadata = purgedMetadata.updateMetadata(dictionary: rootProperty, property: p, value: ImageMetadata.getVoidValue(v) ?? v)
                    }
                }else if let rootValue = gotMetadata[rootProperty]{
                    purgedMetadata = purgedMetadata.updateMetadata(dictionary: nil, property: rootProperty, value: ImageMetadata.getVoidValue(rootValue) ?? rootValue)
                }
            }
        }
        return purgedMetadata
    }

    func changeMetadata(with imageSize: CGSize?, comment: String?, software: String?, exifOrientation: CGImagePropertyOrientation?) -> [String: Any] {
        var newMetadata = self as! [String:Any]
        var exifdata = newMetadata[ImageMetadata.Dictionary.Exif] as? [String:Any]
        var tiffdata = newMetadata[ImageMetadata.Dictionary.TIFF] as? [String:Any]
        if exifdata == nil {
            exifdata = [String:Any]()
        }
        if tiffdata == nil {
            tiffdata = [String:Any]()
        }

        if let imageSize = imageSize {
            newMetadata.updateValue(imageSize.width, forKey: ImageMetadata.PixelWidth )
            newMetadata.updateValue(imageSize.height, forKey: ImageMetadata.PixelHeight )
            exifdata!.updateValue(imageSize.width, forKey: ImageMetadata.Property.ExifPixelXDimension )
            exifdata!.updateValue(imageSize.height, forKey: ImageMetadata.Property.ExifPixelYDimension )
        }

        if let comment = comment {
            exifdata!.updateValue(comment, forKey: ImageMetadata.Property.ExifUserComment )
        }

        if let software = software {
            tiffdata!.updateValue(software, forKey: ImageMetadata.Property.TIFFSoftware )
        }

        if let exifOrientation = exifOrientation {
            newMetadata.updateValue(exifOrientation.rawValue, forKey: ImageMetadata.Orientation)
            tiffdata!.updateValue(exifOrientation.rawValue, forKey: ImageMetadata.Property.TIFFOrientation )
        }

        newMetadata.updateValue(exifdata!, forKey: ImageMetadata.Dictionary.Exif )
        newMetadata.updateValue(tiffdata!, forKey: ImageMetadata.Dictionary.TIFF )

        return newMetadata
    }
}

