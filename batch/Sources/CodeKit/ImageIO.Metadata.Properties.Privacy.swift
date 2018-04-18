//
// Created by BLACKGENE on 18/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension ImageMetadata{
    public static let DefaultSensitiveProperties: ImageMetadataCollection = [
        ImageMetadata.Dictionary.GPS: [
            ImageMetadata.Property.GPSDateStamp
            , ImageMetadata.Property.GPSDateStamp
            , ImageMetadata.Property.GPSAltitude
            , ImageMetadata.Property.GPSAltitudeRef
            , ImageMetadata.Property.GPSLatitude
            , ImageMetadata.Property.GPSLatitudeRef
            , ImageMetadata.Property.GPSLongitude
            , ImageMetadata.Property.GPSLongitudeRef
            , ImageMetadata.Property.GPSImgDirection
            , ImageMetadata.Property.GPSImgDirectionRef
        ],

        ImageMetadata.Dictionary.Exif: [
            ImageMetadata.Property.ExifDateTimeDigitized
            , ImageMetadata.Property.ExifDateTimeOriginal
            , ImageMetadata.Property.ExifLensMake
            , ImageMetadata.Property.ExifLensModel
            , ImageMetadata.Property.ExifLensSerialNumber
            , ImageMetadata.Property.ExifLensSerialNumber
            , ImageMetadata.Property.ExifSubsecTime
            , ImageMetadata.Property.ExifSubsecTimeOriginal
            , ImageMetadata.Property.ExifSubsecTimeDigitized
        ],

        ImageMetadata.Dictionary.TIFF: [
            ImageMetadata.Property.TIFFDateTime
            , ImageMetadata.Property.TIFFArtist
            , ImageMetadata.Property.TIFFCopyright
            , ImageMetadata.Property.TIFFDocumentName
            , ImageMetadata.Property.TIFFSoftware
            , ImageMetadata.Property.TIFFMake
            , ImageMetadata.Property.TIFFModel
            , ImageMetadata.Property.TIFFImageDescription
            , ImageMetadata.Property.TIFFHostComputer
        ],
    ]
}