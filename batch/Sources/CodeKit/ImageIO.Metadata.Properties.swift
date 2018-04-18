//
// Created by BLACKGENE on 16/04/2018.
// Copyright c 2018 Stells. All rights reserved.
//

// (kCGImageProperty)(.+)\sas\sString -> static let $2 = $1$2 as String
// .*(kCGImageProperty)(.+)(Dictionary):\sCFString -> static let $2 = $1$2$3 as String

// .*(kCGImage)(.+):\sCFString -> static let $2 = $1$2 as String

import Foundation
import ImageIO

public typealias ImageMetadataCollection = [String:[String]]

public struct ImageMetadata {
    static let FileSize = kCGImagePropertyFileSize as String

/* The number of pixels in the x- and y-dimensions. The value of these keys
 * is a CFNumberRef. */

/** Properties which may be returned by "CGImageSourceCopyPropertiesAtIndex".
 ** The values apply to a single image of an image source file. **/
    static let PixelHeight = kCGImagePropertyPixelHeight as String
    static let PixelWidth = kCGImagePropertyPixelWidth as String

/* The DPI in the x- and y-dimensions, if known. If present, the value of
 * these keys is a CFNumberRef. */

    static let DPIHeight = kCGImagePropertyDPIHeight as String
    static let DPIWidth = kCGImagePropertyDPIWidth as String

/* The number of bits in each color sample of each pixel. The value of this
 * key is a CFNumberRef. */

    static let Depth = kCGImagePropertyDepth as String

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

    static let Orientation = kCGImagePropertyOrientation as String

/* The value of this key is kCFBooleanTrue if the image contains floating-
 * point pixel samples */

    static let IsFloat = kCGImagePropertyIsFloat as String

/* The value of this key is kCFBooleanTrue if the image contains indexed
 * (a.k.a. paletted) pixel samples */

    static let IsIndexed = kCGImagePropertyIsIndexed as String

/* The value of this key is kCFBooleanTrue if the image contains an alpha
 * (a.k.a. coverage) channel */

    static let HasAlpha = kCGImagePropertyHasAlpha as String

/* The color model of the image such as "RGB", "CMYK", "Gray", or "Lab".
 * The value of this key is CFStringRef. */

    static let ColorModel = kCGImagePropertyColorModel as String

/* The name of the optional ICC profile embedded in the image, if known.
 * If present, the value of this key is a CFStringRef. */

    static let ProfileName = kCGImagePropertyProfileName as String

/* Possible values for kCGImagePropertyColorModel property */

    static let ColorModelRGB = kCGImagePropertyColorModelRGB as String
    static let ColorModelGray = kCGImagePropertyColorModelGray as String
    static let ColorModelCMYK = kCGImagePropertyColorModelCMYK as String
    static let ColorModelLab = kCGImagePropertyColorModelLab as String

    public struct Dictionary {
        static let TIFF = kCGImagePropertyTIFFDictionary as String
        static let GIF = kCGImagePropertyGIFDictionary as String
        static let JFIF = kCGImagePropertyJFIFDictionary as String
        static let Exif = kCGImagePropertyExifDictionary as String
        static let PNG = kCGImagePropertyPNGDictionary as String
        static let IPTC = kCGImagePropertyIPTCDictionary as String
        static let GPS = kCGImagePropertyGPSDictionary as String
        static let Raw = kCGImagePropertyRawDictionary as String
        static let CIFF = kCGImagePropertyCIFFDictionary as String
        static let MakerCanon = kCGImagePropertyMakerCanonDictionary as String
        static let MakerNikon = kCGImagePropertyMakerNikonDictionary as String
        static let MakerMinolta = kCGImagePropertyMakerMinoltaDictionary as String
        static let MakerFuji = kCGImagePropertyMakerFujiDictionary as String
        static let MakerOlympus = kCGImagePropertyMakerOlympusDictionary as String
        static let MakerPentax = kCGImagePropertyMakerPentaxDictionary as String
        static let _8BIM = kCGImageProperty8BIMDictionary as String
        static let DNG = kCGImagePropertyDNGDictionary as String
        static let ExifAux = kCGImagePropertyExifAuxDictionary as String
        @available(iOS 11.3, *)
        static let OpenEXR = kCGImagePropertyOpenEXRDictionary as String
        @available(iOS 7.0, *)
        static let MakerApple = kCGImagePropertyMakerAppleDictionary as String
        @available(iOS 11.0, *)
        static let FileContents = kCGImagePropertyFileContentsDictionary as String
    }

    public struct Property {
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
        @available(iOS 9.0, *)
        static let TIFFTileWidth = kCGImagePropertyTIFFTileWidth as String
        @available(iOS 9.0, *)
        static let TIFFTileLength = kCGImagePropertyTIFFTileLength as String

/* Possible keys for kCGImagePropertyJFIFDictionary */

        static let JFIFVersion = kCGImagePropertyJFIFVersion as String
        static let JFIFXDensity = kCGImagePropertyJFIFXDensity as String
        static let JFIFYDensity = kCGImagePropertyJFIFYDensity as String
        static let JFIFDensityUnit = kCGImagePropertyJFIFDensityUnit as String
        static let JFIFIsProgressive = kCGImagePropertyJFIFIsProgressive as String

/* Possible keys for kCGImagePropertyExifDictionary */

