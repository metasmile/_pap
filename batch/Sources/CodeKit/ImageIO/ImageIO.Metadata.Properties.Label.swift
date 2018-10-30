//
// Created by BLACKGENE on 18/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension ImageMetadata{

    public struct Labels {

/*
    Altitude = "30.6360153256705";
    AltitudeRef = 0;
    DateStamp = "2018:04:07";
    DestBearing = "44.0509337860781";
    DestBearingRef = T;
    HPositioningError = "29.69374313940725";
    ImgDirection = "44.0509337860781";
    ImgDirectionRef = T;
    Latitude = "52.40276333333333";
    LatitudeRef = N;
    Longitude = "13.05823333333333";
    LongitudeRef = E;
    Speed = "0.02591712852995513";
    SpeedRef = K;
    TimeStamp = "16:13:16";
*/
        static var GPS:[String:String] {
            return [
                Property.GPSDateStamp: "Date Stamp",
                Property.GPSAltitudeRef: "Altitude",
                Property.GPSAltitude: "Altitude Reference",
                Property.GPSDestBearing: "Destination Bearing",
                Property.GPSDestBearingRef: "Destination Bearing Reference",
                Property.GPSHPositioningError: "Horizontal Positioning Error",
                Property.GPSImgDirection: "Image Direction",
                Property.GPSImgDirectionRef: "Image Direction Reference",
                Property.GPSLatitude: "Latitude",
                Property.GPSLatitudeRef: "Latitude Reference",
                Property.GPSLongitude: "Longitude",
                Property.GPSLongitudeRef: "Longitude Reference",
                Property.GPSSpeed: "Speed",
                Property.GPSSpeedRef: "Speed Reference",
                Property.GPSTimeStamp: "Time Stamp",
                Property.GPSDifferental: "Differental",
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
                Property.TIFFDateTime: "Date Time",
                Property.TIFFMake: "Make",
                Property.TIFFModel: "Model",
                Property.TIFFOrientation: "Orientation",
                Property.TIFFResolutionUnit: "Resolution Unit",
                Property.TIFFSoftware: "Software",
                Property.TIFFTileLength: "Tile Length",
                Property.TIFFTileWidth: "Tile Width",
                Property.TIFFXResolution: "X Resolution",
                Property.TIFFYResolution: "Y Resolution"
            ]
        }
    }
}