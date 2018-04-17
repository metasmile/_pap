//
// Created by BLACKGENE on 16/04/2018.
// Copyright c 2018 Stells. All rights reserved.
//

import Foundation
import ImageIO

public struct ImageMetadataProperties{
    public struct LabelsForKeys {
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
        static let GPS:[String:String] = [
            kCGImagePropertyGPSDateStamp as String : "Date Stamp",
            kCGImagePropertyGPSAltitudeRef as String : "Altitude",
            kCGImagePropertyGPSAltitude as String : "Altitude Reference",
            kCGImagePropertyGPSDestBearing as String : "Destination Bearing",
            kCGImagePropertyGPSDestBearingRef as String : "Destination Bearing Reference",
            kCGImagePropertyGPSHPositioningError as String : "Horizontal Positioning Error",
            kCGImagePropertyGPSImgDirection as String: "Image Direction",
            kCGImagePropertyGPSImgDirectionRef as String: "Image Direction Reference",
            kCGImagePropertyGPSLatitude as String : "Latitude",
            kCGImagePropertyGPSLatitudeRef as String : "Latitude Reference",
            kCGImagePropertyGPSLongitude as String : "Longitude",
            kCGImagePropertyGPSLongitudeRef as String : "Longitude Reference",
            kCGImagePropertyGPSSpeed as String : "Speed",
            kCGImagePropertyGPSSpeedRef as String : "Speed Reference",
            kCGImagePropertyGPSTimeStamp as String : "Time Stamp",
            kCGImagePropertyGPSDifferental as String : "Differental",
        ]

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
        static let EXIF:[String:String] = [
            "":""
        ]

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
        static let TIFF:[String:String] = [
            kCGImagePropertyTIFFDateTime as String : "Date Time",
            kCGImagePropertyTIFFMake as String : "Make",
            kCGImagePropertyTIFFModel as String : "Model",
            kCGImagePropertyTIFFOrientation as String : "Orientation",
            kCGImagePropertyTIFFResolutionUnit as String : "Resolution Unit",
            kCGImagePropertyTIFFSoftware as String : "Software",
            kCGImagePropertyTIFFTileLength as String : "Tile Length",
            kCGImagePropertyTIFFTileWidth as String : "Tile Width",
            kCGImagePropertyTIFFXResolution as String : "X Resolution",
            kCGImagePropertyTIFFYResolution as String : "Y Resolution"
        ]
    }