        static let ExifExposureTime = kCGImagePropertyExifExposureTime as String
        static let ExifFNumber = kCGImagePropertyExifFNumber as String
        static let ExifExposureProgram = kCGImagePropertyExifExposureProgram as String
        static let ExifSpectralSensitivity = kCGImagePropertyExifSpectralSensitivity as String
        static let ExifISOSpeedRatings = kCGImagePropertyExifISOSpeedRatings as String
        static let ExifOECF = kCGImagePropertyExifOECF as String
        @available(iOS 7.0, *)
        static let ExifSensitivityType = kCGImagePropertyExifSensitivityType as String
        @available(iOS 7.0, *)
        static let ExifStandardOutputSensitivity = kCGImagePropertyExifStandardOutputSensitivity as String
        @available(iOS 7.0, *)
        static let ExifRecommendedExposureIndex = kCGImagePropertyExifRecommendedExposureIndex as String
        @available(iOS 7.0, *)
        static let ExifISOSpeed = kCGImagePropertyExifISOSpeed as String
        @available(iOS 7.0, *)
        static let ExifISOSpeedLatitudeyyy = kCGImagePropertyExifISOSpeedLatitudeyyy as String
        @available(iOS 7.0, *)
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
        @available(iOS 10.0, *)
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
        @available(iOS 5.0, *)
        static let ExifCameraOwnerName = kCGImagePropertyExifCameraOwnerName as String
        @available(iOS 5.0, *)
        static let ExifBodySerialNumber = kCGImagePropertyExifBodySerialNumber as String
        @available(iOS 5.0, *)
        static let ExifLensSpecification = kCGImagePropertyExifLensSpecification as String
        @available(iOS 5.0, *)
        static let ExifLensMake = kCGImagePropertyExifLensMake as String
        @available(iOS 5.0, *)
        static let ExifLensModel = kCGImagePropertyExifLensModel as String
        @available(iOS 5.0, *)
        static let ExifLensSerialNumber = kCGImagePropertyExifLensSerialNumber as String
        static let ExifGamma = kCGImagePropertyExifGamma as String

/* deprecated */
        static let ExifSubsecTimeOrginal = kCGImagePropertyExifSubsecTimeOrginal as String

/* Possible keys for kCGImagePropertyExifAuxDictionary */
        static let ExifAuxLensInfo = kCGImagePropertyExifAuxLensInfo as String
        static let ExifAuxLensModel = kCGImagePropertyExifAuxLensModel as String
        static let ExifAuxSerialNumber = kCGImagePropertyExifAuxSerialNumber as String
        static let ExifAuxLensID = kCGImagePropertyExifAuxLensID as String
        static let ExifAuxLensSerialNumber = kCGImagePropertyExifAuxLensSerialNumber as String
        static let ExifAuxImageNumber = kCGImagePropertyExifAuxImageNumber as String
        static let ExifAuxFlashCompensation = kCGImagePropertyExifAuxFlashCompensation as String
        static let ExifAuxOwnerName = kCGImagePropertyExifAuxOwnerName as String
        static let ExifAuxFirmware = kCGImagePropertyExifAuxFirmware as String

/* Possible keys for kCGImagePropertyGIFDictionary */

        static let GIFLoopCount = kCGImagePropertyGIFLoopCount as String
        static let GIFDelayTime = kCGImagePropertyGIFDelayTime as String
        static let GIFImageColorMap = kCGImagePropertyGIFImageColorMap as String
        static let GIFHasGlobalColorMap = kCGImagePropertyGIFHasGlobalColorMap as String
        static let GIFUnclampedDelayTime = kCGImagePropertyGIFUnclampedDelayTime as String

/* Possible keys for kCGImagePropertyPNGDictionary */

        static let PNGGamma = kCGImagePropertyPNGGamma as String
        static let PNGInterlaceType = kCGImagePropertyPNGInterlaceType as String
        static let PNGXPixelsPerMeter = kCGImagePropertyPNGXPixelsPerMeter as String
        static let PNGYPixelsPerMeter = kCGImagePropertyPNGYPixelsPerMeter as String
        static let PNGsRGBIntent = kCGImagePropertyPNGsRGBIntent as String
        static let PNGChromaticities = kCGImagePropertyPNGChromaticities as String

        @available(iOS 5.0, *)
        static let PNGAuthor = kCGImagePropertyPNGAuthor as String
        @available(iOS 5.0, *)
        static let PNGCopyright = kCGImagePropertyPNGCopyright as String
        @available(iOS 5.0, *)
        static let PNGCreationTime = kCGImagePropertyPNGCreationTime as String
        @available(iOS 5.0, *)
        static let PNGDescription = kCGImagePropertyPNGDescription as String
        @available(iOS 5.0, *)
        static let PNGModificationTime = kCGImagePropertyPNGModificationTime as String
        @available(iOS 5.0, *)
        static let PNGSoftware = kCGImagePropertyPNGSoftware as String
        @available(iOS 5.0, *)
        static let PNGTitle = kCGImagePropertyPNGTitle as String

        @available(iOS 8.0, *)
        static let APNGLoopCount = kCGImagePropertyAPNGLoopCount as String
        @available(iOS 8.0, *)
        static let APNGDelayTime = kCGImagePropertyAPNGDelayTime as String
        @available(iOS 8.0, *)
        static let APNGUnclampedDelayTime = kCGImagePropertyAPNGUnclampedDelayTime as String

/* Possible keys for kCGImagePropertyGPSDictionary */

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
        @available(iOS 8.0, *)
        static let GPSHPositioningError = kCGImagePropertyGPSHPositioningError as String

/* Possible keys for kCGImagePropertyIPTCDictionary */

        static let IPTCObjectTypeReference = kCGImagePropertyIPTCObjectTypeReference as String
        static let IPTCObjectAttributeReference = kCGImagePropertyIPTCObjectAttributeReference as String
        static let IPTCObjectName = kCGImagePropertyIPTCObjectName as String
        static let IPTCEditStatus = kCGImagePropertyIPTCEditStatus as String
        static let IPTCEditorialUpdate = kCGImagePropertyIPTCEditorialUpdate as String
        static let IPTCUrgency = kCGImagePropertyIPTCUrgency as String
        static let IPTCSubjectReference = kCGImagePropertyIPTCSubjectReference as String
        static let IPTCCategory = kCGImagePropertyIPTCCategory as String
        static let IPTCSupplementalCategory = kCGImagePropertyIPTCSupplementalCategory as String
        static let IPTCFixtureIdentifier = kCGImagePropertyIPTCFixtureIdentifier as String
        static let IPTCKeywords = kCGImagePropertyIPTCKeywords as String
        static let IPTCContentLocationCode = kCGImagePropertyIPTCContentLocationCode as String
        static let IPTCContentLocationName = kCGImagePropertyIPTCContentLocationName as String
        static let IPTCReleaseDate = kCGImagePropertyIPTCReleaseDate as String
        static let IPTCReleaseTime = kCGImagePropertyIPTCReleaseTime as String
        static let IPTCExpirationDate = kCGImagePropertyIPTCExpirationDate as String
        static let IPTCExpirationTime = kCGImagePropertyIPTCExpirationTime as String
        static let IPTCSpecialInstructions = kCGImagePropertyIPTCSpecialInstructions as String
        static let IPTCActionAdvised = kCGImagePropertyIPTCActionAdvised as String
        static let IPTCReferenceService = kCGImagePropertyIPTCReferenceService as String
        static let IPTCReferenceDate = kCGImagePropertyIPTCReferenceDate as String
        static let IPTCReferenceNumber = kCGImagePropertyIPTCReferenceNumber as String
        static let IPTCDateCreated = kCGImagePropertyIPTCDateCreated as String
        static let IPTCTimeCreated = kCGImagePropertyIPTCTimeCreated as String
        static let IPTCDigitalCreationDate = kCGImagePropertyIPTCDigitalCreationDate as String
        static let IPTCDigitalCreationTime = kCGImagePropertyIPTCDigitalCreationTime as String
        static let IPTCOriginatingProgram = kCGImagePropertyIPTCOriginatingProgram as String
        static let IPTCProgramVersion = kCGImagePropertyIPTCProgramVersion as String
        static let IPTCObjectCycle = kCGImagePropertyIPTCObjectCycle as String
        static let IPTCByline = kCGImagePropertyIPTCByline as String
        static let IPTCBylineTitle = kCGImagePropertyIPTCBylineTitle as String
        static let IPTCCity = kCGImagePropertyIPTCCity as String
        static let IPTCSubLocation = kCGImagePropertyIPTCSubLocation as String
        static let IPTCProvinceState = kCGImagePropertyIPTCProvinceState as String
        static let IPTCCountryPrimaryLocationCode = kCGImagePropertyIPTCCountryPrimaryLocationCode as String
        static let IPTCCountryPrimaryLocationName = kCGImagePropertyIPTCCountryPrimaryLocationName as String
        static let IPTCOriginalTransmissionReference = kCGImagePropertyIPTCOriginalTransmissionReference as String
        static let IPTCHeadline = kCGImagePropertyIPTCHeadline as String
        static let IPTCCredit = kCGImagePropertyIPTCCredit as String
        static let IPTCSource = kCGImagePropertyIPTCSource as String
        static let IPTCCopyrightNotice = kCGImagePropertyIPTCCopyrightNotice as String
        static let IPTCContact = kCGImagePropertyIPTCContact as String
        static let IPTCCaptionAbstract = kCGImagePropertyIPTCCaptionAbstract as String
        static let IPTCWriterEditor = kCGImagePropertyIPTCWriterEditor as String
        static let IPTCImageType = kCGImagePropertyIPTCImageType as String
        static let IPTCImageOrientation = kCGImagePropertyIPTCImageOrientation as String
        static let IPTCLanguageIdentifier = kCGImagePropertyIPTCLanguageIdentifier as String
        static let IPTCStarRating = kCGImagePropertyIPTCStarRating as String
        static let IPTCCreatorContactInfo = kCGImagePropertyIPTCCreatorContactInfo as String // IPTC Core
        static let IPTCRightsUsageTerms = kCGImagePropertyIPTCRightsUsageTerms as String // IPTC Core
        static let IPTCScene = kCGImagePropertyIPTCScene as String // IPTC Core

