//
// Created by BLACKGENE on 23/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import TPPDF

extension PDFPageFormat{

    var label:String{
        switch self {
        case .usHalfLetter, .usLetter, .usLegal, .usJuniorLegal, .usLedger:
            return usLabel
        case .ansiA, .ansiB, .ansiC, .ansiD, .ansiE:
            return ansiLabel
        case .a0, .a1, .a2, .a3, .a4, .a5, .a6, .a7, .a8, .a9, .a10:
            return aLabel
        case .b0, .b1, .b2, .b3, .b4, .b5, .b6, .b7, .b8, .b9, .b10:
            return bLabel
        case .c0, .c1, .c2, .c3, .c4, .c5, .c6, .c7, .c8, .c9, .c10:
            return cLabel
        }
    }

    var defaultLabel:String{
        let dpi:CGFloat = 72
        return "\(self.layout.size.width/dpi) x \(self.layout.size.height/dpi) (inch, 72 DPI)"
    }

    /**
    Returns the defined US paper label if this format is a US format.
    If it is not a US format, it will check other constants for correct size
    */
    var usLabel: String {
        switch self {
        case .usHalfLetter:
            return "US Half Letter"   // 140  x 216  mm | 5.5  x 8.5  in
        case .usLetter:
            return "US Letter"   // 216  x 279  mm | 8.5  x 11.0 in
        case .usLegal:
            return "US Legal"  // 216  x 356  mm | 8.5  x 14.0 in
        case .usJuniorLegal:
            return "US Junior Legal"   // 127  x 203  mm | 5.0  x 8.0  in
        case .usLedger:
            return "US Ledger"  // 279  x 432  mm | 11.0 x 17.0 in
        default:
            return defaultLabel
        }
    }

    /**
     Returns the defined ANSI paper size if this format is a ANSI format.
     If it is not a ANSI format, it will check other constants for correct size
     */
    var ansiLabel: String {
        switch self {
        case .ansiA:
            return "ANSI A"   // 216  x 279  mm | 8.5  x 11.0 in
        case .ansiB:
            return "ANSI B" // 279  x 432  mm | 11.0 x 17.0 in
        case .ansiC:
            return "ANSI C" // 432  x 559  mm | 17.0 x 22.0 in
        case .ansiD:
            return "ANSI D" // 559  x 864  mm | 22.0 x 34.0 in
        case .ansiE:
            return "ANSI E" // 864  x 1118 mm | 34.0 x 44.0 in
        default:
            return defaultLabel
        }
    }

    /**
     Returns the defined A-Series paper label if this format is a A-Series format.
     If it is not a A-Series format, it will check other constants for correct size
     */
    var aLabel: String {
        switch self {
        case .a0:
            return "A0" // 841  x 1189 mm | 33.1 x 46.8 in
        case .a1:
            return "A1" // 594  x 841  mm | 23.4 x 33.1 in
        case .a2:
            return "A2" // 420  x 594  mm | 16.5 x 23.4 in
        case .a3:
            return "A3"  // 297  x 420  mm | 11.7 x 16.5 in
        case .a4:
            return "A4"   // 210  x 297  mm | 8.3  x 11.7 in
        case .a5:
            return "A5"   // 148  x 210  mm | 5.8  x 8.3  in
        case .a6:
            return "A6"   // 105  x 148  mm | 4.1  x 5.8  in
        case .a7:
            return "A7"   // 74   x 105  mm | 2.9  x 4.1  in
        case .a8:
            return "A8"   // 52   x 74   mm | 2.0  x 2.9  in
        case .a9:
            return "A9"   // 37   x 52   mm | 1.5  x 2.0  in
        case .a10:
            return "A10"    // 26   x 37   mm | 1.0  x 1.5  in
        default:
            return defaultLabel
        }
    }

    /**
     Returns the defined B-Series paper label if this format is a B-Series format.
     If it is not a B-Series format, it will check other constants for correct size
     */
    var bLabel: String {
        switch self {
        case .b0:
            return "B0" // 1000 x 1414 mm | 39.4 x 66.7 in
        case .b1:
            return "B1" // 707  x 1000 mm | 27.8 x 39.4 in
        case .b2:
            return "B2" // 500  x 707  mm | 19.7 x 27.8 in
        case .b3:
            return "B3" // 353  x 500  mm | 13.9 x 19.7 in
        case .b4:
            return "B4"  // 250  x 353  mm | 9.8  x 13.9 in
        case .b5:
            return "B5"   // 176  x 250  mm | 6.9  x 9.8  in
        case .b6:
            return "B6"   // 125  x 176  mm | 4.9  x 6.9  in
        case .b7:
            return "B7"   // 88   x 125  mm | 3.5  x 4.9  in
        case .b8:
            return "B8"   // 62   x 88   mm | 2.4  x 3.5  in
        case .b9:
            return "B9"   // 44   x 62   mm | 1.7  x 2.4  in
        case .b10:
            return "B10"    // 31   x 44   mm | 1.2  x 1.7  in
        default:
            return defaultLabel
        }
    }

    /**
     Returns the defined C-Series paper label if this format is a C-Series format.
     If it is not a C-Series format, it will check other constants for correct size
     */
    var cLabel: String {
        switch self {
        case .c0:
            return "C0" // 917  x 1297 mm | 36.1 x 51.5 in
        case .c1:
            return "C1" // 648  x 917  mm | 25.5 x 36.1 in
        case .c2:
            return "C2" // 458  x 648  mm | 18.0 x 25.5 in
        case .c3:
            return "C3"  // 324  x 458  mm | 12.8 x 18.0 in
        case .c4:
            return "C4"   // 229  x 324  mm | 9.0  x 12.8 in
        case .c5:
            return "C5"   // 162  x 229  mm | 6.4  x 9.0  in
        case .c6:
            return "C6"   // 114  x 162  mm | 4.5  x 6.4  in
        case .c7:
            return "C7"   // 81   x 114  mm | 3.2  x 4.5  in
        case .c8:
            return "C8"   // 57   x 81   mm | 2.2  x 3.2  in
        case .c9:
            return "C9"   // 40   x 57   mm | 1.6  x 2.2  in
        case .c10:
            return "C10"    // 28   x 40   mm | 1.1  x 1.6  in
        default:
            return defaultLabel
        }
    }
}