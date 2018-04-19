//
// Created by BLACKGENE on 16/04/2018.
// Copyright c 2018 Stells. All rights reserved.
//

// (kCGImageProperty)(.+)\sas\sString -> static let $2 = $1$2 as String
// .*(kCGImageProperty)(.+)(Dictionary):\sCFString -> static let $2 = $1$2$3 as String

// .*(kCGImage)(.+):\sCFString -> static let $2 = $1$2 as String

import Foundation
import ImageIO

public typealias ImageMetadataPropertyCollection = [String: [String]]
public typealias ImageMetadataValueCollection = [String: [String: Any]]

public struct ImageMetadata {
    static var FileSize:String { return kCGImagePropertyFileSize as String }

/* The number of pixels in the x- and y-dimensions. The value of these keys
 * is a CFNumberRef. */

/** Properties which may be returned by "CGImageSourceCopyPropertiesAtIndex".
 ** The values apply to a single image of an image source file. **/
    static var PixelHeight:String { return kCGImagePropertyPixelHeight as String }
    static var PixelWidth:String { return kCGImagePropertyPixelWidth as String }

/* The DPI in the x- and y-dimensions, if known. If present, the value of
 * these keys is a CFNumberRef. */

    static var DPIHeight:String { return kCGImagePropertyDPIHeight as String }
    static var DPIWidth:String { return kCGImagePropertyDPIWidth as String }

/* The number of bits in each color sample of each pixel. The value of this
 * key is a CFNumberRef. */

    static var Depth:String { return kCGImagePropertyDepth as String }

/* The intended display orientation of the image. If present, the value
 * of this key is a CFNumberRef with the same value as defined by the
 * TIFF and Exif specifications.  That is:
 *   1  =  0th row is at the top, and 0th column is on the left.
 *   2  =  0th row is at the top, and 0th column is on the right.
 *   3  =  0th row is at the bottom, and 0th column is on the right.
 *   4  =  0th row is at the bottom, and 0th column is on the left.
 *   5  =  0th row is on the left, and 0th column is the top.
 *   6  =  0th row is on the right, and 0th column is the top.
 *   7  =  0th row is on the right, and 0th column is the bottom.
 *   8  =  0th row is on the left, and 0th column is the bottom.
 * If not present, a value of 1 is assumed. */

    static var Orientation:String { return kCGImagePropertyOrientation as String }

/* The value of this key is kCFBooleanTrue if the image contains floating-
 * point pixel samples */

    static var IsFloat:String { return kCGImagePropertyIsFloat as String }

/* The value of this key is kCFBooleanTrue if the image contains indexed
 * (a.k.a. paletted) pixel samples */

    static var IsIndexed:String { return kCGImagePropertyIsIndexed as String }

/* The value of this key is kCFBooleanTrue if the image contains an alpha
 * (a.k.a. coverage) channel */

    static var HasAlpha:String { return kCGImagePropertyHasAlpha as String }

/* The color model of the image such as "RGB", "CMYK", "Gray", or "Lab".
 * The value of this key is CFStringRef. */

    static var ColorModel:String { return kCGImagePropertyColorModel as String }

/* The name of the optional ICC profile embedded in the image, if known.
 * If present, the value of this key is a CFStringRef. */

    static var ProfileName:String { return kCGImagePropertyProfileName as String }

/* Possible values for kCGImagePropertyColorModel property */

    static var ColorModelRGB:String { return kCGImagePropertyColorModelRGB as String }
    static var ColorModelGray:String { return kCGImagePropertyColorModelGray as String }
    static var ColorModelCMYK:String { return kCGImagePropertyColorModelCMYK as String }
    static var ColorModelLab:String { return kCGImagePropertyColorModelLab as String }

    public struct Dictionary {
        static var TIFF:String { return kCGImagePropertyTIFFDictionary as String }
        static var GIF:String { return kCGImagePropertyGIFDictionary as String }
        static var JFIF:String { return kCGImagePropertyJFIFDictionary as String }
        static var Exif:String { return kCGImagePropertyExifDictionary as String }
        static var PNG:String { return kCGImagePropertyPNGDictionary as String }
        static var IPTC:String { return kCGImagePropertyIPTCDictionary as String }
        static var GPS:String { return kCGImagePropertyGPSDictionary as String }
        static var Raw:String { return kCGImagePropertyRawDictionary as String }
        static var CIFF:String { return kCGImagePropertyCIFFDictionary as String }
        static var MakerCanon:String { return kCGImagePropertyMakerCanonDictionary as String }
        static var MakerNikon:String { return kCGImagePropertyMakerNikonDictionary as String }
        static var MakerMinolta:String { return kCGImagePropertyMakerMinoltaDictionary as String }
        static var MakerFuji:String { return kCGImagePropertyMakerFujiDictionary as String }
        static var MakerOlympus:String { return kCGImagePropertyMakerOlympusDictionary as String }
        static var MakerPentax:String { return kCGImagePropertyMakerPentaxDictionary as String }
        static var _8BIM:String { return kCGImageProperty8BIMDictionary as String }
        static var DNG:String { return kCGImagePropertyDNGDictionary as String }
        static var ExifAux:String { return kCGImagePropertyExifAuxDictionary as String }
        @available(iOS 11.3, *)
        static var OpenEXR:String { return kCGImagePropertyOpenEXRDictionary as String }
        @available(iOS 7.0, *)
        static var MakerApple:String { return kCGImagePropertyMakerAppleDictionary as String }
        @available(iOS 11.0, *)
        static var FileContents:String { return kCGImagePropertyFileContentsDictionary as String }
    }

    public struct Property {
        static var TIFFCompression:String { return kCGImagePropertyTIFFCompression as String }
        static var TIFFPhotometricInterpretation:String { return kCGImagePropertyTIFFPhotometricInterpretation as String }
        static var TIFFDocumentName:String { return kCGImagePropertyTIFFDocumentName as String }
        static var TIFFImageDescription:String { return kCGImagePropertyTIFFImageDescription as String }
        static var TIFFMake:String { return kCGImagePropertyTIFFMake as String }
        static var TIFFModel:String { return kCGImagePropertyTIFFModel as String }
        static var TIFFOrientation:String { return kCGImagePropertyTIFFOrientation as String }
        static var TIFFXResolution:String { return kCGImagePropertyTIFFXResolution as String }
        static var TIFFYResolution:String { return kCGImagePropertyTIFFYResolution as String }
        static var TIFFResolutionUnit:String { return kCGImagePropertyTIFFResolutionUnit as String }
        static var TIFFSoftware:String { return kCGImagePropertyTIFFSoftware as String }
        static var TIFFTransferFunction:String { return kCGImagePropertyTIFFTransferFunction as String }
        static var TIFFDateTime:String { return kCGImagePropertyTIFFDateTime as String }
        static var TIFFArtist:String { return kCGImagePropertyTIFFArtist as String }
        static var TIFFHostComputer:String { return kCGImagePropertyTIFFHostComputer as String }
        static var TIFFCopyright:String { return kCGImagePropertyTIFFCopyright as String }
        static var TIFFWhitePoint:String { return kCGImagePropertyTIFFWhitePoint as String }
        static var TIFFPrimaryChromaticities:String { return kCGImagePropertyTIFFPrimaryChromaticities as String }
        @available(iOS 9.0, *)
        static var TIFFTileWidth:String { return kCGImagePropertyTIFFTileWidth as String }
        @available(iOS 9.0, *)
        static var TIFFTileLength:String { return kCGImagePropertyTIFFTileLength as String }

/* Possible keys for kCGImagePropertyJFIFDictionary */

        static var JFIFVersion:String { return kCGImagePropertyJFIFVersion as String }
        static var JFIFXDensity:String { return kCGImagePropertyJFIFXDensity as String }
        static var JFIFYDensity:String { return kCGImagePropertyJFIFYDensity as String }
        static var JFIFDensityUnit:String { return kCGImagePropertyJFIFDensityUnit as String }
        static var JFIFIsProgressive:String { return kCGImagePropertyJFIFIsProgressive as String }

/* Possible keys for kCGImagePropertyExifDictionary */