        @available(iOS 11.3, *)
        static let IPTCExtAboutCvTerm = kCGImagePropertyIPTCExtAboutCvTerm as String
        @available(iOS 11.3, *)
        static let IPTCExtAboutCvTermCvId = kCGImagePropertyIPTCExtAboutCvTermCvId as String
        @available(iOS 11.3, *)
        static let IPTCExtAboutCvTermId = kCGImagePropertyIPTCExtAboutCvTermId as String
        @available(iOS 11.3, *)
        static let IPTCExtAboutCvTermName = kCGImagePropertyIPTCExtAboutCvTermName as String
        @available(iOS 11.3, *)
        static let IPTCExtAboutCvTermRefinedAbout = kCGImagePropertyIPTCExtAboutCvTermRefinedAbout as String
        @available(iOS 11.3, *)
        static let IPTCExtAddlModelInfo = kCGImagePropertyIPTCExtAddlModelInfo as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkOrObject = kCGImagePropertyIPTCExtArtworkOrObject as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkCircaDateCreated = kCGImagePropertyIPTCExtArtworkCircaDateCreated as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkContentDescription = kCGImagePropertyIPTCExtArtworkContentDescription as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkContributionDescription = kCGImagePropertyIPTCExtArtworkContributionDescription as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkCopyrightNotice = kCGImagePropertyIPTCExtArtworkCopyrightNotice as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkCreator = kCGImagePropertyIPTCExtArtworkCreator as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkCreatorID = kCGImagePropertyIPTCExtArtworkCreatorID as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkCopyrightOwnerID = kCGImagePropertyIPTCExtArtworkCopyrightOwnerID as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkCopyrightOwnerName = kCGImagePropertyIPTCExtArtworkCopyrightOwnerName as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkLicensorID = kCGImagePropertyIPTCExtArtworkLicensorID as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkLicensorName = kCGImagePropertyIPTCExtArtworkLicensorName as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkDateCreated = kCGImagePropertyIPTCExtArtworkDateCreated as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkPhysicalDescription = kCGImagePropertyIPTCExtArtworkPhysicalDescription as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkSource = kCGImagePropertyIPTCExtArtworkSource as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkSourceInventoryNo = kCGImagePropertyIPTCExtArtworkSourceInventoryNo as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkSourceInvURL = kCGImagePropertyIPTCExtArtworkSourceInvURL as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkStylePeriod = kCGImagePropertyIPTCExtArtworkStylePeriod as String
        @available(iOS 11.3, *)
        static let IPTCExtArtworkTitle = kCGImagePropertyIPTCExtArtworkTitle as String
        @available(iOS 11.3, *)
        static let IPTCExtAudioBitrate = kCGImagePropertyIPTCExtAudioBitrate as String
        @available(iOS 11.3, *)
        static let IPTCExtAudioBitrateMode = kCGImagePropertyIPTCExtAudioBitrateMode as String
        @available(iOS 11.3, *)
        static let IPTCExtAudioChannelCount = kCGImagePropertyIPTCExtAudioChannelCount as String
        @available(iOS 11.3, *)
        static let IPTCExtCircaDateCreated = kCGImagePropertyIPTCExtCircaDateCreated as String
        @available(iOS 11.3, *)
        static let IPTCExtContainerFormat = kCGImagePropertyIPTCExtContainerFormat as String
        @available(iOS 11.3, *)
        static let IPTCExtContainerFormatIdentifier = kCGImagePropertyIPTCExtContainerFormatIdentifier as String
        @available(iOS 11.3, *)
        static let IPTCExtContainerFormatName = kCGImagePropertyIPTCExtContainerFormatName as String
        @available(iOS 11.3, *)
        static let IPTCExtContributor = kCGImagePropertyIPTCExtContributor as String
        @available(iOS 11.3, *)
        static let IPTCExtContributorIdentifier = kCGImagePropertyIPTCExtContributorIdentifier as String
        @available(iOS 11.3, *)
        static let IPTCExtContributorName = kCGImagePropertyIPTCExtContributorName as String
        @available(iOS 11.3, *)
        static let IPTCExtContributorRole = kCGImagePropertyIPTCExtContributorRole as String
        @available(iOS 11.3, *)
        static let IPTCExtCopyrightYear = kCGImagePropertyIPTCExtCopyrightYear as String
        @available(iOS 11.3, *)
        static let IPTCExtCreator = kCGImagePropertyIPTCExtCreator as String
        @available(iOS 11.3, *)
        static let IPTCExtCreatorIdentifier = kCGImagePropertyIPTCExtCreatorIdentifier as String
        @available(iOS 11.3, *)
        static let IPTCExtCreatorName = kCGImagePropertyIPTCExtCreatorName as String
        @available(iOS 11.3, *)
        static let IPTCExtCreatorRole = kCGImagePropertyIPTCExtCreatorRole as String
        @available(iOS 11.3, *)
        static let IPTCExtControlledVocabularyTerm = kCGImagePropertyIPTCExtControlledVocabularyTerm as String
        @available(iOS 11.3, *)
        static let IPTCExtDataOnScreen = kCGImagePropertyIPTCExtDataOnScreen as String
        @available(iOS 11.3, *)
        static let IPTCExtDataOnScreenRegion = kCGImagePropertyIPTCExtDataOnScreenRegion as String
        @available(iOS 11.3, *)
        static let IPTCExtDataOnScreenRegionD = kCGImagePropertyIPTCExtDataOnScreenRegionD as String
        @available(iOS 11.3, *)
        static let IPTCExtDataOnScreenRegionH = kCGImagePropertyIPTCExtDataOnScreenRegionH as String
        @available(iOS 11.3, *)
        static let IPTCExtDataOnScreenRegionText = kCGImagePropertyIPTCExtDataOnScreenRegionText as String
        @available(iOS 11.3, *)
        static let IPTCExtDataOnScreenRegionUnit = kCGImagePropertyIPTCExtDataOnScreenRegionUnit as String
        @available(iOS 11.3, *)
        static let IPTCExtDataOnScreenRegionW = kCGImagePropertyIPTCExtDataOnScreenRegionW as String
        @available(iOS 11.3, *)
        static let IPTCExtDataOnScreenRegionX = kCGImagePropertyIPTCExtDataOnScreenRegionX as String
        @available(iOS 11.3, *)
        static let IPTCExtDataOnScreenRegionY = kCGImagePropertyIPTCExtDataOnScreenRegionY as String
        @available(iOS 11.3, *)
        static let IPTCExtDigitalImageGUID = kCGImagePropertyIPTCExtDigitalImageGUID as String
        @available(iOS 11.3, *)
        static let IPTCExtDigitalSourceFileType = kCGImagePropertyIPTCExtDigitalSourceFileType as String
        @available(iOS 11.3, *)
        static let IPTCExtDigitalSourceType = kCGImagePropertyIPTCExtDigitalSourceType as String
        @available(iOS 11.3, *)
        static let IPTCExtDopesheet = kCGImagePropertyIPTCExtDopesheet as String
        @available(iOS 11.3, *)
        static let IPTCExtDopesheetLink = kCGImagePropertyIPTCExtDopesheetLink as String
        @available(iOS 11.3, *)
        static let IPTCExtDopesheetLinkLink = kCGImagePropertyIPTCExtDopesheetLinkLink as String
        @available(iOS 11.3, *)
        static let IPTCExtDopesheetLinkLinkQualifier = kCGImagePropertyIPTCExtDopesheetLinkLinkQualifier as String
        @available(iOS 11.3, *)
        static let IPTCExtEmbdEncRightsExpr = kCGImagePropertyIPTCExtEmbdEncRightsExpr as String
        @available(iOS 11.3, *)
        static let IPTCExtEmbeddedEncodedRightsExpr = kCGImagePropertyIPTCExtEmbeddedEncodedRightsExpr as String
        @available(iOS 11.3, *)
        static let IPTCExtEmbeddedEncodedRightsExprType = kCGImagePropertyIPTCExtEmbeddedEncodedRightsExprType as String
        @available(iOS 11.3, *)
        static let IPTCExtEmbeddedEncodedRightsExprLangID = kCGImagePropertyIPTCExtEmbeddedEncodedRightsExprLangID as String
        @available(iOS 11.3, *)
        static let IPTCExtEpisode = kCGImagePropertyIPTCExtEpisode as String
        @available(iOS 11.3, *)
        static let IPTCExtEpisodeIdentifier = kCGImagePropertyIPTCExtEpisodeIdentifier as String
        @available(iOS 11.3, *)
        static let IPTCExtEpisodeName = kCGImagePropertyIPTCExtEpisodeName as String
        @available(iOS 11.3, *)
        static let IPTCExtEpisodeNumber = kCGImagePropertyIPTCExtEpisodeNumber as String
        @available(iOS 11.3, *)
        static let IPTCExtEvent = kCGImagePropertyIPTCExtEvent as String
        @available(iOS 11.3, *)
        static let IPTCExtShownEvent = kCGImagePropertyIPTCExtShownEvent as String
        @available(iOS 11.3, *)
        static let IPTCExtShownEventIdentifier = kCGImagePropertyIPTCExtShownEventIdentifier as String
        @available(iOS 11.3, *)
        static let IPTCExtShownEventName = kCGImagePropertyIPTCExtShownEventName as String
        @available(iOS 11.3, *)
        static let IPTCExtExternalMetadataLink = kCGImagePropertyIPTCExtExternalMetadataLink as String
        @available(iOS 11.3, *)
        static let IPTCExtFeedIdentifier = kCGImagePropertyIPTCExtFeedIdentifier as String
        @available(iOS 11.3, *)
        static let IPTCExtGenre = kCGImagePropertyIPTCExtGenre as String
        @available(iOS 11.3, *)
        static let IPTCExtGenreCvId = kCGImagePropertyIPTCExtGenreCvId as String
        @available(iOS 11.3, *)
        static let IPTCExtGenreCvTermId = kCGImagePropertyIPTCExtGenreCvTermId as String
        @available(iOS 11.3, *)
        static let IPTCExtGenreCvTermName = kCGImagePropertyIPTCExtGenreCvTermName as String
        @available(iOS 11.3, *)
        static let IPTCExtGenreCvTermRefinedAbout = kCGImagePropertyIPTCExtGenreCvTermRefinedAbout as String
        @available(iOS 11.3, *)
        static let IPTCExtHeadline = kCGImagePropertyIPTCExtHeadline as String
        @available(iOS 11.3, *)
        static let IPTCExtIPTCLastEdited = kCGImagePropertyIPTCExtIPTCLastEdited as String
        @available(iOS 11.3, *)
        static let IPTCExtLinkedEncRightsExpr = kCGImagePropertyIPTCExtLinkedEncRightsExpr as String
        @available(iOS 11.3, *)
        static let IPTCExtLinkedEncodedRightsExpr = kCGImagePropertyIPTCExtLinkedEncodedRightsExpr as String
        @available(iOS 11.3, *)
        static let IPTCExtLinkedEncodedRightsExprType = kCGImagePropertyIPTCExtLinkedEncodedRightsExprType as String
        @available(iOS 11.3, *)
        static let IPTCExtLinkedEncodedRightsExprLangID = kCGImagePropertyIPTCExtLinkedEncodedRightsExprLangID as String
        @available(iOS 11.3, *)
        static let IPTCExtLocationCreated = kCGImagePropertyIPTCExtLocationCreated as String
        @available(iOS 11.3, *)
        static let IPTCExtLocationCity = kCGImagePropertyIPTCExtLocationCity as String
        @available(iOS 11.3, *)
        static let IPTCExtLocationCountryCode = kCGImagePropertyIPTCExtLocationCountryCode as String
        @available(iOS 11.3, *)
        static let IPTCExtLocationCountryName = kCGImagePropertyIPTCExtLocationCountryName as String
        @available(iOS 11.3, *)
        static let IPTCExtLocationGPSAltitude = kCGImagePropertyIPTCExtLocationGPSAltitude as String
        @available(iOS 11.3, *)
        static let IPTCExtLocationGPSLatitude = kCGImagePropertyIPTCExtLocationGPSLatitude as String
        @available(iOS 11.3, *)
        static let IPTCExtLocationGPSLongitude = kCGImagePropertyIPTCExtLocationGPSLongitude as String
        @available(iOS 11.3, *)
        static let IPTCExtLocationIdentifier = kCGImagePropertyIPTCExtLocationIdentifier as String
        @available(iOS 11.3, *)
        static let IPTCExtLocationLocationId = kCGImagePropertyIPTCExtLocationLocationId as String
        @available(iOS 11.3, *)
        static let IPTCExtLocationLocationName = kCGImagePropertyIPTCExtLocationLocationName as String
        @available(iOS 11.3, *)
        static let IPTCExtLocationProvinceState = kCGImagePropertyIPTCExtLocationProvinceState as String
        @available(iOS 11.3, *)
        static let IPTCExtLocationSublocation = kCGImagePropertyIPTCExtLocationSublocation as String
        @available(iOS 11.3, *)
        static let IPTCExtLocationWorldRegion = kCGImagePropertyIPTCExtLocationWorldRegion as String
        @available(iOS 11.3, *)
        static let IPTCExtLocationShown = kCGImagePropertyIPTCExtLocationShown as String
        @available(iOS 11.3, *)
        static let IPTCExtMaxAvailHeight = kCGImagePropertyIPTCExtMaxAvailHeight as String
        @available(iOS 11.3, *)
        static let IPTCExtMaxAvailWidth = kCGImagePropertyIPTCExtMaxAvailWidth as String
        @available(iOS 11.3, *)
        static let IPTCExtModelAge = kCGImagePropertyIPTCExtModelAge as String
        @available(iOS 11.3, *)
        static let IPTCExtOrganisationInImageCode = kCGImagePropertyIPTCExtOrganisationInImageCode as String
        @available(iOS 11.3, *)
        static let IPTCExtOrganisationInImageName = kCGImagePropertyIPTCExtOrganisationInImageName as String
        @available(iOS 11.3, *)
        static let IPTCExtPersonHeard = kCGImagePropertyIPTCExtPersonHeard as String
        @available(iOS 11.3, *)
        static let IPTCExtPersonHeardIdentifier = kCGImagePropertyIPTCExtPersonHeardIdentifier as String
        @available(iOS 11.3, *)
        static let IPTCExtPersonHeardName = kCGImagePropertyIPTCExtPersonHeardName as String
        @available(iOS 11.3, *)
        static let IPTCExtPersonInImage = kCGImagePropertyIPTCExtPersonInImage as String
        @available(iOS 11.3, *)
        static let IPTCExtPersonInImageWDetails = kCGImagePropertyIPTCExtPersonInImageWDetails as String
        @available(iOS 11.3, *)
        static let IPTCExtPersonInImageCharacteristic = kCGImagePropertyIPTCExtPersonInImageCharacteristic as String
        @available(iOS 11.3, *)
        static let IPTCExtPersonInImageCvTermCvId = kCGImagePropertyIPTCExtPersonInImageCvTermCvId as String
        @available(iOS 11.3, *)
        static let IPTCExtPersonInImageCvTermId = kCGImagePropertyIPTCExtPersonInImageCvTermId as String
        @available(iOS 11.3, *)
        static let IPTCExtPersonInImageCvTermName = kCGImagePropertyIPTCExtPersonInImageCvTermName as String
        @available(iOS 11.3, *)
        static let IPTCExtPersonInImageCvTermRefinedAbout = kCGImagePropertyIPTCExtPersonInImageCvTermRefinedAbout as String
        @available(iOS 11.3, *)
        static let IPTCExtPersonInImageDescription = kCGImagePropertyIPTCExtPersonInImageDescription as String
        @available(iOS 11.3, *)
        static let IPTCExtPersonInImageId = kCGImagePropertyIPTCExtPersonInImageId as String
        @available(iOS 11.3, *)
        static let IPTCExtPersonInImageName = kCGImagePropertyIPTCExtPersonInImageName as String
        @available(iOS 11.3, *)
        static let IPTCExtProductInImage = kCGImagePropertyIPTCExtProductInImage as String
        @available(iOS 11.3, *)
        static let IPTCExtProductInImageDescription = kCGImagePropertyIPTCExtProductInImageDescription as String
        @available(iOS 11.3, *)
        static let IPTCExtProductInImageGTIN = kCGImagePropertyIPTCExtProductInImageGTIN as String
        @available(iOS 11.3, *)
        static let IPTCExtProductInImageName = kCGImagePropertyIPTCExtProductInImageName as String
        @available(iOS 11.3, *)
        static let IPTCExtPublicationEvent = kCGImagePropertyIPTCExtPublicationEvent as String
        @available(iOS 11.3, *)
        static let IPTCExtPublicationEventDate = kCGImagePropertyIPTCExtPublicationEventDate as String
        @available(iOS 11.3, *)
        static let IPTCExtPublicationEventIdentifier = kCGImagePropertyIPTCExtPublicationEventIdentifier as String
        @available(iOS 11.3, *)
        static let IPTCExtPublicationEventName = kCGImagePropertyIPTCExtPublicationEventName as String
        @available(iOS 11.3, *)
        static let IPTCExtRating = kCGImagePropertyIPTCExtRating as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingRatingRegion = kCGImagePropertyIPTCExtRatingRatingRegion as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingRegionCity = kCGImagePropertyIPTCExtRatingRegionCity as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingRegionCountryCode = kCGImagePropertyIPTCExtRatingRegionCountryCode as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingRegionCountryName = kCGImagePropertyIPTCExtRatingRegionCountryName as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingRegionGPSAltitude = kCGImagePropertyIPTCExtRatingRegionGPSAltitude as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingRegionGPSLatitude = kCGImagePropertyIPTCExtRatingRegionGPSLatitude as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingRegionGPSLongitude = kCGImagePropertyIPTCExtRatingRegionGPSLongitude as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingRegionIdentifier = kCGImagePropertyIPTCExtRatingRegionIdentifier as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingRegionLocationId = kCGImagePropertyIPTCExtRatingRegionLocationId as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingRegionLocationName = kCGImagePropertyIPTCExtRatingRegionLocationName as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingRegionProvinceState = kCGImagePropertyIPTCExtRatingRegionProvinceState as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingRegionSublocation = kCGImagePropertyIPTCExtRatingRegionSublocation as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingRegionWorldRegion = kCGImagePropertyIPTCExtRatingRegionWorldRegion as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingScaleMaxValue = kCGImagePropertyIPTCExtRatingScaleMaxValue as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingScaleMinValue = kCGImagePropertyIPTCExtRatingScaleMinValue as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingSourceLink = kCGImagePropertyIPTCExtRatingSourceLink as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingValue = kCGImagePropertyIPTCExtRatingValue as String
        @available(iOS 11.3, *)
        static let IPTCExtRatingValueLogoLink = kCGImagePropertyIPTCExtRatingValueLogoLink as String
        @available(iOS 11.3, *)
        static let IPTCExtRegistryID = kCGImagePropertyIPTCExtRegistryID as String
        @available(iOS 11.3, *)
        static let IPTCExtRegistryEntryRole = kCGImagePropertyIPTCExtRegistryEntryRole as String
        @available(iOS 11.3, *)
        static let IPTCExtRegistryItemID = kCGImagePropertyIPTCExtRegistryItemID as String
        @available(iOS 11.3, *)
        static let IPTCExtRegistryOrganisationID = kCGImagePropertyIPTCExtRegistryOrganisationID as String
        @available(iOS 11.3, *)
        static let IPTCExtReleaseReady = kCGImagePropertyIPTCExtReleaseReady as String
        @available(iOS 11.3, *)
        static let IPTCExtSeason = kCGImagePropertyIPTCExtSeason as String
        @available(iOS 11.3, *)
        static let IPTCExtSeasonIdentifier = kCGImagePropertyIPTCExtSeasonIdentifier as String
        @available(iOS 11.3, *)
        static let IPTCExtSeasonName = kCGImagePropertyIPTCExtSeasonName as String
        @available(iOS 11.3, *)
        static let IPTCExtSeasonNumber = kCGImagePropertyIPTCExtSeasonNumber as String
        @available(iOS 11.3, *)
        static let IPTCExtSeries = kCGImagePropertyIPTCExtSeries as String
        @available(iOS 11.3, *)
        static let IPTCExtSeriesIdentifier = kCGImagePropertyIPTCExtSeriesIdentifier as String
        @available(iOS 11.3, *)
        static let IPTCExtSeriesName = kCGImagePropertyIPTCExtSeriesName as String
        @available(iOS 11.3, *)
        static let IPTCExtStorylineIdentifier = kCGImagePropertyIPTCExtStorylineIdentifier as String
        @available(iOS 11.3, *)
        static let IPTCExtStreamReady = kCGImagePropertyIPTCExtStreamReady as String
        @available(iOS 11.3, *)
        static let IPTCExtStylePeriod = kCGImagePropertyIPTCExtStylePeriod as String
        @available(iOS 11.3, *)
        static let IPTCExtSupplyChainSource = kCGImagePropertyIPTCExtSupplyChainSource as String
        @available(iOS 11.3, *)
        static let IPTCExtSupplyChainSourceIdentifier = kCGImagePropertyIPTCExtSupplyChainSourceIdentifier as String
        @available(iOS 11.3, *)
        static let IPTCExtSupplyChainSourceName = kCGImagePropertyIPTCExtSupplyChainSourceName as String
        @available(iOS 11.3, *)
        static let IPTCExtTemporalCoverage = kCGImagePropertyIPTCExtTemporalCoverage as String
        @available(iOS 11.3, *)
        static let IPTCExtTemporalCoverageFrom = kCGImagePropertyIPTCExtTemporalCoverageFrom as String
        @available(iOS 11.3, *)
        static let IPTCExtTemporalCoverageTo = kCGImagePropertyIPTCExtTemporalCoverageTo as String
        @available(iOS 11.3, *)
        static let IPTCExtTranscript = kCGImagePropertyIPTCExtTranscript as String
        @available(iOS 11.3, *)
        static let IPTCExtTranscriptLink = kCGImagePropertyIPTCExtTranscriptLink as String
        @available(iOS 11.3, *)
        static let IPTCExtTranscriptLinkLink = kCGImagePropertyIPTCExtTranscriptLinkLink as String
        @available(iOS 11.3, *)
        static let IPTCExtTranscriptLinkLinkQualifier = kCGImagePropertyIPTCExtTranscriptLinkLinkQualifier as String
        @available(iOS 11.3, *)
        static let IPTCExtVideoBitrate = kCGImagePropertyIPTCExtVideoBitrate as String
        @available(iOS 11.3, *)
        static let IPTCExtVideoBitrateMode = kCGImagePropertyIPTCExtVideoBitrateMode as String
        @available(iOS 11.3, *)
        static let IPTCExtVideoDisplayAspectRatio = kCGImagePropertyIPTCExtVideoDisplayAspectRatio as String
        @available(iOS 11.3, *)
        static let IPTCExtVideoEncodingProfile = kCGImagePropertyIPTCExtVideoEncodingProfile as String
        @available(iOS 11.3, *)
        static let IPTCExtVideoShotType = kCGImagePropertyIPTCExtVideoShotType as String
        @available(iOS 11.3, *)
        static let IPTCExtVideoShotTypeIdentifier = kCGImagePropertyIPTCExtVideoShotTypeIdentifier as String
        @available(iOS 11.3, *)
        static let IPTCExtVideoShotTypeName = kCGImagePropertyIPTCExtVideoShotTypeName as String
        @available(iOS 11.3, *)
        static let IPTCExtVideoStreamsCount = kCGImagePropertyIPTCExtVideoStreamsCount as String
        @available(iOS 11.3, *)
        static let IPTCExtVisualColor = kCGImagePropertyIPTCExtVisualColor as String
        @available(iOS 11.3, *)
        static let IPTCExtWorkflowTag = kCGImagePropertyIPTCExtWorkflowTag as String
        @available(iOS 11.3, *)
        static let IPTCExtWorkflowTagCvId = kCGImagePropertyIPTCExtWorkflowTagCvId as String
        @available(iOS 11.3, *)
        static let IPTCExtWorkflowTagCvTermId = kCGImagePropertyIPTCExtWorkflowTagCvTermId as String
        @available(iOS 11.3, *)
        static let IPTCExtWorkflowTagCvTermName = kCGImagePropertyIPTCExtWorkflowTagCvTermName as String
        @available(iOS 11.3, *)
        static let IPTCExtWorkflowTagCvTermRefinedAbout = kCGImagePropertyIPTCExtWorkflowTagCvTermRefinedAbout as String

/* Possible keys for kCGImagePropertyIPTCCreatorContactInfo dictionary (part of IPTC Core - above) */

