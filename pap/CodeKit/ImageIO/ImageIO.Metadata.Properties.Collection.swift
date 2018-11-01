//
// Created by BLACKGENE on 18/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension ImageMetadata{

    /*
Altitude: 44.83 m (147.07 ft)
Altitude Reference: above sea level
Date Stamp: 7 Apr 2018
Destination Bearing: 56.491
Destination Bearing Reference: True direction
Horizontal Positioning Error: 8
Image Direction: 56.491
Image Direction Reference: True north
Latitude: 52° 24’ 14.292” N
Longitude: 0° 0’ 0” E
Speed: 0.071
Speed Reference: Kilometers per hour
Time Stamp: 13:37:15 UTC
*/


/*
Aperture Value: 1.696
Brightness Value: 10.713
Color Space: Uncalibrated
Components Configuration: 1, 2, 3, 0
Custom Rendered: 6
Date Time Digitized: 7 Apr 2018 at 3:37:16 PM
Date Time Original: 7 Apr 2018 at 3:37:16 PM
Exif Version: 2.2.1
Exposure Bias Value: 0
Exposure Time: 1/2703
Flash: No Flash
FlashPix Version: 1.0
FNumber: 1.8
Focal Length: 4
Focal Length In 35mm Film: 28
ISO Speed Ratings: 20
Lens Make: Apple
Lens Model: iPhone X back camera 4mm f/1.8
Lens Specification: 4, 4, 1.8, 1.8
Metering Mode: Pattern
Pixel X Dimension: 6,022
Pixel Y Dimension: 3,896
Scene Capture Type: Standard
Scene Type: A directly photographed image
Sensing Method: One-chip color area sensor
Shutter Speed Value: 1/2702
Sub-second Time Digitized: 772
Sub-second Time Original: 772
White Balance: Auto white balance
*/

    public struct Collection {

        public static let DefaultSensitivity: ImageMetadataPropertyCollection = [
            ImageMetadata.Dictionary.GPS: [
                ImageMetadata.Property.GPSDateStamp
                , ImageMetadata.Property.GPSTimeStamp
                , ImageMetadata.Property.GPSAltitude
                , ImageMetadata.Property.GPSLatitude
                , ImageMetadata.Property.GPSLongitude
                , ImageMetadata.Property.GPSImgDirection
                , ImageMetadata.Property.GPSImgDirectionRef
            ],

            ImageMetadata.Dictionary.Exif: [
                ImageMetadata.Property.ExifDateTimeDigitized
                , ImageMetadata.Property.ExifDateTimeOriginal
                , ImageMetadata.Property.ExifLensMake
                , ImageMetadata.Property.ExifLensModel
                , ImageMetadata.Property.ExifLensSerialNumber
                , ImageMetadata.Property.ExifBodySerialNumber
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
}