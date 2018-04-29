//
// Created by BLACKGENE on 19/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

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
        }else if let rootValue = metadata[property]{
            return updateMetadata(dictionary: dictionary, property: property, value: ImageMetadata.getVoidValue(rootValue) ?? rootValue)
        }
        return metadata
    }

    func purgeMetadata(for properties: ImageMetadataPropertyCollection?) -> [String:Any] {
        let gotMetadata = self as! [String:Any]

        var purgedMetadata = gotMetadata

        for (rootProperty, _) in gotMetadata {
            // purge for keys in specific collection
            if let collection = properties{
                if let colllection_p = collection[rootProperty]{
                    for p in colllection_p {
                        purgedMetadata = purgedMetadata.purgeMetadata(dictionary:rootProperty, property: p)
                    }
                }
            }else{
                // undefined specific collection -> purge all if possible
                if let properties = gotMetadata[rootProperty] as? [String:Any]{
                    for (p, _) in properties{
                        purgedMetadata = purgedMetadata.purgeMetadata(dictionary:rootProperty, property: p)
                    }
                }else if let _ = gotMetadata[rootProperty]{
                    purgedMetadata = purgedMetadata.purgeMetadata(dictionary:nil, property: rootProperty)
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