        static let IPTCContactInfoCity = kCGImagePropertyIPTCContactInfoCity as String
        static let IPTCContactInfoCountry = kCGImagePropertyIPTCContactInfoCountry as String
        static let IPTCContactInfoAddress = kCGImagePropertyIPTCContactInfoAddress as String
        static let IPTCContactInfoPostalCode = kCGImagePropertyIPTCContactInfoPostalCode as String
        static let IPTCContactInfoStateProvince = kCGImagePropertyIPTCContactInfoStateProvince as String
        static let IPTCContactInfoEmails = kCGImagePropertyIPTCContactInfoEmails as String
        static let IPTCContactInfoPhones = kCGImagePropertyIPTCContactInfoPhones as String
        static let IPTCContactInfoWebURLs = kCGImagePropertyIPTCContactInfoWebURLs as String

/* Possible keys for kCGImageProperty8BIMDictionary */

        static let _8BIMLayerNames = kCGImageProperty8BIMLayerNames as String
        @available(iOS 8.0, *)
        static let _8BIMVersion = kCGImageProperty8BIMVersion as String

/* Possible keys for kCGImagePropertyDNGDictionary */

        static let DNGVersion = kCGImagePropertyDNGVersion as String
        static let DNGBackwardVersion = kCGImagePropertyDNGBackwardVersion as String
        static let DNGUniqueCameraModel = kCGImagePropertyDNGUniqueCameraModel as String
        static let DNGLocalizedCameraModel = kCGImagePropertyDNGLocalizedCameraModel as String
        static let DNGCameraSerialNumber = kCGImagePropertyDNGCameraSerialNumber as String
        static let DNGLensInfo = kCGImagePropertyDNGLensInfo as String
        @available(iOS 10.0, *)
        static let DNGBlackLevel = kCGImagePropertyDNGBlackLevel as String
        @available(iOS 10.0, *)
        static let DNGWhiteLevel = kCGImagePropertyDNGWhiteLevel as String
        @available(iOS 10.0, *)
        static let DNGCalibrationIlluminant1 = kCGImagePropertyDNGCalibrationIlluminant1 as String
        @available(iOS 10.0, *)
        static let DNGCalibrationIlluminant2 = kCGImagePropertyDNGCalibrationIlluminant2 as String
        @available(iOS 10.0, *)
        static let DNGColorMatrix1 = kCGImagePropertyDNGColorMatrix1 as String
        @available(iOS 10.0, *)
        static let DNGColorMatrix2 = kCGImagePropertyDNGColorMatrix2 as String
        @available(iOS 10.0, *)
        static let DNGCameraCalibration1 = kCGImagePropertyDNGCameraCalibration1 as String
        @available(iOS 10.0, *)
        static let DNGCameraCalibration2 = kCGImagePropertyDNGCameraCalibration2 as String
        @available(iOS 10.0, *)
        static let DNGAsShotNeutral = kCGImagePropertyDNGAsShotNeutral as String
        @available(iOS 10.0, *)
        static let DNGAsShotWhiteXY = kCGImagePropertyDNGAsShotWhiteXY as String
        @available(iOS 10.0, *)
        static let DNGBaselineExposure = kCGImagePropertyDNGBaselineExposure as String
        @available(iOS 10.0, *)
        static let DNGBaselineNoise = kCGImagePropertyDNGBaselineNoise as String
        @available(iOS 10.0, *)
        static let DNGBaselineSharpness = kCGImagePropertyDNGBaselineSharpness as String
        @available(iOS 10.0, *)
        static let DNGPrivateData = kCGImagePropertyDNGPrivateData as String
        @available(iOS 10.0, *)
        static let DNGCameraCalibrationSignature = kCGImagePropertyDNGCameraCalibrationSignature as String
        @available(iOS 10.0, *)
        static let DNGProfileCalibrationSignature = kCGImagePropertyDNGProfileCalibrationSignature as String
        @available(iOS 10.0, *)
        static let DNGNoiseProfile = kCGImagePropertyDNGNoiseProfile as String
        @available(iOS 10.0, *)
        static let DNGWarpRectilinear = kCGImagePropertyDNGWarpRectilinear as String
        @available(iOS 10.0, *)
        static let DNGWarpFisheye = kCGImagePropertyDNGWarpFisheye as String
        @available(iOS 10.0, *)
        static let DNGFixVignetteRadial = kCGImagePropertyDNGFixVignetteRadial as String

/* Possible keys for kCGImagePropertyCIFFDictionary */

