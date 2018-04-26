//
// Created by BLACKGENE on 24/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit
import TPPDF
import Photos


protocol PDFactoryDefaults: AppDefaults{
    var sizePreset: String {get set}
    var landscape: Bool {get set}
    var imagesPerPage: Int {get set}
    var scaleMode: Int {get set}
    var metadataCaption: Bool {get set}
    var imageQuality: Double {get set} // 0 - 1
    var margin: Int {get set} // 0 - 100 %
}

extension Defaults: PDFactoryDefaults {
    var sizePreset:String {
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
        get{ return get(or: PDFactorySettings.ScaleMode.fitPage ) }
    }

    var metadataCaption:Bool {
        set{ set(newValue) }
        get{ return get(or: false ) }
    }

    var imageQuality:Double {
        set{ set(newValue) }
        get{ return get(or: 1 ) }
    }

    var margin:Int {
        set{ set(newValue) }
        get{ return get(or: 15 ) }
    }
}

struct PDFactorySettings{
    enum ScaleMode {
        static let fitPage = 0
        static let fillPage = 1

        static let Labels = [
            "Entire Image": PDFactorySettings.ScaleMode.fitPage
            , "Fill Page": PDFactorySettings.ScaleMode.fillPage
        ]
    }

    enum DPI {
        case dpi72
        case dpi300
    }

    static let SizePresetFitToPhotoSize = "Fit To Photo Size"

    static let SizePresets:[String:PDFPageFormat] = [
        SizePresetFitToPhotoSize: PDFPageFormat.a4

        , PDFPageFormat.a4.label: PDFPageFormat.a4
        , PDFPageFormat.a3.label: PDFPageFormat.a3
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
    ]
}

extension PDFactory{
    class var defaultsPDFFormat:PDFPageFormat{
        if let defaults = PDFactory.defaults as? PDFactoryDefaults
        , let format = PDFactorySettings.SizePresets[defaults.sizePreset] {
            return format
        }else{
            return PDFPageFormat.a4
        }
    }

    class var defaultsPDFLayout:PDFPageLayout{
        var defaultLayout:PDFPageLayout = defaultsPDFFormat.layout
        if let defaults = PDFactory.defaults as? PDFactoryDefaults {

            if defaults.landscape{
                defaultLayout.size = CGSize(width: defaultLayout.size.height, height: defaultLayout.size.width)
            }

            print(defaults.margin)
            let horizontalMargin = defaultLayout.size.width/2 * CGFloat(defaults.margin)/100
            let verticalMargin = defaultLayout.size.height/2 * CGFloat(defaults.margin)/100

            defaultLayout.margin = UIEdgeInsets(top: verticalMargin, left: horizontalMargin, bottom: verticalMargin, right: horizontalMargin)

        }
        return defaultLayout
    }
}