        static var ExifExposureTime:String { return kCGImagePropertyExifExposureTime as String }
        static var ExifFNumber:String { return kCGImagePropertyExifFNumber as String }
        static var ExifExposureProgram:String { return kCGImagePropertyExifExposureProgram as String }
        static var ExifSpectralSensitivity:String { return kCGImagePropertyExifSpectralSensitivity as String }
        static var ExifISOSpeedRatings:String { return kCGImagePropertyExifISOSpeedRatings as String }
        static var ExifOECF:String { return kCGImagePropertyExifOECF as String }
        @available(iOS 7.0, *)
        static var ExifSensitivityType:String { return kCGImagePropertyExifSensitivityType as String }
        @available(iOS 7.0, *)
        static var ExifStandardOutputSensitivity:String { return kCGImagePropertyExifStandardOutputSensitivity as String }
        @available(iOS 7.0, *)
        static var ExifRecommendedExposureIndex:String { return kCGImagePropertyExifRecommendedExposureIndex as String }
        @available(iOS 7.0, *)
        static var ExifISOSpeed:String { return kCGImagePropertyExifISOSpeed as String }
        @available(iOS 7.0, *)
        static var ExifISOSpeedLatitudeyyy:String { return kCGImagePropertyExifISOSpeedLatitudeyyy as String }
        @available(iOS 7.0, *)
        static var ExifISOSpeedLatitudezzz:String { return kCGImagePropertyExifISOSpeedLatitudezzz as String }
        static var ExifVersion:String { return kCGImagePropertyExifVersion as String }
        static var ExifDateTimeOriginal:String { return kCGImagePropertyExifDateTimeOriginal as String }
        static var ExifDateTimeDigitized:String { return kCGImagePropertyExifDateTimeDigitized as String }
        static var ExifComponentsConfiguration:String { return kCGImagePropertyExifComponentsConfiguration as String }
        static var ExifCompressedBitsPerPixel:String { return kCGImagePropertyExifCompressedBitsPerPixel as String }
        static var ExifShutterSpeedValue:String { return kCGImagePropertyExifShutterSpeedValue as String }
        static var ExifApertureValue:String { return kCGImagePropertyExifApertureValue as String }
        static var ExifBrightnessValue:String { return kCGImagePropertyExifBrightnessValue as String }
        static var ExifExposureBiasValue:String { return kCGImagePropertyExifExposureBiasValue as String }
        static var ExifMaxApertureValue:String { return kCGImagePropertyExifMaxApertureValue as String }
        static var ExifSubjectDistance:String { return kCGImagePropertyExifSubjectDistance as String }
        static var ExifMeteringMode:String { return kCGImagePropertyExifMeteringMode as String }
        static var ExifLightSource:String { return kCGImagePropertyExifLightSource as String }
        static var ExifFlash:String { return kCGImagePropertyExifFlash as String }
        static var ExifFocalLength:String { return kCGImagePropertyExifFocalLength as String }
        static var ExifSubjectArea:String { return kCGImagePropertyExifSubjectArea as String }
        static var ExifMakerNote:String { return kCGImagePropertyExifMakerNote as String }
        static var ExifUserComment:String { return kCGImagePropertyExifUserComment as String }
        static var ExifSubsecTime:String { return kCGImagePropertyExifSubsecTime as String }
        @available(iOS 10.0, *)
        static var ExifSubsecTimeOriginal:String { return kCGImagePropertyExifSubsecTimeOriginal as String }
        static var ExifSubsecTimeDigitized:String { return kCGImagePropertyExifSubsecTimeDigitized as String }
        static var ExifFlashPixVersion:String { return kCGImagePropertyExifFlashPixVersion as String }
        static var ExifColorSpace:String { return kCGImagePropertyExifColorSpace as String }
        static var ExifPixelXDimension:String { return kCGImagePropertyExifPixelXDimension as String }
        static var ExifPixelYDimension:String { return kCGImagePropertyExifPixelYDimension as String }
        static var ExifRelatedSoundFile:String { return kCGImagePropertyExifRelatedSoundFile as String }
        static var ExifFlashEnergy:String { return kCGImagePropertyExifFlashEnergy as String }
        static var ExifSpatialFrequencyResponse:String { return kCGImagePropertyExifSpatialFrequencyResponse as String }
        static var ExifFocalPlaneXResolution:String { return kCGImagePropertyExifFocalPlaneXResolution as String }
        static var ExifFocalPlaneYResolution:String { return kCGImagePropertyExifFocalPlaneYResolution as String }
        static var ExifFocalPlaneResolutionUnit:String { return kCGImagePropertyExifFocalPlaneResolutionUnit as String }
        static var ExifSubjectLocation:String { return kCGImagePropertyExifSubjectLocation as String }
        static var ExifExposureIndex:String { return kCGImagePropertyExifExposureIndex as String }
        static var ExifSensingMethod:String { return kCGImagePropertyExifSensingMethod as String }
        static var ExifFileSource:String { return kCGImagePropertyExifFileSource as String }
        static var ExifSceneType:String { return kCGImagePropertyExifSceneType as String }
        static var ExifCFAPattern:String { return kCGImagePropertyExifCFAPattern as String }
        static var ExifCustomRendered:String { return kCGImagePropertyExifCustomRendered as String }
        static var ExifExposureMode:String { return kCGImagePropertyExifExposureMode as String }
        static var ExifWhiteBalance:String { return kCGImagePropertyExifWhiteBalance as String }
        static var ExifDigitalZoomRatio:String { return kCGImagePropertyExifDigitalZoomRatio as String }
        static var ExifFocalLenIn35mmFilm:String { return kCGImagePropertyExifFocalLenIn35mmFilm as String }
        static var ExifSceneCaptureType:String { return kCGImagePropertyExifSceneCaptureType as String }
        static var ExifGainControl:String { return kCGImagePropertyExifGainControl as String }
        static var ExifContrast:String { return kCGImagePropertyExifContrast as String }
        static var ExifSaturation:String { return kCGImagePropertyExifSaturation as String }
        static var ExifSharpness:String { return kCGImagePropertyExifSharpness as String }
        static var ExifDeviceSettingDescription:String { return kCGImagePropertyExifDeviceSettingDescription as String }
        static var ExifSubjectDistRange:String { return kCGImagePropertyExifSubjectDistRange as String }
        static var ExifImageUniqueID:String { return kCGImagePropertyExifImageUniqueID as String }
        @available(iOS 5.0, *)
        static var ExifCameraOwnerName:String { return kCGImagePropertyExifCameraOwnerName as String }
        @available(iOS 5.0, *)
        static var ExifBodySerialNumber:String { return kCGImagePropertyExifBodySerialNumber as String }
        @available(iOS 5.0, *)
        static var ExifLensSpecification:String { return kCGImagePropertyExifLensSpecification as String }
        @available(iOS 5.0, *)
        static var ExifLensMake:String { return kCGImagePropertyExifLensMake as String }
        @available(iOS 5.0, *)
        static var ExifLensModel:String { return kCGImagePropertyExifLensModel as String }
        @available(iOS 5.0, *)
        static var ExifLensSerialNumber:String { return kCGImagePropertyExifLensSerialNumber as String }
        static var ExifGamma:String { return kCGImagePropertyExifGamma as String }

/* deprecated */
        static var ExifSubsecTimeOrginal:String { return kCGImagePropertyExifSubsecTimeOrginal as String }

/* Possible keys for kCGImagePropertyExifAuxDictionary */
        static var ExifAuxLensInfo:String { return kCGImagePropertyExifAuxLensInfo as String }
        static var ExifAuxLensModel:String { return kCGImagePropertyExifAuxLensModel as String }
        static var ExifAuxSerialNumber:String { return kCGImagePropertyExifAuxSerialNumber as String }
        static var ExifAuxLensID:String { return kCGImagePropertyExifAuxLensID as String }
        static var ExifAuxLensSerialNumber:String { return kCGImagePropertyExifAuxLensSerialNumber as String }
        static var ExifAuxImageNumber:String { return kCGImagePropertyExifAuxImageNumber as String }
        static var ExifAuxFlashCompensation:String { return kCGImagePropertyExifAuxFlashCompensation as String }
        static var ExifAuxOwnerName:String { return kCGImagePropertyExifAuxOwnerName as String }
        static var ExifAuxFirmware:String { return kCGImagePropertyExifAuxFirmware as String }

/* Possible keys for kCGImagePropertyGIFDictionary */

        static var GIFLoopCount:String { return kCGImagePropertyGIFLoopCount as String }
        static var GIFDelayTime:String { return kCGImagePropertyGIFDelayTime as String }
        static var GIFImageColorMap:String { return kCGImagePropertyGIFImageColorMap as String }
        static var GIFHasGlobalColorMap:String { return kCGImagePropertyGIFHasGlobalColorMap as String }
        static var GIFUnclampedDelayTime:String { return kCGImagePropertyGIFUnclampedDelayTime as String }

/* Possible keys for kCGImagePropertyPNGDictionary */

        static var PNGGamma:String { return kCGImagePropertyPNGGamma as String }
        static var PNGInterlaceType:String { return kCGImagePropertyPNGInterlaceType as String }
        static var PNGXPixelsPerMeter:String { return kCGImagePropertyPNGXPixelsPerMeter as String }
        static var PNGYPixelsPerMeter:String { return kCGImagePropertyPNGYPixelsPerMeter as String }
        static var PNGsRGBIntent:String { return kCGImagePropertyPNGsRGBIntent as String }
        static var PNGChromaticities:String { return kCGImagePropertyPNGChromaticities as String }