        static let CIFFDescription = kCGImagePropertyCIFFDescription as String
        static let CIFFFirmware = kCGImagePropertyCIFFFirmware as String
        static let CIFFOwnerName = kCGImagePropertyCIFFOwnerName as String
        static let CIFFImageName = kCGImagePropertyCIFFImageName as String
        static let CIFFImageFileName = kCGImagePropertyCIFFImageFileName as String
        static let CIFFReleaseMethod = kCGImagePropertyCIFFReleaseMethod as String
        static let CIFFReleaseTiming = kCGImagePropertyCIFFReleaseTiming as String
        static let CIFFRecordID = kCGImagePropertyCIFFRecordID as String
        static let CIFFSelfTimingTime = kCGImagePropertyCIFFSelfTimingTime as String
        static let CIFFCameraSerialNumber = kCGImagePropertyCIFFCameraSerialNumber as String
        static let CIFFImageSerialNumber = kCGImagePropertyCIFFImageSerialNumber as String
        static let CIFFContinuousDrive = kCGImagePropertyCIFFContinuousDrive as String
        static let CIFFFocusMode = kCGImagePropertyCIFFFocusMode as String
        static let CIFFMeteringMode = kCGImagePropertyCIFFMeteringMode as String
        static let CIFFShootingMode = kCGImagePropertyCIFFShootingMode as String
        static let CIFFLensModel = kCGImagePropertyCIFFLensModel as String
        static let CIFFLensMaxMM = kCGImagePropertyCIFFLensMaxMM as String
        static let CIFFLensMinMM = kCGImagePropertyCIFFLensMinMM as String
        static let CIFFWhiteBalanceIndex = kCGImagePropertyCIFFWhiteBalanceIndex as String
        static let CIFFFlashExposureComp = kCGImagePropertyCIFFFlashExposureComp as String
        static let CIFFMeasuredEV = kCGImagePropertyCIFFMeasuredEV as String

/* Possible keys for kCGImagePropertyMakerNikonDictionary */