    public struct Keys {

/*
iPhone X

1 LatitudeRef
2 Latitude
3 LongitudeRef
4 Longitude
5 AltitudeRef
6 Altitude
7 TimeStamp
12 SpeedRef
13 Speed
16 ImgDirectionRef
17 ImgDirection
23 DestBearingRef
24 DestBearing
29 DateStamp
31 HPositioningError
*/
        static let GPS:[String] = [kCGImagePropertyGPSVersion as String,
                                   kCGImagePropertyGPSLatitudeRef as String,
                                   kCGImagePropertyGPSLatitude as String,
                                   kCGImagePropertyGPSLongitudeRef as String,
                                   kCGImagePropertyGPSLongitude as String,
                                   kCGImagePropertyGPSAltitudeRef as String,
                                   kCGImagePropertyGPSAltitude as String,
                                   kCGImagePropertyGPSTimeStamp as String,
                                   kCGImagePropertyGPSSatellites as String,
                                   kCGImagePropertyGPSStatus as String,
                                   kCGImagePropertyGPSMeasureMode as String,
                                   kCGImagePropertyGPSDOP as String,
                                   kCGImagePropertyGPSSpeedRef as String,
                                   kCGImagePropertyGPSSpeed as String,
                                   kCGImagePropertyGPSTrackRef as String,
                                   kCGImagePropertyGPSTrack as String,
                                   kCGImagePropertyGPSImgDirectionRef as String,
                                   kCGImagePropertyGPSImgDirection as String,
                                   kCGImagePropertyGPSMapDatum as String,
                                   kCGImagePropertyGPSDestLatitudeRef as String,
                                   kCGImagePropertyGPSDestLatitude as String,
                                   kCGImagePropertyGPSDestLongitudeRef as String,
                                   kCGImagePropertyGPSDestLongitude as String,
                                   kCGImagePropertyGPSDestBearingRef as String,
                                   kCGImagePropertyGPSDestBearing as String,
                                   kCGImagePropertyGPSDestDistanceRef as String,
                                   kCGImagePropertyGPSDestDistance as String,
                                   kCGImagePropertyGPSProcessingMethod as String,
                                   kCGImagePropertyGPSAreaInformation as String,
                                   kCGImagePropertyGPSDateStamp as String,
                                   kCGImagePropertyGPSDifferental as String,
                                   kCGImagePropertyGPSHPositioningError as String]


/*
iPhone X

0, 'ExposureTime'
1, 'FNumber'
2, 'ExposureProgram'
4, 'ISOSpeedRatings'
12, 'ExifVersion'
13, 'DateTimeOriginal'
14, 'DateTimeDigitized'
15, 'ComponentsConfiguration'
17, 'ShutterSpeedValue'
18, 'ApertureValue'
19, 'BrightnessValue'
20, 'ExposureBiasValue'
23, 'MeteringMode'
25, 'Flash'
26, 'FocalLength'
27, 'SubjectArea'
31, 'SubsecTimeOriginal'
32, 'SubsecTimeDigitized'
33, 'FlashPixVersion'
34, 'ColorSpace'
35, 'PixelXDimension'
36, 'PixelYDimension'
45, 'SensingMethod'
47, 'SceneType'
50, 'ExposureMode'
51, 'WhiteBalance'
53, 'FocalLenIn35mmFilm'
54, 'SceneCaptureType'
64, 'LensSpecification'
65, 'LensMake'
66, 'LensModel'
*/