        @available(iOS 5.0, *)
        static var PNGAuthor:String { return kCGImagePropertyPNGAuthor as String }
        @available(iOS 5.0, *)
        static var PNGCopyright:String { return kCGImagePropertyPNGCopyright as String }
        @available(iOS 5.0, *)
        static var PNGCreationTime:String { return kCGImagePropertyPNGCreationTime as String }
        @available(iOS 5.0, *)
        static var PNGDescription:String { return kCGImagePropertyPNGDescription as String }
        @available(iOS 5.0, *)
        static var PNGModificationTime:String { return kCGImagePropertyPNGModificationTime as String }
        @available(iOS 5.0, *)
        static var PNGSoftware:String { return kCGImagePropertyPNGSoftware as String }
        @available(iOS 5.0, *)
        static var PNGTitle:String { return kCGImagePropertyPNGTitle as String }

        @available(iOS 8.0, *)
        static var APNGLoopCount:String { return kCGImagePropertyAPNGLoopCount as String }
        @available(iOS 8.0, *)
        static var APNGDelayTime:String { return kCGImagePropertyAPNGDelayTime as String }
        @available(iOS 8.0, *)
        static var APNGUnclampedDelayTime:String { return kCGImagePropertyAPNGUnclampedDelayTime as String }

/* Possible keys for kCGImagePropertyGPSDictionary */

        static var GPSVersion:String { return kCGImagePropertyGPSVersion as String }
        static var GPSLatitudeRef:String { return kCGImagePropertyGPSLatitudeRef as String }
        static var GPSLatitude:String { return kCGImagePropertyGPSLatitude as String }
        static var GPSLongitudeRef:String { return kCGImagePropertyGPSLongitudeRef as String }
        static var GPSLongitude:String { return kCGImagePropertyGPSLongitude as String }
        static var GPSAltitudeRef:String { return kCGImagePropertyGPSAltitudeRef as String }
        static var GPSAltitude:String { return kCGImagePropertyGPSAltitude as String }
        static var GPSTimeStamp:String { return kCGImagePropertyGPSTimeStamp as String }
        static var GPSSatellites:String { return kCGImagePropertyGPSSatellites as String }
        static var GPSStatus:String { return kCGImagePropertyGPSStatus as String }
        static var GPSMeasureMode:String { return kCGImagePropertyGPSMeasureMode as String }
        static var GPSDOP:String { return kCGImagePropertyGPSDOP as String }
        static var GPSSpeedRef:String { return kCGImagePropertyGPSSpeedRef as String }
        static var GPSSpeed:String { return kCGImagePropertyGPSSpeed as String }
        static var GPSTrackRef:String { return kCGImagePropertyGPSTrackRef as String }
        static var GPSTrack:String { return kCGImagePropertyGPSTrack as String }
        static var GPSImgDirectionRef:String { return kCGImagePropertyGPSImgDirectionRef as String }
        static var GPSImgDirection:String { return kCGImagePropertyGPSImgDirection as String }
        static var GPSMapDatum:String { return kCGImagePropertyGPSMapDatum as String }
        static var GPSDestLatitudeRef:String { return kCGImagePropertyGPSDestLatitudeRef as String }
        static var GPSDestLatitude:String { return kCGImagePropertyGPSDestLatitude as String }
        static var GPSDestLongitudeRef:String { return kCGImagePropertyGPSDestLongitudeRef as String }
        static var GPSDestLongitude:String { return kCGImagePropertyGPSDestLongitude as String }
        static var GPSDestBearingRef:String { return kCGImagePropertyGPSDestBearingRef as String }
        static var GPSDestBearing:String { return kCGImagePropertyGPSDestBearing as String }
        static var GPSDestDistanceRef:String { return kCGImagePropertyGPSDestDistanceRef as String }
        static var GPSDestDistance:String { return kCGImagePropertyGPSDestDistance as String }
        static var GPSProcessingMethod:String { return kCGImagePropertyGPSProcessingMethod as String }
        static var GPSAreaInformation:String { return kCGImagePropertyGPSAreaInformation as String }
        static var GPSDateStamp:String { return kCGImagePropertyGPSDateStamp as String }
        static var GPSDifferental:String { return kCGImagePropertyGPSDifferental as String }
        @available(iOS 8.0, *)
        static var GPSHPositioningError:String { return kCGImagePropertyGPSHPositioningError as String }

/* Possible keys for kCGImagePropertyIPTCDictionary */

        static var IPTCObjectTypeReference:String { return kCGImagePropertyIPTCObjectTypeReference as String }
        static var IPTCObjectAttributeReference:String { return kCGImagePropertyIPTCObjectAttributeReference as String }
        static var IPTCObjectName:String { return kCGImagePropertyIPTCObjectName as String }
        static var IPTCEditStatus:String { return kCGImagePropertyIPTCEditStatus as String }
        static var IPTCEditorialUpdate:String { return kCGImagePropertyIPTCEditorialUpdate as String }
        static var IPTCUrgency:String { return kCGImagePropertyIPTCUrgency as String }
        static var IPTCSubjectReference:String { return kCGImagePropertyIPTCSubjectReference as String }
        static var IPTCCategory:String { return kCGImagePropertyIPTCCategory as String }
        static var IPTCSupplementalCategory:String { return kCGImagePropertyIPTCSupplementalCategory as String }
        static var IPTCFixtureIdentifier:String { return kCGImagePropertyIPTCFixtureIdentifier as String }
        static var IPTCKeywords:String { return kCGImagePropertyIPTCKeywords as String }
        static var IPTCContentLocationCode:String { return kCGImagePropertyIPTCContentLocationCode as String }
        static var IPTCContentLocationName:String { return kCGImagePropertyIPTCContentLocationName as String }
        static var IPTCReleaseDate:String { return kCGImagePropertyIPTCReleaseDate as String }
        static var IPTCReleaseTime:String { return kCGImagePropertyIPTCReleaseTime as String }
        static var IPTCExpirationDate:String { return kCGImagePropertyIPTCExpirationDate as String }
        static var IPTCExpirationTime:String { return kCGImagePropertyIPTCExpirationTime as String }
        static var IPTCSpecialInstructions:String { return kCGImagePropertyIPTCSpecialInstructions as String }
        static var IPTCActionAdvised:String { return kCGImagePropertyIPTCActionAdvised as String }
        static var IPTCReferenceService:String { return kCGImagePropertyIPTCReferenceService as String }
        static var IPTCReferenceDate:String { return kCGImagePropertyIPTCReferenceDate as String }
        static var IPTCReferenceNumber:String { return kCGImagePropertyIPTCReferenceNumber as String }
        static var IPTCDateCreated:String { return kCGImagePropertyIPTCDateCreated as String }
        static var IPTCTimeCreated:String { return kCGImagePropertyIPTCTimeCreated as String }
        static var IPTCDigitalCreationDate:String { return kCGImagePropertyIPTCDigitalCreationDate as String }
        static var IPTCDigitalCreationTime:String { return kCGImagePropertyIPTCDigitalCreationTime as String }
        static var IPTCOriginatingProgram:String { return kCGImagePropertyIPTCOriginatingProgram as String }
        static var IPTCProgramVersion:String { return kCGImagePropertyIPTCProgramVersion as String }
        static var IPTCObjectCycle:String { return kCGImagePropertyIPTCObjectCycle as String }
        static var IPTCByline:String { return kCGImagePropertyIPTCByline as String }
        static var IPTCBylineTitle:String { return kCGImagePropertyIPTCBylineTitle as String }
        static var IPTCCity:String { return kCGImagePropertyIPTCCity as String }
        static var IPTCSubLocation:String { return kCGImagePropertyIPTCSubLocation as String }
        static var IPTCProvinceState:String { return kCGImagePropertyIPTCProvinceState as String }
        static var IPTCCountryPrimaryLocationCode:String { return kCGImagePropertyIPTCCountryPrimaryLocationCode as String }
        static var IPTCCountryPrimaryLocationName:String { return kCGImagePropertyIPTCCountryPrimaryLocationName as String }
        static var IPTCOriginalTransmissionReference:String { return kCGImagePropertyIPTCOriginalTransmissionReference as String }
        static var IPTCHeadline:String { return kCGImagePropertyIPTCHeadline as String }
        static var IPTCCredit:String { return kCGImagePropertyIPTCCredit as String }
        static var IPTCSource:String { return kCGImagePropertyIPTCSource as String }
        static var IPTCCopyrightNotice:String { return kCGImagePropertyIPTCCopyrightNotice as String }
        static var IPTCContact:String { return kCGImagePropertyIPTCContact as String }
        static var IPTCCaptionAbstract:String { return kCGImagePropertyIPTCCaptionAbstract as String }
        static var IPTCWriterEditor:String { return kCGImagePropertyIPTCWriterEditor as String }
        static var IPTCImageType:String { return kCGImagePropertyIPTCImageType as String }
        static var IPTCImageOrientation:String { return kCGImagePropertyIPTCImageOrientation as String }
        static var IPTCLanguageIdentifier:String { return kCGImagePropertyIPTCLanguageIdentifier as String }
        static var IPTCStarRating:String { return kCGImagePropertyIPTCStarRating as String }
        static var IPTCCreatorContactInfo:String { return kCGImagePropertyIPTCCreatorContactInfo as String } // IPTC Core
        static var IPTCRightsUsageTerms:String { return kCGImagePropertyIPTCRightsUsageTerms as String } // IPTC Core
        static var IPTCScene:String { return kCGImagePropertyIPTCScene as String } // IPTC Core