        static let MakerNikonISOSetting = kCGImagePropertyMakerNikonISOSetting as String
        static let MakerNikonColorMode = kCGImagePropertyMakerNikonColorMode as String
        static let MakerNikonQuality = kCGImagePropertyMakerNikonQuality as String
        static let MakerNikonWhiteBalanceMode = kCGImagePropertyMakerNikonWhiteBalanceMode as String
        static let MakerNikonSharpenMode = kCGImagePropertyMakerNikonSharpenMode as String
        static let MakerNikonFocusMode = kCGImagePropertyMakerNikonFocusMode as String
        static let MakerNikonFlashSetting = kCGImagePropertyMakerNikonFlashSetting as String
        static let MakerNikonISOSelection = kCGImagePropertyMakerNikonISOSelection as String
        static let MakerNikonFlashExposureComp = kCGImagePropertyMakerNikonFlashExposureComp as String
        static let MakerNikonImageAdjustment = kCGImagePropertyMakerNikonImageAdjustment as String
        static let MakerNikonLensAdapter = kCGImagePropertyMakerNikonLensAdapter as String
        static let MakerNikonLensType = kCGImagePropertyMakerNikonLensType as String
        static let MakerNikonLensInfo = kCGImagePropertyMakerNikonLensInfo as String
        static let MakerNikonFocusDistance = kCGImagePropertyMakerNikonFocusDistance as String
        static let MakerNikonDigitalZoom = kCGImagePropertyMakerNikonDigitalZoom as String
        static let MakerNikonShootingMode = kCGImagePropertyMakerNikonShootingMode as String
        static let MakerNikonCameraSerialNumber = kCGImagePropertyMakerNikonCameraSerialNumber as String
        static let MakerNikonShutterCount = kCGImagePropertyMakerNikonShutterCount as String

/* Possible keys for kCGImagePropertyMakerCanonDictionary */