        static let EXIF:[String] = [kCGImagePropertyExifExposureTime as String,
                                    kCGImagePropertyExifFNumber as String,
                                    kCGImagePropertyExifExposureProgram as String,
                                    kCGImagePropertyExifSpectralSensitivity as String,
                                    kCGImagePropertyExifISOSpeedRatings as String,
                                    kCGImagePropertyExifOECF as String,
                                    kCGImagePropertyExifSensitivityType as String,
                                    kCGImagePropertyExifStandardOutputSensitivity as String,
                                    kCGImagePropertyExifRecommendedExposureIndex as String,
                                    kCGImagePropertyExifISOSpeed as String,
                                    kCGImagePropertyExifISOSpeedLatitudeyyy as String,
                                    kCGImagePropertyExifISOSpeedLatitudezzz as String,
                                    kCGImagePropertyExifVersion as String,
                                    kCGImagePropertyExifDateTimeOriginal as String,
                                    kCGImagePropertyExifDateTimeDigitized as String,
                                    kCGImagePropertyExifComponentsConfiguration as String,
                                    kCGImagePropertyExifCompressedBitsPerPixel as String,
                                    kCGImagePropertyExifShutterSpeedValue as String,
                                    kCGImagePropertyExifApertureValue as String,
                                    kCGImagePropertyExifBrightnessValue as String,
                                    kCGImagePropertyExifExposureBiasValue as String,
                                    kCGImagePropertyExifMaxApertureValue as String,
                                    kCGImagePropertyExifSubjectDistance as String,
                                    kCGImagePropertyExifMeteringMode as String,
                                    kCGImagePropertyExifLightSource as String,
                                    kCGImagePropertyExifFlash as String,
                                    kCGImagePropertyExifFocalLength as String,
                                    kCGImagePropertyExifSubjectArea as String,
                                    kCGImagePropertyExifMakerNote as String,
                                    kCGImagePropertyExifUserComment as String,
                                    kCGImagePropertyExifSubsecTime as String,
                                    kCGImagePropertyExifSubsecTimeOriginal as String,
                                    kCGImagePropertyExifSubsecTimeDigitized as String,
                                    kCGImagePropertyExifFlashPixVersion as String,
                                    kCGImagePropertyExifColorSpace as String,
                                    kCGImagePropertyExifPixelXDimension as String,
                                    kCGImagePropertyExifPixelYDimension as String,
                                    kCGImagePropertyExifRelatedSoundFile as String,
                                    kCGImagePropertyExifFlashEnergy as String,
                                    kCGImagePropertyExifSpatialFrequencyResponse as String,
                                    kCGImagePropertyExifFocalPlaneXResolution as String,
                                    kCGImagePropertyExifFocalPlaneYResolution as String,
                                    kCGImagePropertyExifFocalPlaneResolutionUnit as String,
                                    kCGImagePropertyExifSubjectLocation as String,
                                    kCGImagePropertyExifExposureIndex as String,
                                    kCGImagePropertyExifSensingMethod as String,
                                    kCGImagePropertyExifFileSource as String,
                                    kCGImagePropertyExifSceneType as String,
                                    kCGImagePropertyExifCFAPattern as String,
                                    kCGImagePropertyExifCustomRendered as String,
                                    kCGImagePropertyExifExposureMode as String,
                                    kCGImagePropertyExifWhiteBalance as String,
                                    kCGImagePropertyExifDigitalZoomRatio as String,
                                    kCGImagePropertyExifFocalLenIn35mmFilm as String,
                                    kCGImagePropertyExifSceneCaptureType as String,
                                    kCGImagePropertyExifGainControl as String,
                                    kCGImagePropertyExifContrast as String,
                                    kCGImagePropertyExifSaturation as String,
                                    kCGImagePropertyExifSharpness as String,
                                    kCGImagePropertyExifDeviceSettingDescription as String,
                                    kCGImagePropertyExifSubjectDistRange as String,
                                    kCGImagePropertyExifImageUniqueID as String,
                                    kCGImagePropertyExifCameraOwnerName as String,
                                    kCGImagePropertyExifBodySerialNumber as String,
                                    kCGImagePropertyExifLensSpecification as String,
                                    kCGImagePropertyExifLensMake as String,
                                    kCGImagePropertyExifLensModel as String,
                                    kCGImagePropertyExifLensSerialNumber as String,
                                    kCGImagePropertyExifGamma as String]

/*
iPhone X

DateTime = "2018:04:15 15:46:13";
    Make = Apple;
    Model = "iPhone X";
    Orientation = 3;
    ResolutionUnit = 2;
    Software = "11.3";
    TileLength = 512;
    TileWidth = 512;
    XResolution = 72;
    YResolution = 72;
*/
        static let TIFF:[String] = [
            kCGImagePropertyTIFFCompression as String
            ,kCGImagePropertyTIFFPhotometricInterpretation as String
            ,kCGImagePropertyTIFFDocumentName as String
            ,kCGImagePropertyTIFFImageDescription as String
            ,kCGImagePropertyTIFFMake as String
            ,kCGImagePropertyTIFFModel as String
            ,kCGImagePropertyTIFFOrientation as String
            ,kCGImagePropertyTIFFXResolution as String
            ,kCGImagePropertyTIFFYResolution as String
            ,kCGImagePropertyTIFFResolutionUnit as String
            ,kCGImagePropertyTIFFSoftware as String
            ,kCGImagePropertyTIFFTransferFunction as String
            ,kCGImagePropertyTIFFDateTime as String
            ,kCGImagePropertyTIFFArtist as String
            ,kCGImagePropertyTIFFHostComputer as String
            ,kCGImagePropertyTIFFCopyright as String
            ,kCGImagePropertyTIFFWhitePoint as String
            ,kCGImagePropertyTIFFPrimaryChromaticities as String
            ,kCGImagePropertyTIFFTileWidth as String
            ,kCGImagePropertyTIFFTileLength as String
        ]


    }


}


