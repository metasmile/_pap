//
// Created by BLACKGENE on 24/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit
import TPPDF
import Photos


protocol PDFactoryDefaults: AppDefaults{
    var formatPreset: String {get set}
    var landscape: Bool {get set}
    var imagesPerPage: Int {get set}
    var scaleMode: Int {get set}
    var metadataCaption: Bool {get set}
}

extension Defaults: PDFactoryDefaults {
    var formatPreset:String {
        set{ set(newValue) }
        get{ return get(or: PDFPageFormat.a4.label ) }
    }

    var landscape:Bool {
        set{ set(newValue) }
        get{ return get(or: false ) }
    }

    var imagesPerPage:Int {
        set{ set(newValue) }
        get{ return get(or: 1 ) }
    }

    var scaleMode:Int {
        set{ set(newValue) }
        get{ return get(or: PDFScaleMode.fitPage ) }
    }

    var metadataCaption:Bool {
        set{ set(newValue) }
        get{ return get(or: false ) }
    }
}


struct PDFScaleMode{
    static let fitPage = 0
    static let fillPage = 1
}

enum PDFDocumentDPI{
    case dpi72
    case dpi300
}

struct PDFactorySettings{

    static let FormatPresetFitToPhotoSize = "Fit To Photo Size"

    static let FormatPresets:[String:PDFPageFormat] = [
        PDFPageFormat.a3.label: PDFPageFormat.a3
        , PDFPageFormat.a4.label: PDFPageFormat.a4
        , PDFPageFormat.a5.label: PDFPageFormat.a5
        , PDFPageFormat.a6.label: PDFPageFormat.a6

        , PDFPageFormat.b3.label: PDFPageFormat.b3
        , PDFPageFormat.b4.label: PDFPageFormat.b4

        , PDFPageFormat.b5.label: PDFPageFormat.b5
        , PDFPageFormat.c5.label: PDFPageFormat.c5

        , PDFPageFormat.usLegal.label: PDFPageFormat.usLegal
        , PDFPageFormat.usLetter.label: PDFPageFormat.usLetter
        , PDFPageFormat.usHalfLetter.label: PDFPageFormat.usHalfLetter
        , PDFPageFormat.usLedger.label: PDFPageFormat.usLedger

        , FormatPresetFitToPhotoSize : PDFPageFormat.a4
    ]
}

extension PDFactory{
    class var defaultsPDFFormat:PDFPageFormat{
        if let defaults = PDFactory.defaults as? PDFactoryDefaults
        , let format = PDFactorySettings.FormatPresets[defaults.formatPreset] {
            return format
        }else{
            return PDFPageFormat.a4
        }
    }

    class var defaultsPDFLayout:PDFPageLayout{
        var defaultLayout:PDFPageLayout = defaultsPDFFormat.layout
        if let defaults = PDFactory.defaults as? PDFactoryDefaults, defaults.landscape {
            defaultLayout.size = CGSize(width: defaultLayout.size.height, height: defaultLayout.size.width)
        }
        return defaultLayout
    }
}