        static let MakerCanonOwnerName = kCGImagePropertyMakerCanonOwnerName as String
        static let MakerCanonCameraSerialNumber = kCGImagePropertyMakerCanonCameraSerialNumber as String
        static let MakerCanonImageSerialNumber = kCGImagePropertyMakerCanonImageSerialNumber as String
        static let MakerCanonFlashExposureComp = kCGImagePropertyMakerCanonFlashExposureComp as String
        static let MakerCanonContinuousDrive = kCGImagePropertyMakerCanonContinuousDrive as String
        static let MakerCanonLensModel = kCGImagePropertyMakerCanonLensModel as String
        static let MakerCanonFirmware = kCGImagePropertyMakerCanonFirmware as String
        static let MakerCanonAspectRatioInfo = kCGImagePropertyMakerCanonAspectRatioInfo as String

/* Possible keys for kCGImagePropertyOpenEXRDictionary */

        @available(iOS 11.3, *)
        static let OpenEXRAspectRatio = kCGImagePropertyOpenEXRAspectRatio as String

/*
 * Allows client to choose the filters applied before PNG compression
 * http://www.libpng.org/pub/png/book/chapter09.html#png.ch09.div.1
 * The value should be a CFNumber, of type long, containing a bitwise OR of the desired filters
 * The filters are defined below, IMAGEIO_PNG_NO_FILTERS, IMAGEIO_PNG_FILTER_NONE, etc
 * This value has no effect when compressing to any format other than PNG
 */
        @available(iOS 9.0, *)
        static let PNGCompressionFilter = kCGImagePropertyPNGCompressionFilter as String

/* For use with CGImageSourceCopyAuxiliaryDataInfoAtIndex and CGImageDestinationAddAuxiliaryDataInfo:
 * These strings specify the 'auxiliaryImageDataType':
 */
        @available(iOS 11.0, *)
        static let AuxiliaryDataTypeDepth = kCGImageAuxiliaryDataTypeDepth  as String
        @available(iOS 11.0, *)
        static let AuxiliaryDataTypeDisparity = kCGImageAuxiliaryDataTypeDisparity  as String

/* Depth/Disparity data support for JPEG, HEIF, and DNG images:
 * CGImageSourceCopyAuxiliaryDataInfoAtIndex and CGImageDestinationAddAuxiliaryDataInfo will use these keys in the dictionary:
 * kCGImageAuxiliaryDataInfoData - the depth data (CFDataRef)
 * kCGImageAuxiliaryDataInfoDataDescription - the depth data description (CFDictionary)
 * kCGImageAuxiliaryDataInfoMetadata - metadata (CGImageMetadataRef)
 */
        @available(iOS 11.0, *)
        static let AuxiliaryDataInfoData = kCGImageAuxiliaryDataInfoData  as String
        @available(iOS 11.0, *)
        static let AuxiliaryDataInfoDataDescription = kCGImageAuxiliaryDataInfoDataDescription  as String
        @available(iOS 11.0, *)
        static let AuxiliaryDataInfoMetadata = kCGImageAuxiliaryDataInfoMetadata  as String

