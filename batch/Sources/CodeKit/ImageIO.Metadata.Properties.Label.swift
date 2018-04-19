//
// Created by BLACKGENE on 18/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension ImageMetadata{

    public struct Labels {

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
        static var GPS:[String:String] {
            return [
                Property.GPSDateStamp as String : "Date Stamp",
                Property.GPSAltitudeRef as String : "Altitude",
                Property.GPSAltitude as String : "Altitude Reference",
                Property.GPSDestBearing as String : "Destination Bearing",
                Property.GPSDestBearingRef as String : "Destination Bearing Reference",
                Property.GPSHPositioningError as String : "Horizontal Positioning Error",
                Property.GPSImgDirection as String: "Image Direction",
                Property.GPSImgDirectionRef as String: "Image Direction Reference",
                Property.GPSLatitude as String : "Latitude",
                Property.GPSLatitudeRef as String : "Latitude Reference",
                Property.GPSLongitude as String : "Longitude",
                Property.GPSLongitudeRef as String : "Longitude Reference",
                Property.GPSSpeed as String : "Speed",
                Property.GPSSpeedRef as String : "Speed Reference",
                Property.GPSTimeStamp as String : "Time Stamp",
                Property.GPSDifferental as String : "Differental",
            ]
        }

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
        static var Exif:[String:String] {
            return [
                "":""
            ]
        }

/*
Date Time: 7 Apr 2018 at 3:37:16 PM
Make: Apple
Model: iPhone X
Orientation: 1 (Normal)
Resolution Unit: inches
Software: 11.3
X Resolution: 72
Y Resolution: 72
*/
        static var TIFF:[String:String] {
            return [
                Property.TIFFDateTime as String : "Date Time",
                Property.TIFFMake as String : "Make",
                Property.TIFFModel as String : "Model",
                Property.TIFFOrientation as String : "Orientation",
                Property.TIFFResolutionUnit as String : "Resolution Unit",
                Property.TIFFSoftware as String : "Software",
                Property.TIFFTileLength as String : "Tile Length",
                Property.TIFFTileWidth as String : "Tile Width",
                Property.TIFFXResolution as String : "X Resolution",
                Property.TIFFYResolution as String : "Y Resolution"
            ]
        }
    }
}