        @available(iOS 11.3, *)
        static var IPTCExtAboutCvTerm:String { return kCGImagePropertyIPTCExtAboutCvTerm as String }
        @available(iOS 11.3, *)
        static var IPTCExtAboutCvTermCvId:String { return kCGImagePropertyIPTCExtAboutCvTermCvId as String }
        @available(iOS 11.3, *)
        static var IPTCExtAboutCvTermId:String { return kCGImagePropertyIPTCExtAboutCvTermId as String }
        @available(iOS 11.3, *)
        static var IPTCExtAboutCvTermName:String { return kCGImagePropertyIPTCExtAboutCvTermName as String }
        @available(iOS 11.3, *)
        static var IPTCExtAboutCvTermRefinedAbout:String { return kCGImagePropertyIPTCExtAboutCvTermRefinedAbout as String }
        @available(iOS 11.3, *)
        static var IPTCExtAddlModelInfo:String { return kCGImagePropertyIPTCExtAddlModelInfo as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkOrObject:String { return kCGImagePropertyIPTCExtArtworkOrObject as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkCircaDateCreated:String { return kCGImagePropertyIPTCExtArtworkCircaDateCreated as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkContentDescription:String { return kCGImagePropertyIPTCExtArtworkContentDescription as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkContributionDescription:String { return kCGImagePropertyIPTCExtArtworkContributionDescription as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkCopyrightNotice:String { return kCGImagePropertyIPTCExtArtworkCopyrightNotice as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkCreator:String { return kCGImagePropertyIPTCExtArtworkCreator as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkCreatorID:String { return kCGImagePropertyIPTCExtArtworkCreatorID as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkCopyrightOwnerID:String { return kCGImagePropertyIPTCExtArtworkCopyrightOwnerID as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkCopyrightOwnerName:String { return kCGImagePropertyIPTCExtArtworkCopyrightOwnerName as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkLicensorID:String { return kCGImagePropertyIPTCExtArtworkLicensorID as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkLicensorName:String { return kCGImagePropertyIPTCExtArtworkLicensorName as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkDateCreated:String { return kCGImagePropertyIPTCExtArtworkDateCreated as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkPhysicalDescription:String { return kCGImagePropertyIPTCExtArtworkPhysicalDescription as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkSource:String { return kCGImagePropertyIPTCExtArtworkSource as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkSourceInventoryNo:String { return kCGImagePropertyIPTCExtArtworkSourceInventoryNo as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkSourceInvURL:String { return kCGImagePropertyIPTCExtArtworkSourceInvURL as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkStylePeriod:String { return kCGImagePropertyIPTCExtArtworkStylePeriod as String }
        @available(iOS 11.3, *)
        static var IPTCExtArtworkTitle:String { return kCGImagePropertyIPTCExtArtworkTitle as String }
        @available(iOS 11.3, *)
        static var IPTCExtAudioBitrate:String { return kCGImagePropertyIPTCExtAudioBitrate as String }
        @available(iOS 11.3, *)
        static var IPTCExtAudioBitrateMode:String { return kCGImagePropertyIPTCExtAudioBitrateMode as String }
        @available(iOS 11.3, *)
        static var IPTCExtAudioChannelCount:String { return kCGImagePropertyIPTCExtAudioChannelCount as String }
        @available(iOS 11.3, *)
        static var IPTCExtCircaDateCreated:String { return kCGImagePropertyIPTCExtCircaDateCreated as String }
        @available(iOS 11.3, *)
        static var IPTCExtContainerFormat:String { return kCGImagePropertyIPTCExtContainerFormat as String }
        @available(iOS 11.3, *)
        static var IPTCExtContainerFormatIdentifier:String { return kCGImagePropertyIPTCExtContainerFormatIdentifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtContainerFormatName:String { return kCGImagePropertyIPTCExtContainerFormatName as String }
        @available(iOS 11.3, *)
        static var IPTCExtContributor:String { return kCGImagePropertyIPTCExtContributor as String }
        @available(iOS 11.3, *)
        static var IPTCExtContributorIdentifier:String { return kCGImagePropertyIPTCExtContributorIdentifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtContributorName:String { return kCGImagePropertyIPTCExtContributorName as String }
        @available(iOS 11.3, *)
        static var IPTCExtContributorRole:String { return kCGImagePropertyIPTCExtContributorRole as String }
        @available(iOS 11.3, *)
        static var IPTCExtCopyrightYear:String { return kCGImagePropertyIPTCExtCopyrightYear as String }
        @available(iOS 11.3, *)
        static var IPTCExtCreator:String { return kCGImagePropertyIPTCExtCreator as String }
        @available(iOS 11.3, *)
        static var IPTCExtCreatorIdentifier:String { return kCGImagePropertyIPTCExtCreatorIdentifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtCreatorName:String { return kCGImagePropertyIPTCExtCreatorName as String }
        @available(iOS 11.3, *)
        static var IPTCExtCreatorRole:String { return kCGImagePropertyIPTCExtCreatorRole as String }
        @available(iOS 11.3, *)
        static var IPTCExtControlledVocabularyTerm:String { return kCGImagePropertyIPTCExtControlledVocabularyTerm as String }
        @available(iOS 11.3, *)
        static var IPTCExtDataOnScreen:String { return kCGImagePropertyIPTCExtDataOnScreen as String }
        @available(iOS 11.3, *)
        static var IPTCExtDataOnScreenRegion:String { return kCGImagePropertyIPTCExtDataOnScreenRegion as String }
        @available(iOS 11.3, *)
        static var IPTCExtDataOnScreenRegionD:String { return kCGImagePropertyIPTCExtDataOnScreenRegionD as String }
        @available(iOS 11.3, *)
        static var IPTCExtDataOnScreenRegionH:String { return kCGImagePropertyIPTCExtDataOnScreenRegionH as String }
        @available(iOS 11.3, *)
        static var IPTCExtDataOnScreenRegionText:String { return kCGImagePropertyIPTCExtDataOnScreenRegionText as String }
        @available(iOS 11.3, *)
        static var IPTCExtDataOnScreenRegionUnit:String { return kCGImagePropertyIPTCExtDataOnScreenRegionUnit as String }
        @available(iOS 11.3, *)
        static var IPTCExtDataOnScreenRegionW:String { return kCGImagePropertyIPTCExtDataOnScreenRegionW as String }
        @available(iOS 11.3, *)
        static var IPTCExtDataOnScreenRegionX:String { return kCGImagePropertyIPTCExtDataOnScreenRegionX as String }
        @available(iOS 11.3, *)
        static var IPTCExtDataOnScreenRegionY:String { return kCGImagePropertyIPTCExtDataOnScreenRegionY as String }
        @available(iOS 11.3, *)
        static var IPTCExtDigitalImageGUID:String { return kCGImagePropertyIPTCExtDigitalImageGUID as String }
        @available(iOS 11.3, *)
        static var IPTCExtDigitalSourceFileType:String { return kCGImagePropertyIPTCExtDigitalSourceFileType as String }
        @available(iOS 11.3, *)
        static var IPTCExtDigitalSourceType:String { return kCGImagePropertyIPTCExtDigitalSourceType as String }
        @available(iOS 11.3, *)
        static var IPTCExtDopesheet:String { return kCGImagePropertyIPTCExtDopesheet as String }
        @available(iOS 11.3, *)
        static var IPTCExtDopesheetLink:String { return kCGImagePropertyIPTCExtDopesheetLink as String }
        @available(iOS 11.3, *)
        static var IPTCExtDopesheetLinkLink:String { return kCGImagePropertyIPTCExtDopesheetLinkLink as String }
        @available(iOS 11.3, *)
        static var IPTCExtDopesheetLinkLinkQualifier:String { return kCGImagePropertyIPTCExtDopesheetLinkLinkQualifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtEmbdEncRightsExpr:String { return kCGImagePropertyIPTCExtEmbdEncRightsExpr as String }
        @available(iOS 11.3, *)
        static var IPTCExtEmbeddedEncodedRightsExpr:String { return kCGImagePropertyIPTCExtEmbeddedEncodedRightsExpr as String }
        @available(iOS 11.3, *)
        static var IPTCExtEmbeddedEncodedRightsExprType:String { return kCGImagePropertyIPTCExtEmbeddedEncodedRightsExprType as String }
        @available(iOS 11.3, *)
        static var IPTCExtEmbeddedEncodedRightsExprLangID:String { return kCGImagePropertyIPTCExtEmbeddedEncodedRightsExprLangID as String }
        @available(iOS 11.3, *)
        static var IPTCExtEpisode:String { return kCGImagePropertyIPTCExtEpisode as String }
        @available(iOS 11.3, *)
        static var IPTCExtEpisodeIdentifier:String { return kCGImagePropertyIPTCExtEpisodeIdentifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtEpisodeName:String { return kCGImagePropertyIPTCExtEpisodeName as String }
        @available(iOS 11.3, *)
        static var IPTCExtEpisodeNumber:String { return kCGImagePropertyIPTCExtEpisodeNumber as String }
        @available(iOS 11.3, *)
        static var IPTCExtEvent:String { return kCGImagePropertyIPTCExtEvent as String }
        @available(iOS 11.3, *)
        static var IPTCExtShownEvent:String { return kCGImagePropertyIPTCExtShownEvent as String }
        @available(iOS 11.3, *)
        static var IPTCExtShownEventIdentifier:String { return kCGImagePropertyIPTCExtShownEventIdentifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtShownEventName:String { return kCGImagePropertyIPTCExtShownEventName as String }
        @available(iOS 11.3, *)
        static var IPTCExtExternalMetadataLink:String { return kCGImagePropertyIPTCExtExternalMetadataLink as String }
        @available(iOS 11.3, *)
        static var IPTCExtFeedIdentifier:String { return kCGImagePropertyIPTCExtFeedIdentifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtGenre:String { return kCGImagePropertyIPTCExtGenre as String }
        @available(iOS 11.3, *)
        static var IPTCExtGenreCvId:String { return kCGImagePropertyIPTCExtGenreCvId as String }
        @available(iOS 11.3, *)
        static var IPTCExtGenreCvTermId:String { return kCGImagePropertyIPTCExtGenreCvTermId as String }
        @available(iOS 11.3, *)
        static var IPTCExtGenreCvTermName:String { return kCGImagePropertyIPTCExtGenreCvTermName as String }
        @available(iOS 11.3, *)
        static var IPTCExtGenreCvTermRefinedAbout:String { return kCGImagePropertyIPTCExtGenreCvTermRefinedAbout as String }
        @available(iOS 11.3, *)
        static var IPTCExtHeadline:String { return kCGImagePropertyIPTCExtHeadline as String }
        @available(iOS 11.3, *)
        static var IPTCExtIPTCLastEdited:String { return kCGImagePropertyIPTCExtIPTCLastEdited as String }
        @available(iOS 11.3, *)
        static var IPTCExtLinkedEncRightsExpr:String { return kCGImagePropertyIPTCExtLinkedEncRightsExpr as String }
        @available(iOS 11.3, *)
        static var IPTCExtLinkedEncodedRightsExpr:String { return kCGImagePropertyIPTCExtLinkedEncodedRightsExpr as String }
        @available(iOS 11.3, *)
        static var IPTCExtLinkedEncodedRightsExprType:String { return kCGImagePropertyIPTCExtLinkedEncodedRightsExprType as String }
        @available(iOS 11.3, *)
        static var IPTCExtLinkedEncodedRightsExprLangID:String { return kCGImagePropertyIPTCExtLinkedEncodedRightsExprLangID as String }
        @available(iOS 11.3, *)
        static var IPTCExtLocationCreated:String { return kCGImagePropertyIPTCExtLocationCreated as String }
        @available(iOS 11.3, *)
        static var IPTCExtLocationCity:String { return kCGImagePropertyIPTCExtLocationCity as String }
        @available(iOS 11.3, *)
        static var IPTCExtLocationCountryCode:String { return kCGImagePropertyIPTCExtLocationCountryCode as String }
        @available(iOS 11.3, *)
        static var IPTCExtLocationCountryName:String { return kCGImagePropertyIPTCExtLocationCountryName as String }
        @available(iOS 11.3, *)
        static var IPTCExtLocationGPSAltitude:String { return kCGImagePropertyIPTCExtLocationGPSAltitude as String }
        @available(iOS 11.3, *)
        static var IPTCExtLocationGPSLatitude:String { return kCGImagePropertyIPTCExtLocationGPSLatitude as String }
        @available(iOS 11.3, *)
        static var IPTCExtLocationGPSLongitude:String { return kCGImagePropertyIPTCExtLocationGPSLongitude as String }
        @available(iOS 11.3, *)
        static var IPTCExtLocationIdentifier:String { return kCGImagePropertyIPTCExtLocationIdentifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtLocationLocationId:String { return kCGImagePropertyIPTCExtLocationLocationId as String }
        @available(iOS 11.3, *)
        static var IPTCExtLocationLocationName:String { return kCGImagePropertyIPTCExtLocationLocationName as String }
        @available(iOS 11.3, *)
        static var IPTCExtLocationProvinceState:String { return kCGImagePropertyIPTCExtLocationProvinceState as String }
        @available(iOS 11.3, *)
        static var IPTCExtLocationSublocation:String { return kCGImagePropertyIPTCExtLocationSublocation as String }
        @available(iOS 11.3, *)
        static var IPTCExtLocationWorldRegion:String { return kCGImagePropertyIPTCExtLocationWorldRegion as String }
        @available(iOS 11.3, *)
        static var IPTCExtLocationShown:String { return kCGImagePropertyIPTCExtLocationShown as String }
        @available(iOS 11.3, *)
        static var IPTCExtMaxAvailHeight:String { return kCGImagePropertyIPTCExtMaxAvailHeight as String }
        @available(iOS 11.3, *)
        static var IPTCExtMaxAvailWidth:String { return kCGImagePropertyIPTCExtMaxAvailWidth as String }
        @available(iOS 11.3, *)
        static var IPTCExtModelAge:String { return kCGImagePropertyIPTCExtModelAge as String }
        @available(iOS 11.3, *)
        static var IPTCExtOrganisationInImageCode:String { return kCGImagePropertyIPTCExtOrganisationInImageCode as String }
        @available(iOS 11.3, *)
        static var IPTCExtOrganisationInImageName:String { return kCGImagePropertyIPTCExtOrganisationInImageName as String }
        @available(iOS 11.3, *)
        static var IPTCExtPersonHeard:String { return kCGImagePropertyIPTCExtPersonHeard as String }
        @available(iOS 11.3, *)
        static var IPTCExtPersonHeardIdentifier:String { return kCGImagePropertyIPTCExtPersonHeardIdentifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtPersonHeardName:String { return kCGImagePropertyIPTCExtPersonHeardName as String }
        @available(iOS 11.3, *)
        static var IPTCExtPersonInImage:String { return kCGImagePropertyIPTCExtPersonInImage as String }
        @available(iOS 11.3, *)
        static var IPTCExtPersonInImageWDetails:String { return kCGImagePropertyIPTCExtPersonInImageWDetails as String }
        @available(iOS 11.3, *)
        static var IPTCExtPersonInImageCharacteristic:String { return kCGImagePropertyIPTCExtPersonInImageCharacteristic as String }
        @available(iOS 11.3, *)
        static var IPTCExtPersonInImageCvTermCvId:String { return kCGImagePropertyIPTCExtPersonInImageCvTermCvId as String }
        @available(iOS 11.3, *)
        static var IPTCExtPersonInImageCvTermId:String { return kCGImagePropertyIPTCExtPersonInImageCvTermId as String }
        @available(iOS 11.3, *)
        static var IPTCExtPersonInImageCvTermName:String { return kCGImagePropertyIPTCExtPersonInImageCvTermName as String }
        @available(iOS 11.3, *)
        static var IPTCExtPersonInImageCvTermRefinedAbout:String { return kCGImagePropertyIPTCExtPersonInImageCvTermRefinedAbout as String }
        @available(iOS 11.3, *)
        static var IPTCExtPersonInImageDescription:String { return kCGImagePropertyIPTCExtPersonInImageDescription as String }
        @available(iOS 11.3, *)
        static var IPTCExtPersonInImageId:String { return kCGImagePropertyIPTCExtPersonInImageId as String }
        @available(iOS 11.3, *)
        static var IPTCExtPersonInImageName:String { return kCGImagePropertyIPTCExtPersonInImageName as String }
        @available(iOS 11.3, *)
        static var IPTCExtProductInImage:String { return kCGImagePropertyIPTCExtProductInImage as String }
        @available(iOS 11.3, *)
        static var IPTCExtProductInImageDescription:String { return kCGImagePropertyIPTCExtProductInImageDescription as String }
        @available(iOS 11.3, *)
        static var IPTCExtProductInImageGTIN:String { return kCGImagePropertyIPTCExtProductInImageGTIN as String }
        @available(iOS 11.3, *)
        static var IPTCExtProductInImageName:String { return kCGImagePropertyIPTCExtProductInImageName as String }
        @available(iOS 11.3, *)
        static var IPTCExtPublicationEvent:String { return kCGImagePropertyIPTCExtPublicationEvent as String }
        @available(iOS 11.3, *)
        static var IPTCExtPublicationEventDate:String { return kCGImagePropertyIPTCExtPublicationEventDate as String }
        @available(iOS 11.3, *)
        static var IPTCExtPublicationEventIdentifier:String { return kCGImagePropertyIPTCExtPublicationEventIdentifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtPublicationEventName:String { return kCGImagePropertyIPTCExtPublicationEventName as String }
        @available(iOS 11.3, *)
        static var IPTCExtRating:String { return kCGImagePropertyIPTCExtRating as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingRatingRegion:String { return kCGImagePropertyIPTCExtRatingRatingRegion as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingRegionCity:String { return kCGImagePropertyIPTCExtRatingRegionCity as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingRegionCountryCode:String { return kCGImagePropertyIPTCExtRatingRegionCountryCode as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingRegionCountryName:String { return kCGImagePropertyIPTCExtRatingRegionCountryName as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingRegionGPSAltitude:String { return kCGImagePropertyIPTCExtRatingRegionGPSAltitude as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingRegionGPSLatitude:String { return kCGImagePropertyIPTCExtRatingRegionGPSLatitude as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingRegionGPSLongitude:String { return kCGImagePropertyIPTCExtRatingRegionGPSLongitude as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingRegionIdentifier:String { return kCGImagePropertyIPTCExtRatingRegionIdentifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingRegionLocationId:String { return kCGImagePropertyIPTCExtRatingRegionLocationId as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingRegionLocationName:String { return kCGImagePropertyIPTCExtRatingRegionLocationName as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingRegionProvinceState:String { return kCGImagePropertyIPTCExtRatingRegionProvinceState as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingRegionSublocation:String { return kCGImagePropertyIPTCExtRatingRegionSublocation as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingRegionWorldRegion:String { return kCGImagePropertyIPTCExtRatingRegionWorldRegion as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingScaleMaxValue:String { return kCGImagePropertyIPTCExtRatingScaleMaxValue as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingScaleMinValue:String { return kCGImagePropertyIPTCExtRatingScaleMinValue as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingSourceLink:String { return kCGImagePropertyIPTCExtRatingSourceLink as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingValue:String { return kCGImagePropertyIPTCExtRatingValue as String }
        @available(iOS 11.3, *)
        static var IPTCExtRatingValueLogoLink:String { return kCGImagePropertyIPTCExtRatingValueLogoLink as String }
        @available(iOS 11.3, *)
        static var IPTCExtRegistryID:String { return kCGImagePropertyIPTCExtRegistryID as String }
        @available(iOS 11.3, *)
        static var IPTCExtRegistryEntryRole:String { return kCGImagePropertyIPTCExtRegistryEntryRole as String }
        @available(iOS 11.3, *)
        static var IPTCExtRegistryItemID:String { return kCGImagePropertyIPTCExtRegistryItemID as String }
        @available(iOS 11.3, *)
        static var IPTCExtRegistryOrganisationID:String { return kCGImagePropertyIPTCExtRegistryOrganisationID as String }
        @available(iOS 11.3, *)
        static var IPTCExtReleaseReady:String { return kCGImagePropertyIPTCExtReleaseReady as String }
        @available(iOS 11.3, *)
        static var IPTCExtSeason:String { return kCGImagePropertyIPTCExtSeason as String }
        @available(iOS 11.3, *)
        static var IPTCExtSeasonIdentifier:String { return kCGImagePropertyIPTCExtSeasonIdentifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtSeasonName:String { return kCGImagePropertyIPTCExtSeasonName as String }
        @available(iOS 11.3, *)
        static var IPTCExtSeasonNumber:String { return kCGImagePropertyIPTCExtSeasonNumber as String }
        @available(iOS 11.3, *)
        static var IPTCExtSeries:String { return kCGImagePropertyIPTCExtSeries as String }
        @available(iOS 11.3, *)
        static var IPTCExtSeriesIdentifier:String { return kCGImagePropertyIPTCExtSeriesIdentifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtSeriesName:String { return kCGImagePropertyIPTCExtSeriesName as String }
        @available(iOS 11.3, *)
        static var IPTCExtStorylineIdentifier:String { return kCGImagePropertyIPTCExtStorylineIdentifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtStreamReady:String { return kCGImagePropertyIPTCExtStreamReady as String }
        @available(iOS 11.3, *)
        static var IPTCExtStylePeriod:String { return kCGImagePropertyIPTCExtStylePeriod as String }
        @available(iOS 11.3, *)
        static var IPTCExtSupplyChainSource:String { return kCGImagePropertyIPTCExtSupplyChainSource as String }
        @available(iOS 11.3, *)
        static var IPTCExtSupplyChainSourceIdentifier:String { return kCGImagePropertyIPTCExtSupplyChainSourceIdentifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtSupplyChainSourceName:String { return kCGImagePropertyIPTCExtSupplyChainSourceName as String }
        @available(iOS 11.3, *)
        static var IPTCExtTemporalCoverage:String { return kCGImagePropertyIPTCExtTemporalCoverage as String }
        @available(iOS 11.3, *)
        static var IPTCExtTemporalCoverageFrom:String { return kCGImagePropertyIPTCExtTemporalCoverageFrom as String }
        @available(iOS 11.3, *)
        static var IPTCExtTemporalCoverageTo:String { return kCGImagePropertyIPTCExtTemporalCoverageTo as String }
        @available(iOS 11.3, *)
        static var IPTCExtTranscript:String { return kCGImagePropertyIPTCExtTranscript as String }
        @available(iOS 11.3, *)
        static var IPTCExtTranscriptLink:String { return kCGImagePropertyIPTCExtTranscriptLink as String }
        @available(iOS 11.3, *)
        static var IPTCExtTranscriptLinkLink:String { return kCGImagePropertyIPTCExtTranscriptLinkLink as String }
        @available(iOS 11.3, *)
        static var IPTCExtTranscriptLinkLinkQualifier:String { return kCGImagePropertyIPTCExtTranscriptLinkLinkQualifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtVideoBitrate:String { return kCGImagePropertyIPTCExtVideoBitrate as String }
        @available(iOS 11.3, *)
        static var IPTCExtVideoBitrateMode:String { return kCGImagePropertyIPTCExtVideoBitrateMode as String }
        @available(iOS 11.3, *)
        static var IPTCExtVideoDisplayAspectRatio:String { return kCGImagePropertyIPTCExtVideoDisplayAspectRatio as String }
        @available(iOS 11.3, *)
        static var IPTCExtVideoEncodingProfile:String { return kCGImagePropertyIPTCExtVideoEncodingProfile as String }
        @available(iOS 11.3, *)
        static var IPTCExtVideoShotType:String { return kCGImagePropertyIPTCExtVideoShotType as String }
        @available(iOS 11.3, *)
        static var IPTCExtVideoShotTypeIdentifier:String { return kCGImagePropertyIPTCExtVideoShotTypeIdentifier as String }
        @available(iOS 11.3, *)
        static var IPTCExtVideoShotTypeName:String { return kCGImagePropertyIPTCExtVideoShotTypeName as String }
        @available(iOS 11.3, *)
        static var IPTCExtVideoStreamsCount:String { return kCGImagePropertyIPTCExtVideoStreamsCount as String }
        @available(iOS 11.3, *)
        static var IPTCExtVisualColor:String { return kCGImagePropertyIPTCExtVisualColor as String }
        @available(iOS 11.3, *)
        static var IPTCExtWorkflowTag:String { return kCGImagePropertyIPTCExtWorkflowTag as String }
        @available(iOS 11.3, *)
        static var IPTCExtWorkflowTagCvId:String { return kCGImagePropertyIPTCExtWorkflowTagCvId as String }
        @available(iOS 11.3, *)
        static var IPTCExtWorkflowTagCvTermId:String { return kCGImagePropertyIPTCExtWorkflowTagCvTermId as String }
        @available(iOS 11.3, *)
        static var IPTCExtWorkflowTagCvTermName:String { return kCGImagePropertyIPTCExtWorkflowTagCvTermName as String }
        @available(iOS 11.3, *)
        static var IPTCExtWorkflowTagCvTermRefinedAbout:String { return kCGImagePropertyIPTCExtWorkflowTagCvTermRefinedAbout as String }

/* Possible keys for kCGImagePropertyIPTCCreatorContactInfo dictionary (part of IPTC Core - above) */

        static var IPTCContactInfoCity:String { return kCGImagePropertyIPTCContactInfoCity as String }
        static var IPTCContactInfoCountry:String { return kCGImagePropertyIPTCContactInfoCountry as String }
        static var IPTCContactInfoAddress:String { return kCGImagePropertyIPTCContactInfoAddress as String }
        static var IPTCContactInfoPostalCode:String { return kCGImagePropertyIPTCContactInfoPostalCode as String }
        static var IPTCContactInfoStateProvince:String { return kCGImagePropertyIPTCContactInfoStateProvince as String }
        static var IPTCContactInfoEmails:String { return kCGImagePropertyIPTCContactInfoEmails as String }
        static var IPTCContactInfoPhones:String { return kCGImagePropertyIPTCContactInfoPhones as String }
        static var IPTCContactInfoWebURLs:String { return kCGImagePropertyIPTCContactInfoWebURLs as String }

/* Possible keys for kCGImageProperty8BIMDictionary */

        static var _8BIMLayerNames:String { return kCGImageProperty8BIMLayerNames as String }
        @available(iOS 8.0, *)
        static var _8BIMVersion:String { return kCGImageProperty8BIMVersion as String }

/* Possible keys for kCGImagePropertyDNGDictionary */

        static var DNGVersion:String { return kCGImagePropertyDNGVersion as String }
        static var DNGBackwardVersion:String { return kCGImagePropertyDNGBackwardVersion as String }
        static var DNGUniqueCameraModel:String { return kCGImagePropertyDNGUniqueCameraModel as String }
        static var DNGLocalizedCameraModel:String { return kCGImagePropertyDNGLocalizedCameraModel as String }
        static var DNGCameraSerialNumber:String { return kCGImagePropertyDNGCameraSerialNumber as String }
        static var DNGLensInfo:String { return kCGImagePropertyDNGLensInfo as String }
        @available(iOS 10.0, *)
        static var DNGBlackLevel:String { return kCGImagePropertyDNGBlackLevel as String }
        @available(iOS 10.0, *)
        static var DNGWhiteLevel:String { return kCGImagePropertyDNGWhiteLevel as String }
        @available(iOS 10.0, *)
        static var DNGCalibrationIlluminant1:String { return kCGImagePropertyDNGCalibrationIlluminant1 as String }
        @available(iOS 10.0, *)
        static var DNGCalibrationIlluminant2:String { return kCGImagePropertyDNGCalibrationIlluminant2 as String }
        @available(iOS 10.0, *)
        static var DNGColorMatrix1:String { return kCGImagePropertyDNGColorMatrix1 as String }
        @available(iOS 10.0, *)
        static var DNGColorMatrix2:String { return kCGImagePropertyDNGColorMatrix2 as String }
        @available(iOS 10.0, *)
        static var DNGCameraCalibration1:String { return kCGImagePropertyDNGCameraCalibration1 as String }
        @available(iOS 10.0, *)
        static var DNGCameraCalibration2:String { return kCGImagePropertyDNGCameraCalibration2 as String }
        @available(iOS 10.0, *)
        static var DNGAsShotNeutral:String { return kCGImagePropertyDNGAsShotNeutral as String }
        @available(iOS 10.0, *)
        static var DNGAsShotWhiteXY:String { return kCGImagePropertyDNGAsShotWhiteXY as String }
        @available(iOS 10.0, *)
        static var DNGBaselineExposure:String { return kCGImagePropertyDNGBaselineExposure as String }
        @available(iOS 10.0, *)
        static var DNGBaselineNoise:String { return kCGImagePropertyDNGBaselineNoise as String }
        @available(iOS 10.0, *)
        static var DNGBaselineSharpness:String { return kCGImagePropertyDNGBaselineSharpness as String }
        @available(iOS 10.0, *)
        static var DNGPrivateData:String { return kCGImagePropertyDNGPrivateData as String }
        @available(iOS 10.0, *)
        static var DNGCameraCalibrationSignature:String { return kCGImagePropertyDNGCameraCalibrationSignature as String }
        @available(iOS 10.0, *)
        static var DNGProfileCalibrationSignature:String { return kCGImagePropertyDNGProfileCalibrationSignature as String }
        @available(iOS 10.0, *)
        static var DNGNoiseProfile:String { return kCGImagePropertyDNGNoiseProfile as String }
        @available(iOS 10.0, *)
        static var DNGWarpRectilinear:String { return kCGImagePropertyDNGWarpRectilinear as String }
        @available(iOS 10.0, *)
        static var DNGWarpFisheye:String { return kCGImagePropertyDNGWarpFisheye as String }
        @available(iOS 10.0, *)
        static var DNGFixVignetteRadial:String { return kCGImagePropertyDNGFixVignetteRadial as String }

/* Possible keys for kCGImagePropertyCIFFDictionary */

        static var CIFFDescription:String { return kCGImagePropertyCIFFDescription as String }
        static var CIFFFirmware:String { return kCGImagePropertyCIFFFirmware as String }
        static var CIFFOwnerName:String { return kCGImagePropertyCIFFOwnerName as String }
        static var CIFFImageName:String { return kCGImagePropertyCIFFImageName as String }
        static var CIFFImageFileName:String { return kCGImagePropertyCIFFImageFileName as String }
        static var CIFFReleaseMethod:String { return kCGImagePropertyCIFFReleaseMethod as String }
        static var CIFFReleaseTiming:String { return kCGImagePropertyCIFFReleaseTiming as String }
        static var CIFFRecordID:String { return kCGImagePropertyCIFFRecordID as String }
        static var CIFFSelfTimingTime:String { return kCGImagePropertyCIFFSelfTimingTime as String }
        static var CIFFCameraSerialNumber:String { return kCGImagePropertyCIFFCameraSerialNumber as String }
        static var CIFFImageSerialNumber:String { return kCGImagePropertyCIFFImageSerialNumber as String }
        static var CIFFContinuousDrive:String { return kCGImagePropertyCIFFContinuousDrive as String }
        static var CIFFFocusMode:String { return kCGImagePropertyCIFFFocusMode as String }
        static var CIFFMeteringMode:String { return kCGImagePropertyCIFFMeteringMode as String }
        static var CIFFShootingMode:String { return kCGImagePropertyCIFFShootingMode as String }
        static var CIFFLensModel:String { return kCGImagePropertyCIFFLensModel as String }
        static var CIFFLensMaxMM:String { return kCGImagePropertyCIFFLensMaxMM as String }
        static var CIFFLensMinMM:String { return kCGImagePropertyCIFFLensMinMM as String }
        static var CIFFWhiteBalanceIndex:String { return kCGImagePropertyCIFFWhiteBalanceIndex as String }
        static var CIFFFlashExposureComp:String { return kCGImagePropertyCIFFFlashExposureComp as String }
        static var CIFFMeasuredEV:String { return kCGImagePropertyCIFFMeasuredEV as String }

/* Possible keys for kCGImagePropertyMakerNikonDictionary */

        static var MakerNikonISOSetting:String { return kCGImagePropertyMakerNikonISOSetting as String }
        static var MakerNikonColorMode:String { return kCGImagePropertyMakerNikonColorMode as String }
        static var MakerNikonQuality:String { return kCGImagePropertyMakerNikonQuality as String }
        static var MakerNikonWhiteBalanceMode:String { return kCGImagePropertyMakerNikonWhiteBalanceMode as String }
        static var MakerNikonSharpenMode:String { return kCGImagePropertyMakerNikonSharpenMode as String }
        static var MakerNikonFocusMode:String { return kCGImagePropertyMakerNikonFocusMode as String }
        static var MakerNikonFlashSetting:String { return kCGImagePropertyMakerNikonFlashSetting as String }
        static var MakerNikonISOSelection:String { return kCGImagePropertyMakerNikonISOSelection as String }
        static var MakerNikonFlashExposureComp:String { return kCGImagePropertyMakerNikonFlashExposureComp as String }
        static var MakerNikonImageAdjustment:String { return kCGImagePropertyMakerNikonImageAdjustment as String }
        static var MakerNikonLensAdapter:String { return kCGImagePropertyMakerNikonLensAdapter as String }
        static var MakerNikonLensType:String { return kCGImagePropertyMakerNikonLensType as String }
        static var MakerNikonLensInfo:String { return kCGImagePropertyMakerNikonLensInfo as String }
        static var MakerNikonFocusDistance:String { return kCGImagePropertyMakerNikonFocusDistance as String }
        static var MakerNikonDigitalZoom:String { return kCGImagePropertyMakerNikonDigitalZoom as String }
        static var MakerNikonShootingMode:String { return kCGImagePropertyMakerNikonShootingMode as String }
        static var MakerNikonCameraSerialNumber:String { return kCGImagePropertyMakerNikonCameraSerialNumber as String }
        static var MakerNikonShutterCount:String { return kCGImagePropertyMakerNikonShutterCount as String }

/* Possible keys for kCGImagePropertyMakerCanonDictionary */

        static var MakerCanonOwnerName:String { return kCGImagePropertyMakerCanonOwnerName as String }
        static var MakerCanonCameraSerialNumber:String { return kCGImagePropertyMakerCanonCameraSerialNumber as String }
        static var MakerCanonImageSerialNumber:String { return kCGImagePropertyMakerCanonImageSerialNumber as String }
        static var MakerCanonFlashExposureComp:String { return kCGImagePropertyMakerCanonFlashExposureComp as String }
        static var MakerCanonContinuousDrive:String { return kCGImagePropertyMakerCanonContinuousDrive as String }
        static var MakerCanonLensModel:String { return kCGImagePropertyMakerCanonLensModel as String }
        static var MakerCanonFirmware:String { return kCGImagePropertyMakerCanonFirmware as String }
        static var MakerCanonAspectRatioInfo:String { return kCGImagePropertyMakerCanonAspectRatioInfo as String }

/* Possible keys for kCGImagePropertyOpenEXRDictionary */

        @available(iOS 11.3, *)
        static var OpenEXRAspectRatio:String { return kCGImagePropertyOpenEXRAspectRatio as String }

/*
 * Allows client to choose the filters applied before PNG compression
 * http://www.libpng.org/pub/png/book/chapter09.html#png.ch09.div.1
 * The value should be a CFNumber, of type long, containing a bitwise OR of the desired filters
 * The filters are defined below, IMAGEIO_PNG_NO_FILTERS, IMAGEIO_PNG_FILTER_NONE, etc
 * This value has no effect when compressing to any format other than PNG
 */
        @available(iOS 9.0, *)
        static var PNGCompressionFilter:String { return kCGImagePropertyPNGCompressionFilter as String }

/* For use with CGImageSourceCopyAuxiliaryDataInfoAtIndex and CGImageDestinationAddAuxiliaryDataInfo:
 * These strings specify the 'auxiliaryImageDataType':
 */
        @available(iOS 11.0, *)
        static var AuxiliaryDataTypeDepth:String { return kCGImageAuxiliaryDataTypeDepth as String }
        @available(iOS 11.0, *)
        static var AuxiliaryDataTypeDisparity:String { return kCGImageAuxiliaryDataTypeDisparity as String }

/* Depth/Disparity data support for JPEG, HEIF, and DNG images:
 * CGImageSourceCopyAuxiliaryDataInfoAtIndex and CGImageDestinationAddAuxiliaryDataInfo will use these keys in the dictionary:
 * kCGImageAuxiliaryDataInfoData - the depth data (CFDataRef)
 * kCGImageAuxiliaryDataInfoDataDescription - the depth data description (CFDictionary)
 * kCGImageAuxiliaryDataInfoMetadata - metadata (CGImageMetadataRef)
 */
        @available(iOS 11.0, *)
        static var AuxiliaryDataInfoData:String { return kCGImageAuxiliaryDataInfoData as String }
        @available(iOS 11.0, *)
        static var AuxiliaryDataInfoDataDescription:String { return kCGImageAuxiliaryDataInfoDataDescription as String }
        @available(iOS 11.0, *)
        static var AuxiliaryDataInfoMetadata:String { return kCGImageAuxiliaryDataInfoMetadata as String }

        @available(iOS 11.0, *)
        static var ImageCount:String { return kCGImagePropertyImageCount as String }
        @available(iOS 11.0, *)
        static var Width:String { return kCGImagePropertyWidth as String }
        @available(iOS 11.0, *)
        static var Height:String { return kCGImagePropertyHeight as String }
        @available(iOS 11.0, *)
        static var BytesPerRow:String { return kCGImagePropertyBytesPerRow as String }
        @available(iOS 11.0, *)
        static var NamedColorSpace:String { return kCGImagePropertyNamedColorSpace as String }
        @available(iOS 11.0, *)
        static var PixelFormat:String { return kCGImagePropertyPixelFormat as String }
        @available(iOS 11.0, *)
        static var Images:String { return kCGImagePropertyImages as String }
        @available(iOS 11.0, *)
        static var ThumbnailImages:String { return kCGImagePropertyThumbnailImages as String }
        @available(iOS 11.0, *)
        static var AuxiliaryData:String { return kCGImagePropertyAuxiliaryData as String }
        @available(iOS 11.0, *)
        static var AuxiliaryDataType:String { return kCGImagePropertyAuxiliaryDataType as String }
    }

    public struct PropertyApple {
        static var supportedDictionaries: [String] {
            return [Dictionary.TIFF, Dictionary.Exif, Dictionary.GPS]
        }

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
        static var GPS: [String] {
            return [
                Property.GPSVersion,
                    Property.GPSLatitudeRef,
                    Property.GPSLatitude,
                    Property.GPSLongitudeRef,
                    Property.GPSLongitude,
                    Property.GPSAltitudeRef,
                    Property.GPSAltitude,
                    Property.GPSTimeStamp,
                    Property.GPSSatellites,
                    Property.GPSStatus,
                    Property.GPSMeasureMode,
                    Property.GPSDOP,
                    Property.GPSSpeedRef,
                    Property.GPSSpeed,
                    Property.GPSTrackRef,
                    Property.GPSTrack,
                    Property.GPSImgDirectionRef,
                    Property.GPSImgDirection,
                    Property.GPSMapDatum,
                    Property.GPSDestLatitudeRef,
                    Property.GPSDestLatitude,
                    Property.GPSDestLongitudeRef,
                    Property.GPSDestLongitude,
                    Property.GPSDestBearingRef,
                    Property.GPSDestBearing,
                    Property.GPSDestDistanceRef,
                    Property.GPSDestDistance,
                    Property.GPSProcessingMethod,
                    Property.GPSAreaInformation,
                    Property.GPSDateStamp,
                    Property.GPSDifferental,
                    Property.GPSHPositioningError
            ]
        }


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
        static var EXIF: [String] {
            return [
                Property.ExifExposureTime,
                Property.ExifFNumber,
                Property.ExifExposureProgram,
                Property.ExifSpectralSensitivity,
                Property.ExifISOSpeedRatings,
                Property.ExifOECF,
                Property.ExifSensitivityType,
                Property.ExifStandardOutputSensitivity,
                Property.ExifRecommendedExposureIndex,
                Property.ExifISOSpeed,
                Property.ExifISOSpeedLatitudeyyy,
                Property.ExifISOSpeedLatitudezzz,
                Property.ExifVersion,
                Property.ExifDateTimeOriginal,
                Property.ExifDateTimeDigitized,
                Property.ExifComponentsConfiguration,
                Property.ExifCompressedBitsPerPixel,
                Property.ExifShutterSpeedValue,
                Property.ExifApertureValue,
                Property.ExifBrightnessValue,
                Property.ExifExposureBiasValue,
                Property.ExifMaxApertureValue,
                Property.ExifSubjectDistance,
                Property.ExifMeteringMode,
                Property.ExifLightSource,
                Property.ExifFlash,
                Property.ExifFocalLength,
                Property.ExifSubjectArea,
                Property.ExifMakerNote,
                Property.ExifUserComment,
                Property.ExifSubsecTime,
                Property.ExifSubsecTimeOriginal,
                Property.ExifSubsecTimeDigitized,
                Property.ExifFlashPixVersion,
                Property.ExifColorSpace,
                Property.ExifPixelXDimension,
                Property.ExifPixelYDimension,
                Property.ExifRelatedSoundFile,
                Property.ExifFlashEnergy,
                Property.ExifSpatialFrequencyResponse,
                Property.ExifFocalPlaneXResolution,
                Property.ExifFocalPlaneYResolution,
                Property.ExifFocalPlaneResolutionUnit,
                Property.ExifSubjectLocation,
                Property.ExifExposureIndex,
                Property.ExifSensingMethod,
                Property.ExifFileSource,
                Property.ExifSceneType,
                Property.ExifCFAPattern,
                Property.ExifCustomRendered,
                Property.ExifExposureMode,
                Property.ExifWhiteBalance,
                Property.ExifDigitalZoomRatio,
                Property.ExifFocalLenIn35mmFilm,
                Property.ExifSceneCaptureType,
                Property.ExifGainControl,
                Property.ExifContrast,
                Property.ExifSaturation,
                Property.ExifSharpness,
                Property.ExifDeviceSettingDescription,
                Property.ExifSubjectDistRange,
                Property.ExifImageUniqueID,
                Property.ExifCameraOwnerName,
                Property.ExifBodySerialNumber,
                Property.ExifLensSpecification,
                Property.ExifLensMake,
                Property.ExifLensModel,
                Property.ExifLensSerialNumber,
                Property.ExifGamma
            ]
        }

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
        static var TIFF: [String] {
            return [
                Property.TIFFCompression
                , Property.TIFFPhotometricInterpretation
                , Property.TIFFDocumentName
                , Property.TIFFImageDescription
                , Property.TIFFMake
                , Property.TIFFModel
                , Property.TIFFOrientation
                , Property.TIFFXResolution
                , Property.TIFFYResolution
                , Property.TIFFResolutionUnit
                , Property.TIFFSoftware
                , Property.TIFFTransferFunction
                , Property.TIFFDateTime
                , Property.TIFFArtist
                , Property.TIFFHostComputer
                , Property.TIFFCopyright
                , Property.TIFFWhitePoint
                , Property.TIFFPrimaryChromaticities
                , Property.TIFFTileWidth
                , Property.TIFFTileLength
            ]
        }
    }
}