        @available(iOS 11.0, *)
        static let ImageCount = kCGImagePropertyImageCount as String
        @available(iOS 11.0, *)
        static let Width = kCGImagePropertyWidth as String
        @available(iOS 11.0, *)
        static let Height = kCGImagePropertyHeight as String
        @available(iOS 11.0, *)
        static let BytesPerRow = kCGImagePropertyBytesPerRow as String
        @available(iOS 11.0, *)
        static let NamedColorSpace = kCGImagePropertyNamedColorSpace as String
        @available(iOS 11.0, *)
        static let PixelFormat = kCGImagePropertyPixelFormat as String
        @available(iOS 11.0, *)
        static let Images = kCGImagePropertyImages as String
        @available(iOS 11.0, *)
        static let ThumbnailImages = kCGImagePropertyThumbnailImages as String
        @available(iOS 11.0, *)
        static let AuxiliaryData = kCGImagePropertyAuxiliaryData as String
        @available(iOS 11.0, *)
        static let AuxiliaryDataType = kCGImagePropertyAuxiliaryDataType as String
    }

    public struct PropertyApple {
        static let supportedDictionaries:[String] = [Dictionary.TIFF, Dictionary.Exif, Dictionary.GPS]

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
        static let GPS:[String] = [Property.GPSVersion,
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
                                   Property.GPSHPositioningError]


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
        static let EXIF:[String] = [Property.ExifExposureTime,
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
                                    Property.ExifGamma]

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
            , Property.TIFFTileLength]
    }


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
        static let GPS:[String:String] = [
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
        static let Exif:[String:String] = [
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


