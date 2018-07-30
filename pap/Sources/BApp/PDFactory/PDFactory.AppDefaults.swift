//
// Created by BLACKGENE on 24/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit
import TPPDF
import Photos


protocol PDFactoryAppDefaults: AppDefaults{
    var sizePreset: String {get set}
    var landscape: Bool {get set}
    var imagesPerPage: Int {get set}
    var scaleMode: Int {get set}
    var metadataCaption: Bool {get set}
    var imageQuality: Double {get set} // 0 - 1
    var margin: Int {get set} // 0 - 100 %
}

extension Defaults: PDFactoryAppDefaults {
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
        get{ return get(or: PDFactoryAppSettings.ScaleMode.fitPage.rawValue ) }
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

struct PDFactoryAppSettings{
    enum ScaleMode:Int {
        case fitPage
        case fillPage

        static let Labels = [
            "Images".localized: PDFactoryAppSettings.ScaleMode.fitPage.rawValue
            , "Pages".localized: PDFactoryAppSettings.ScaleMode.fillPage.rawValue
        ]
    }

    enum DPI {
        case dpi72
        case dpi300
    }

    static let SizePresetFitToPhotoSize = "Fit To Photo Size"

    static let SizePresets:[String:PDFPageFormat] = [
        PDFPageFormat.a4.label: PDFPageFormat.a4
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

extension PDFactoryApp{
    class var defaultsPDFFormat:PDFPageFormat{
        let defaults = PDFactoryApp.defaults as! PDFactoryAppDefaults
        if let format = PDFactoryAppSettings.SizePresets[defaults.sizePreset] {
            return format
        }else{
            return PDFPageFormat.a4
        }
    }

    class var defaultsPDFLayout:PDFPageLayout{
        var defaultLayout:PDFPageLayout = defaultsPDFFormat.layout
        let defaults = PDFactoryApp.defaults as! PDFactoryAppDefaults

        // swap width and height
        if defaults.landscape{
            defaultLayout.size = CGSize(width: defaultLayout.size.height, height: defaultLayout.size.width)
        }

        // if ScaleMode is fillPage, margin will be ignored.
        if defaults.scaleMode == PDFactoryAppSettings.ScaleMode.fillPage.rawValue{
            defaultLayout.margin = .zero
        }else{
            let horizontalMargin = defaultLayout.size.width/2 * CGFloat(defaults.margin)/100
            let verticalMargin = defaultLayout.size.height/2 * CGFloat(defaults.margin)/100
            defaultLayout.margin = UIEdgeInsets(top: verticalMargin, left: horizontalMargin, bottom: verticalMargin, right: horizontalMargin)
        }

        return defaultLayout
    }
}
