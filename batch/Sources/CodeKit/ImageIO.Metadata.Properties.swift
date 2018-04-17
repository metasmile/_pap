//
// Created by BLACKGENE on 16/04/2018.
// Copyright c 2018 Stells. All rights reserved.
//

import Foundation
import ImageIO

public struct ImageMetadata {
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
            Keys.GPSDateStamp as String : "Date Stamp",
            Keys.GPSAltitudeRef as String : "Altitude",
            Keys.GPSAltitude as String : "Altitude Reference",
            Keys.GPSDestBearing as String : "Destination Bearing",
            Keys.GPSDestBearingRef as String : "Destination Bearing Reference",
            Keys.GPSHPositioningError as String : "Horizontal Positioning Error",
            Keys.GPSImgDirection as String: "Image Direction",
            Keys.GPSImgDirectionRef as String: "Image Direction Reference",
            Keys.GPSLatitude as String : "Latitude",
            Keys.GPSLatitudeRef as String : "Latitude Reference",
            Keys.GPSLongitude as String : "Longitude",
            Keys.GPSLongitudeRef as String : "Longitude Reference",
            Keys.GPSSpeed as String : "Speed",
            Keys.GPSSpeedRef as String : "Speed Reference",
            Keys.GPSTimeStamp as String : "Time Stamp",
            Keys.GPSDifferental as String : "Differental",
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
            Keys.TIFFDateTime as String : "Date Time",
            Keys.TIFFMake as String : "Make",
            Keys.TIFFModel as String : "Model",
            Keys.TIFFOrientation as String : "Orientation",
            Keys.TIFFResolutionUnit as String : "Resolution Unit",
            Keys.TIFFSoftware as String : "Software",
            Keys.TIFFTileLength as String : "Tile Length",
            Keys.TIFFTileWidth as String : "Tile Width",
            Keys.TIFFXResolution as String : "X Resolution",
            Keys.TIFFYResolution as String : "Y Resolution"
        ]
    }

    static let supportedDictionaries:[String] = [Dictionary.TIFF, Dictionary.EXIF, Dictionary.GPS]

    public struct Dictionary {
        static let GPS:String = kCGImagePropertyGPSDictionary as String
        static let EXIF:String = kCGImagePropertyExifDictionary as String
        static let TIFF:String = kCGImagePropertyTIFFDictionary as String
    }

    public struct Keys {
        // (kCGImageProperty)(.+)\sas\sString -> static let $2 = $1$2 as String

        static let GPSVersion = kCGImagePropertyGPSVersion as String
        static let GPSLatitudeRef = kCGImagePropertyGPSLatitudeRef as String
        static let GPSLatitude = kCGImagePropertyGPSLatitude as String
        static let GPSLongitudeRef = kCGImagePropertyGPSLongitudeRef as String
        static let GPSLongitude = kCGImagePropertyGPSLongitude as String
        static let GPSAltitudeRef = kCGImagePropertyGPSAltitudeRef as String
        static let GPSAltitude = kCGImagePropertyGPSAltitude as String
        static let GPSTimeStamp = kCGImagePropertyGPSTimeStamp as String
        static let GPSSatellites = kCGImagePropertyGPSSatellites as String
        static let GPSStatus = kCGImagePropertyGPSStatus as String
        static let GPSMeasureMode = kCGImagePropertyGPSMeasureMode as String
        static let GPSDOP = kCGImagePropertyGPSDOP as String
        static let GPSSpeedRef = kCGImagePropertyGPSSpeedRef as String
        static let GPSSpeed = kCGImagePropertyGPSSpeed as String
        static let GPSTrackRef = kCGImagePropertyGPSTrackRef as String
        static let GPSTrack = kCGImagePropertyGPSTrack as String
        static let GPSImgDirectionRef = kCGImagePropertyGPSImgDirectionRef as String
        static let GPSImgDirection = kCGImagePropertyGPSImgDirection as String
        static let GPSMapDatum = kCGImagePropertyGPSMapDatum as String
        static let GPSDestLatitudeRef = kCGImagePropertyGPSDestLatitudeRef as String
        static let GPSDestLatitude = kCGImagePropertyGPSDestLatitude as String
        static let GPSDestLongitudeRef = kCGImagePropertyGPSDestLongitudeRef as String
        static let GPSDestLongitude = kCGImagePropertyGPSDestLongitude as String
        static let GPSDestBearingRef = kCGImagePropertyGPSDestBearingRef as String
        static let GPSDestBearing = kCGImagePropertyGPSDestBearing as String
        static let GPSDestDistanceRef = kCGImagePropertyGPSDestDistanceRef as String
        static let GPSDestDistance = kCGImagePropertyGPSDestDistance as String
        static let GPSProcessingMethod = kCGImagePropertyGPSProcessingMethod as String
        static let GPSAreaInformation = kCGImagePropertyGPSAreaInformation as String
        static let GPSDateStamp = kCGImagePropertyGPSDateStamp as String
        static let GPSDifferental = kCGImagePropertyGPSDifferental as String
        static let GPSHPositioningError = kCGImagePropertyGPSHPositioningError as String

        static let ExifExposureTime = kCGImagePropertyExifExposureTime as String
        static let ExifFNumber = kCGImagePropertyExifFNumber as String
        static let ExifExposureProgram = kCGImagePropertyExifExposureProgram as String
        static let ExifSpectralSensitivity = kCGImagePropertyExifSpectralSensitivity as String
        static let ExifISOSpeedRatings = kCGImagePropertyExifISOSpeedRatings as String
        static let ExifOECF = kCGImagePropertyExifOECF as String
        static let ExifSensitivityType = kCGImagePropertyExifSensitivityType as String
        static let ExifStandardOutputSensitivity = kCGImagePropertyExifStandardOutputSensitivity as String
        static let ExifRecommendedExposureIndex = kCGImagePropertyExifRecommendedExposureIndex as String
        static let ExifISOSpeed = kCGImagePropertyExifISOSpeed as String
        static let ExifISOSpeedLatitudeyyy = kCGImagePropertyExifISOSpeedLatitudeyyy as String
        static let ExifISOSpeedLatitudezzz = kCGImagePropertyExifISOSpeedLatitudezzz as String
        static let ExifVersion = kCGImagePropertyExifVersion as String
        static let ExifDateTimeOriginal = kCGImagePropertyExifDateTimeOriginal as String
        static let ExifDateTimeDigitized = kCGImagePropertyExifDateTimeDigitized as String
        static let ExifComponentsConfiguration = kCGImagePropertyExifComponentsConfiguration as String
        static let ExifCompressedBitsPerPixel = kCGImagePropertyExifCompressedBitsPerPixel as String
        static let ExifShutterSpeedValue = kCGImagePropertyExifShutterSpeedValue as String
        static let ExifApertureValue = kCGImagePropertyExifApertureValue as String
        static let ExifBrightnessValue = kCGImagePropertyExifBrightnessValue as String
        static let ExifExposureBiasValue = kCGImagePropertyExifExposureBiasValue as String
        static let ExifMaxApertureValue = kCGImagePropertyExifMaxApertureValue as String
        static let ExifSubjectDistance = kCGImagePropertyExifSubjectDistance as String
        static let ExifMeteringMode = kCGImagePropertyExifMeteringMode as String
        static let ExifLightSource = kCGImagePropertyExifLightSource as String
        static let ExifFlash = kCGImagePropertyExifFlash as String
        static let ExifFocalLength = kCGImagePropertyExifFocalLength as String
        static let ExifSubjectArea = kCGImagePropertyExifSubjectArea as String
        static let ExifMakerNote = kCGImagePropertyExifMakerNote as String
        static let ExifUserComment = kCGImagePropertyExifUserComment as String
        static let ExifSubsecTime = kCGImagePropertyExifSubsecTime as String
        static let ExifSubsecTimeOriginal = kCGImagePropertyExifSubsecTimeOriginal as String
        static let ExifSubsecTimeDigitized = kCGImagePropertyExifSubsecTimeDigitized as String
        static let ExifFlashPixVersion = kCGImagePropertyExifFlashPixVersion as String
        static let ExifColorSpace = kCGImagePropertyExifColorSpace as String
        static let ExifPixelXDimension = kCGImagePropertyExifPixelXDimension as String
        static let ExifPixelYDimension = kCGImagePropertyExifPixelYDimension as String
        static let ExifRelatedSoundFile = kCGImagePropertyExifRelatedSoundFile as String
        static let ExifFlashEnergy = kCGImagePropertyExifFlashEnergy as String
        static let ExifSpatialFrequencyResponse = kCGImagePropertyExifSpatialFrequencyResponse as String
        static let ExifFocalPlaneXResolution = kCGImagePropertyExifFocalPlaneXResolution as String
        static let ExifFocalPlaneYResolution = kCGImagePropertyExifFocalPlaneYResolution as String
        static let ExifFocalPlaneResolutionUnit = kCGImagePropertyExifFocalPlaneResolutionUnit as String
        static let ExifSubjectLocation = kCGImagePropertyExifSubjectLocation as String
        static let ExifExposureIndex = kCGImagePropertyExifExposureIndex as String
        static let ExifSensingMethod = kCGImagePropertyExifSensingMethod as String
        static let ExifFileSource = kCGImagePropertyExifFileSource as String
        static let ExifSceneType = kCGImagePropertyExifSceneType as String
        static let ExifCFAPattern = kCGImagePropertyExifCFAPattern as String
        static let ExifCustomRendered = kCGImagePropertyExifCustomRendered as String
        static let ExifExposureMode = kCGImagePropertyExifExposureMode as String
        static let ExifWhiteBalance = kCGImagePropertyExifWhiteBalance as String
        static let ExifDigitalZoomRatio = kCGImagePropertyExifDigitalZoomRatio as String
        static let ExifFocalLenIn35mmFilm = kCGImagePropertyExifFocalLenIn35mmFilm as String
        static let ExifSceneCaptureType = kCGImagePropertyExifSceneCaptureType as String
        static let ExifGainControl = kCGImagePropertyExifGainControl as String
        static let ExifContrast = kCGImagePropertyExifContrast as String
        static let ExifSaturation = kCGImagePropertyExifSaturation as String
        static let ExifSharpness = kCGImagePropertyExifSharpness as String
        static let ExifDeviceSettingDescription = kCGImagePropertyExifDeviceSettingDescription as String
        static let ExifSubjectDistRange = kCGImagePropertyExifSubjectDistRange as String
        static let ExifImageUniqueID = kCGImagePropertyExifImageUniqueID as String
        static let ExifCameraOwnerName = kCGImagePropertyExifCameraOwnerName as String
        static let ExifBodySerialNumber = kCGImagePropertyExifBodySerialNumber as String
        static let ExifLensSpecification = kCGImagePropertyExifLensSpecification as String
        static let ExifLensMake = kCGImagePropertyExifLensMake as String
        static let ExifLensModel = kCGImagePropertyExifLensModel as String
        static let ExifLensSerialNumber = kCGImagePropertyExifLensSerialNumber as String
        static let ExifGamma = kCGImagePropertyExifGamma as String

        static let TIFFCompression = kCGImagePropertyTIFFCompression as String
        static let TIFFPhotometricInterpretation = kCGImagePropertyTIFFPhotometricInterpretation as String
        static let TIFFDocumentName = kCGImagePropertyTIFFDocumentName as String
        static let TIFFImageDescription = kCGImagePropertyTIFFImageDescription as String
        static let TIFFMake = kCGImagePropertyTIFFMake as String
        static let TIFFModel = kCGImagePropertyTIFFModel as String
        static let TIFFOrientation = kCGImagePropertyTIFFOrientation as String
        static let TIFFXResolution = kCGImagePropertyTIFFXResolution as String
        static let TIFFYResolution = kCGImagePropertyTIFFYResolution as String
        static let TIFFResolutionUnit = kCGImagePropertyTIFFResolutionUnit as String
        static let TIFFSoftware = kCGImagePropertyTIFFSoftware as String
        static let TIFFTransferFunction = kCGImagePropertyTIFFTransferFunction as String
        static let TIFFDateTime = kCGImagePropertyTIFFDateTime as String
        static let TIFFArtist = kCGImagePropertyTIFFArtist as String
        static let TIFFHostComputer = kCGImagePropertyTIFFHostComputer as String
        static let TIFFCopyright = kCGImagePropertyTIFFCopyright as String
        static let TIFFWhitePoint = kCGImagePropertyTIFFWhitePoint as String
        static let TIFFPrimaryChromaticities = kCGImagePropertyTIFFPrimaryChromaticities as String
        static let TIFFTileWidth = kCGImagePropertyTIFFTileWidth as String
        static let TIFFTileLength = kCGImagePropertyTIFFTileLength as String

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
        static let GPS:[String] = [GPSVersion,
                                   GPSLatitudeRef,
                                   GPSLatitude,
                                   GPSLongitudeRef,
                                   GPSLongitude,
                                   GPSAltitudeRef,
                                   GPSAltitude,
                                   GPSTimeStamp,
                                   GPSSatellites,
                                   GPSStatus,
                                   GPSMeasureMode,
                                   GPSDOP,
                                   GPSSpeedRef,
                                   GPSSpeed,
                                   GPSTrackRef,
                                   GPSTrack,
                                   GPSImgDirectionRef,
                                   GPSImgDirection,
                                   GPSMapDatum,
                                   GPSDestLatitudeRef,
                                   GPSDestLatitude,
                                   GPSDestLongitudeRef,
                                   GPSDestLongitude,
                                   GPSDestBearingRef,
                                   GPSDestBearing,
                                   GPSDestDistanceRef,
                                   GPSDestDistance,
                                   GPSProcessingMethod,
                                   GPSAreaInformation,
                                   GPSDateStamp,
                                   GPSDifferental,
                                   GPSHPositioningError]


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

        static let EXIF:[String] = [ExifExposureTime,
                                    ExifFNumber,
                                    ExifExposureProgram,
                                    ExifSpectralSensitivity,
                                    ExifISOSpeedRatings,
                                    ExifOECF,
                                    ExifSensitivityType,
                                    ExifStandardOutputSensitivity,
                                    ExifRecommendedExposureIndex,
                                    ExifISOSpeed,
                                    ExifISOSpeedLatitudeyyy,
                                    ExifISOSpeedLatitudezzz,
                                    ExifVersion,
                                    ExifDateTimeOriginal,
                                    ExifDateTimeDigitized,
                                    ExifComponentsConfiguration,
                                    ExifCompressedBitsPerPixel,
                                    ExifShutterSpeedValue,
                                    ExifApertureValue,
                                    ExifBrightnessValue,
                                    ExifExposureBiasValue,
                                    ExifMaxApertureValue,
                                    ExifSubjectDistance,
                                    ExifMeteringMode,
                                    ExifLightSource,
                                    ExifFlash,
                                    ExifFocalLength,
                                    ExifSubjectArea,
                                    ExifMakerNote,
                                    ExifUserComment,
                                    ExifSubsecTime,
                                    ExifSubsecTimeOriginal,
                                    ExifSubsecTimeDigitized,
                                    ExifFlashPixVersion,
                                    ExifColorSpace,
                                    ExifPixelXDimension,
                                    ExifPixelYDimension,
                                    ExifRelatedSoundFile,
                                    ExifFlashEnergy,
                                    ExifSpatialFrequencyResponse,
                                    ExifFocalPlaneXResolution,
                                    ExifFocalPlaneYResolution,
                                    ExifFocalPlaneResolutionUnit,
                                    ExifSubjectLocation,
                                    ExifExposureIndex,
                                    ExifSensingMethod,
                                    ExifFileSource,
                                    ExifSceneType,
                                    ExifCFAPattern,
                                    ExifCustomRendered,
                                    ExifExposureMode,
                                    ExifWhiteBalance,
                                    ExifDigitalZoomRatio,
                                    ExifFocalLenIn35mmFilm,
                                    ExifSceneCaptureType,
                                    ExifGainControl,
                                    ExifContrast,
                                    ExifSaturation,
                                    ExifSharpness,
                                    ExifDeviceSettingDescription,
                                    ExifSubjectDistRange,
                                    ExifImageUniqueID,
                                    ExifCameraOwnerName,
                                    ExifBodySerialNumber,
                                    ExifLensSpecification,
                                    ExifLensMake,
                                    ExifLensModel,
                                    ExifLensSerialNumber,
                                    ExifGamma]

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
            TIFFCompression
            ,TIFFPhotometricInterpretation
            ,TIFFDocumentName
            ,TIFFImageDescription
            ,TIFFMake
            ,TIFFModel
            ,TIFFOrientation
            ,TIFFXResolution
            ,TIFFYResolution
            ,TIFFResolutionUnit
            ,TIFFSoftware
            ,TIFFTransferFunction
            ,TIFFDateTime
            ,TIFFArtist
            ,TIFFHostComputer
            ,TIFFCopyright
            ,TIFFWhitePoint
            ,TIFFPrimaryChromaticities
            ,TIFFTileWidth
            ,TIFFTileLength
        ]
    }


}


