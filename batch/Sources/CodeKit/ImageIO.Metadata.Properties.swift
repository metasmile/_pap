//
// Created by BLACKGENE on 16/04/2018.
// Copyright c 2018 Stells. All rights reserved.
//

import Foundation
import ImageIO

public struct ImageMetadataProperties{
    public struct Described{
        static let GPS:[String:String] = [
            kCGImagePropertyGPSLatitudeRef as String : "",
            kCGImagePropertyGPSLatitude as String : "",

            kCGImagePropertyGPSLongitudeRef as String : "",
            kCGImagePropertyGPSLongitude as String : "",

            kCGImagePropertyGPSAltitudeRef as String : "",
            kCGImagePropertyGPSAltitude as String : "",

            kCGImagePropertyGPSTimeStamp as String : "",

            kCGImagePropertyGPSSpeedRef as String : "",
            kCGImagePropertyGPSSpeed as String : "",

            kCGImagePropertyGPSImgDirectionRef as String: "",
            kCGImagePropertyGPSImgDirection as String: "",

            kCGImagePropertyGPSDestBearingRef as String : "",
            kCGImagePropertyGPSDestBearing as String : "",

            kCGImagePropertyGPSDateStamp as String : "",
            kCGImagePropertyGPSDifferental as String : "",
            kCGImagePropertyGPSHPositioningError as String : ""
        ]

        static let EXIF:[String:String] = [
            kCGImagePropertyGPSLatitudeRef as String : "",
            kCGImagePropertyGPSLatitude as String : "",

            kCGImagePropertyGPSLongitudeRef as String : "",
            kCGImagePropertyGPSLongitude as String : "",

            kCGImagePropertyGPSAltitudeRef as String : "",
            kCGImagePropertyGPSAltitude as String : "",

            kCGImagePropertyGPSTimeStamp as String : "",

            kCGImagePropertyGPSSpeedRef as String : "",
            kCGImagePropertyGPSSpeed as String : "",

            kCGImagePropertyGPSImgDirectionRef as String: "",
            kCGImagePropertyGPSImgDirection as String: "",

            kCGImagePropertyGPSDestBearingRef as String : "",
            kCGImagePropertyGPSDestBearing as String : "",

            kCGImagePropertyGPSDateStamp as String : "",
            kCGImagePropertyGPSDifferental as String : "",
            kCGImagePropertyGPSHPositioningError as String : ""
        ]
    }

    public struct Raw{

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
    }


}


