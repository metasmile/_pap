//
//  CodeKit.Data.swift
//  pap
//
//  Created by HYOJIN MO on 02/11/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import UIKit
import CoreServices

// https://github.com/sendyhalim/Swime
private struct MimeType {
    public let mime: String
    fileprivate let bytesCount: Int
    fileprivate let matches: ([UInt8], Data) -> Bool
    
    public func matches(bytes: [UInt8], data: Data) -> Bool {
        return bytes.count >= bytesCount && matches(bytes, data)
    }
    
    public static let all: [MimeType] = [
        MimeType(
            mime: "image/jpeg",
            bytesCount: 3,
            matches: { bytes, data in
                return bytes[0...2] == [0xFF, 0xD8, 0xFF]
            }
        ),
        MimeType(
            mime: "image/png",
            bytesCount: 4,
            matches: { bytes, data in
                return bytes[0...3] == [0x89, 0x50, 0x4E, 0x47]
            }
        ),
        MimeType(
            mime: "image/gif",
            bytesCount: 3,
            matches: { bytes, data in
                return bytes[0...2] == [0x47, 0x49, 0x46]
            }
        ),
        MimeType(
            mime: "image/webp",
            bytesCount: 12,
            matches: { bytes, data in
                return bytes[8...11] == [0x57, 0x45, 0x42, 0x50]
            }
        ),
        MimeType(
            mime: "image/flif",
            bytesCount: 4,
            matches: { bytes, data in
                return bytes[0...3] == [0x46, 0x4C, 0x49, 0x46]
            }
        ),
        MimeType(
            mime: "image/x-canon-cr2",
            bytesCount: 10,
            matches: { bytes, data in
                return (bytes[0...3] == [0x49, 0x49, 0x2A, 0x00] || bytes[0...3] == [0x4D, 0x4D, 0x00, 0x2A]) &&
                    (bytes[8...9] == [0x43, 0x52])
            }
        ),
        MimeType(
            mime: "image/tiff",
            bytesCount: 4,
            matches: { bytes, data in
                return (bytes[0...3] == [0x49, 0x49, 0x2A, 0x00]) ||
                    (bytes[0...3] == [0x4D, 0x4D, 0x20, 0x2A])
            }
        ),
        MimeType(
            mime: "image/bmp",
            bytesCount: 2,
            matches: { bytes, data in
                return bytes[0...1] == [0x42, 0x4D]
            }
        ),
        MimeType(
            mime: "image/vnd.ms-photo",
            bytesCount: 3,
            matches: { bytes, data in
                return bytes[0...2] == [0x49, 0x49, 0xBC]
            }
        ),
        MimeType(
            mime: "image/vnd.adobe.photoshop",
            bytesCount: 4,
            matches: { bytes, data in
                return bytes[0...3] == [0x38, 0x42, 0x50, 0x53]
            }
        ),
        MimeType(
            mime: "application/epub+zip",
            bytesCount: 58,
            matches: { bytes, data in
                return (bytes[0...3] == [0x50, 0x4B, 0x03, 0x04]) &&
                    (bytes[30...57] == [
                        0x6D, 0x69, 0x6D, 0x65, 0x74, 0x79, 0x70, 0x65, 0x61, 0x70, 0x70, 0x6C,
                        0x69, 0x63, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x2F, 0x65, 0x70, 0x75, 0x62,
                        0x2B, 0x7A, 0x69, 0x70
                        ])
        }
        ),
        
            // Needs to be before `zip` check
        // assumes signed .xpi from addons.mozilla.org
        MimeType(
            mime: "application/x-xpinstall",
            bytesCount: 50,
            matches: { bytes, data in
                return (bytes[0...3] == [0x50, 0x4B, 0x03, 0x04]) &&
                    (bytes[30...49] == [
                        0x4D, 0x45, 0x54, 0x41, 0x2D, 0x49, 0x4E, 0x46, 0x2F, 0x6D, 0x6F, 0x7A,
                        0x69, 0x6C, 0x6C, 0x61, 0x2E, 0x72, 0x73, 0x61
                        ])
            }
        ),
        MimeType(
            mime: "application/zip",
            bytesCount: 50,
            matches: { bytes, data in
                return (bytes[0...1] == [0x50, 0x4B]) &&
                    (bytes[2] == 0x3 || bytes[2] == 0x5 || bytes[2] == 0x7) &&
                    (bytes[3] == 0x4 || bytes[3] == 0x6 || bytes[3] == 0x8)
            }
        ),
        MimeType(
            mime: "application/x-tar",
            bytesCount: 262,
            matches: { bytes, data in
                return bytes[257...261] == [0x75, 0x73, 0x74, 0x61, 0x72]
            }
        ),
        MimeType(
            mime: "application/x-rar-compressed",
            bytesCount: 7,
            matches: { bytes, data in
                return (bytes[0...5] == [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07]) &&
                    (bytes[6] == 0x0 || bytes[6] == 0x1)
            }
        ),
        MimeType(
            mime: "application/gzip",
            bytesCount: 3,
            matches: { bytes, data in
                return bytes[0...2] == [0x1F, 0x8B, 0x08]
            }
        ),
        MimeType(
            mime: "application/x-bzip2",
            bytesCount: 3,
            matches: { bytes, data in
                return bytes[0...2] == [0x42, 0x5A, 0x68]
            }
        ),
        MimeType(
            mime: "application/x-7z-compressed",
            bytesCount: 6,
            matches: { bytes, data in
                return bytes[0...5] == [0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C]
            }
        ),
        MimeType(
            mime: "application/x-apple-diskimage",
            bytesCount: 2,
            matches: { bytes, data in
                return bytes[0...1] == [0x78, 0x01]
            }
        ),
        MimeType(
            mime: "video/mp4",
            bytesCount: 28,
            matches: { bytes, data in
                return (bytes[0...2] == [0x00, 0x00, 0x00] && (bytes[3] == 0x18 || bytes[3] == 0x20) && bytes[4...7] == [0x66, 0x74, 0x79, 0x70]) ||
                    (bytes[0...3] == [0x33, 0x67, 0x70, 0x35]) ||
                    (bytes[0...11] == [0x00, 0x00, 0x00, 0x1C, 0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x32] &&
                        bytes[16...27] == [0x6D, 0x70, 0x34, 0x31, 0x6D, 0x70, 0x34, 0x32, 0x69, 0x73, 0x6F, 0x6D]) ||
                    (bytes[0...11] == [0x00, 0x00, 0x00, 0x1C, 0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6F, 0x6D]) ||
                    (bytes[0...11] == [0x00, 0x00, 0x00, 0x1C, 0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x32, 0x00, 0x00, 0x00, 0x00])
            }
        ),
        MimeType(
            mime: "video/x-m4v",
            bytesCount: 11,
            matches: { bytes, data in
                return bytes[0...10] == [0x00, 0x00, 0x00, 0x1C, 0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x56]
            }
        ),
        MimeType(
            mime: "audio/midi",
            bytesCount: 4,
            matches: { bytes, data in
                return bytes[0...3] == [0x4D, 0x54, 0x68, 0x64]
            }
        ),
        MimeType(
            mime: "video/x-matroska",
            bytesCount: 4,
            matches: { bytes, data in
                guard bytes[0...3] == [0x1A, 0x45, 0xDF, 0xA3] else {
                    return false
                }
                
                let _bytes = Array(data.readBytes(count: 4100)[4 ..< 4100])
                var idPos = -1
                
                for i in 0 ..< (_bytes.count - 1) {
                    if _bytes[i] == 0x42 && _bytes[i + 1] == 0x82 {
                        idPos = i
                        break;
                    }
                }
                
                guard idPos > -1 else {
                    return false
                }
                
                let docTypePos = idPos + 3
                let findDocType: (String) -> Bool = { type in
                    for i in 0 ..< type.count {
                        let index = type.index(type.startIndex, offsetBy: i)
                        let scalars = String(type[index]).unicodeScalars
                        
                        if _bytes[docTypePos + i] != UInt8(scalars[scalars.startIndex].value) {
                            return false
                        }
                    }
                    
                    return true
                }
                
                return findDocType("matroska")
            }
        ),
        MimeType(
            mime: "video/webm",
            bytesCount: 4,
            matches: { bytes, data in
                guard bytes[0...3] == [0x1A, 0x45, 0xDF, 0xA3] else {
                    return false
                }
                
                let _bytes = Array(data.readBytes(count: 4100)[4 ..< 4100])
                var idPos = -1
                
                for i in 0 ..< (_bytes.count - 1) {
                    if _bytes[i] == 0x42 && _bytes[i + 1] == 0x82 {
                        idPos = i
                        break;
                    }
                }
                
                guard idPos > -1 else {
                    return false
                }
                
                let docTypePos = idPos + 3
                let findDocType: (String) -> Bool = { type in
                    for i in 0 ..< type.count {
                        let index = type.index(type.startIndex, offsetBy: i)
                        let scalars = String(type[index]).unicodeScalars
                        
                        if _bytes[docTypePos + i] != UInt8(scalars[scalars.startIndex].value) {
                            return false
                        }
                    }
                    
                    return true
                }
                
                return findDocType("webm")
            }
        ),
        MimeType(
            mime: "video/quicktime",
            bytesCount: 8,
            matches: { bytes, data in
                return bytes[0...7] == [0x00, 0x00, 0x00, 0x14, 0x66, 0x74, 0x79, 0x70]
            }
        ),
        MimeType(
            mime: "video/x-msvideo",
            bytesCount: 11,
            matches: { bytes, data in
                return (bytes[0...3] == [0x52, 0x49, 0x46, 0x46]) &&
                    (bytes[8...10] == [0x41, 0x56, 0x49])
            }
        ),
        MimeType(
            mime: "video/x-ms-wmv",
            bytesCount: 10,
            matches: { bytes, data in
                return bytes[0...9] == [0x30, 0x26, 0xB2, 0x75, 0x8E, 0x66, 0xCF, 0x11, 0xA6, 0xD9]
            }
        ),
        MimeType(
            mime: "video/mpeg",
            bytesCount: 4,
            matches: { bytes, data in
                guard bytes[0...2] == [0x00, 0x00, 0x01]  else {
                    return false
                }
                
                let hexCode = String(format: "%2X", bytes[3])
                
                if let firstHexCode = hexCode.first, firstHexCode == "B" {
                    return true
                }
                return false
            }
        ),
        MimeType(
            mime: "audio/mpeg",
            bytesCount: 3,
            matches: { bytes, data in
                return (bytes[0...2] == [0x49, 0x44, 0x33]) ||
                    (bytes[0...1] == [0xFF, 0xFB])
            }
        ),
        MimeType(
            mime: "audio/m4a",
            bytesCount: 11,
            matches: { bytes, data in
                return (bytes[0...3] == [0x4D, 0x34, 0x41, 0x20]) ||
                    (bytes[4...10] == [0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x41])
        }
        ),
        
        // Needs to be before `ogg` check
        MimeType(
            mime: "audio/opus",
            bytesCount: 36,
            matches: { bytes, data in
                return bytes[28...35] == [0x4F, 0x70, 0x75, 0x73, 0x48, 0x65, 0x61, 0x64]
            }
        ),
        MimeType(
            mime: "audio/ogg",
            bytesCount: 4,
            matches: { bytes, data in
                return bytes[0...3] == [0x4F, 0x67, 0x67, 0x53]
            }
        ),
        MimeType(
            mime: "audio/x-flac",
            bytesCount: 4,
            matches: { bytes, data in
                return bytes[0...3] == [0x66, 0x4C, 0x61, 0x43]
            }
        ),
        MimeType(
            mime: "audio/x-wav",
            bytesCount: 12,
            matches: { bytes, data in
                return (bytes[0...3] == [0x52, 0x49, 0x46, 0x46]) &&
                    (bytes[8...11] == [0x57, 0x41, 0x56, 0x45])
            }
        ),
        MimeType(
            mime: "audio/amr",
            bytesCount: 6,
            matches: { bytes, data in
                return bytes[0...5] == [0x23, 0x21, 0x41, 0x4D, 0x52, 0x0A]
            }
        ),
        MimeType(
            mime: "application/pdf",
            bytesCount: 4,
            matches: { bytes, data in
                return bytes[0...3] == [0x25, 0x50, 0x44, 0x46]
            }
        ),
        MimeType(
            mime: "application/x-msdownload",
            bytesCount: 2,
            matches: { bytes, data in
                return bytes[0...1] == [0x4D, 0x5A]
            }
        ),
        MimeType(
            mime: "application/x-shockwave-flash",
            bytesCount: 3,
            matches: { bytes, data in
                return (bytes[0] == 0x43 || bytes[0] == 0x46) && (bytes[1...2] == [0x57, 0x53])
            }
        ),
        MimeType(
            mime: "application/rtf",
            bytesCount: 5,
            matches: { bytes, data in
                return bytes[0...4] == [0x7B, 0x5C, 0x72, 0x74, 0x66]
            }
        ),
        MimeType(
            mime: "application/font-woff",
            bytesCount: 8,
            matches: { bytes, data in
                return (bytes[0...3] == [0x77, 0x4F, 0x46, 0x46]) &&
                    ((bytes[4...7] == [0x00, 0x01, 0x00, 0x00]) || (bytes[4...7] == [0x4F, 0x54, 0x54, 0x4F]))
            }
        ),
        MimeType(
            mime: "application/font-woff",
            bytesCount: 8,
            matches: { bytes, data in
                return (bytes[0...3] == [0x77, 0x4F, 0x46,  0x32]) &&
                    ((bytes[4...7] == [0x00, 0x01, 0x00, 0x00]) || (bytes[4...7] == [0x4F, 0x54, 0x54, 0x4F]))
            }
        ),
        MimeType(
            mime: "application/octet-stream",
            bytesCount: 11,
            matches: { bytes, data in
                return (bytes[34...35] == [0x4C, 0x50]) &&
                    ((bytes[8...10] == [0x00, 0x00, 0x01]) || (bytes[8...10] == [0x01, 0x00, 0x02]) || (bytes[8...10] == [0x02, 0x00, 0x02]))
            }
        ),
        MimeType(
            mime: "application/font-sfnt",
            bytesCount: 5,
            matches: { bytes, data in
                return bytes[0...4] == [0x00, 0x01, 0x00, 0x00, 0x00]
            }
        ),
        MimeType(
            mime: "application/font-sfnt",
            bytesCount: 5,
            matches: { bytes, data in
                return bytes[0...4] == [0x4F, 0x54, 0x54, 0x4F, 0x00]
            }
        ),
        MimeType(
            mime: "image/x-icon",
            bytesCount: 4,
            matches: { bytes, data in
                return bytes[0...3] == [0x00, 0x00, 0x01, 0x00]
            }
        ),
        MimeType(
            mime: "video/x-flv",
            bytesCount: 4,
            matches: { bytes, data in
                return bytes[0...3] == [0x46, 0x4C, 0x56, 0x01]
            }
        ),
        MimeType(
            mime: "application/postscript",
            bytesCount: 2,
            matches: { bytes, data in
                return bytes[0...1] == [0x25, 0x21]
            }
        ),
        MimeType(
            mime: "application/x-xz",
            bytesCount: 6,
            matches: { bytes, data in
                return bytes[0...5] == [0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00]
            }
        ),
        MimeType(
            mime: "application/x-sqlite3",
            bytesCount: 4,
            matches: { bytes, data in
                return bytes[0...3] == [0x53, 0x51, 0x4C, 0x69]
            }
        ),
        MimeType(
            mime: "application/x-nintendo-nes-rom",
            bytesCount: 4,
            matches: { bytes, data in
                return bytes[0...3] == [0x4E, 0x45, 0x53, 0x1A]
            }
        ),
        MimeType(
            mime: "application/x-google-chrome-extension",
            bytesCount: 4,
            matches: { bytes, data in
                return bytes[0...3] == [0x43, 0x72, 0x32, 0x34]
            }
        ),
        MimeType(
            mime: "application/vnd.ms-cab-compressed",
            bytesCount: 4,
            matches: { bytes, data in
                return (bytes[0...3] == [0x4D, 0x53, 0x43, 0x46]) || (bytes[0...3] == [0x49, 0x53, 0x63, 0x28])
        }
        ),
        
        // Needs to be before `ar` check
        MimeType(
            mime: "application/x-deb",
            bytesCount: 21,
            matches: { bytes, data in
                return bytes[0...20] == [
                    0x21, 0x3C, 0x61, 0x72, 0x63, 0x68, 0x3E, 0x0A, 0x64, 0x65, 0x62, 0x69,
                    0x61, 0x6E, 0x2D, 0x62, 0x69, 0x6E, 0x61, 0x72, 0x79
                ]
            }
        ),
        MimeType(
            mime: "application/x-unix-archive",
            bytesCount: 7,
            matches: { bytes, data in
                return bytes[0...6] == [0x21, 0x3C, 0x61, 0x72, 0x63, 0x68, 0x3E]
            }
        ),
        MimeType(
            mime: "application/x-rpm",
            bytesCount: 4,
            matches: { bytes, data in
                return bytes[0...3] == [0xED, 0xAB, 0xEE, 0xDB]
            }
        ),
        MimeType(
            mime: "application/x-compress",
            bytesCount: 2,
            matches: { bytes, data in
                return (bytes[0...1] == [0x1F, 0xA0]) || (bytes[0...1] == [0x1F, 0x9D])
            }
        ),
        MimeType(
            mime: "application/x-lzip",
            bytesCount: 4,
            matches: { bytes, data in
                return bytes[0...3] == [0x4C, 0x5A, 0x49, 0x50]
            }
        ),
        MimeType(
            mime: "application/x-msi",
            bytesCount: 8,
            matches: { bytes, data in
                return bytes[0...7] == [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1]
            }
        ),
        MimeType(
            mime: "application/mxf",
            bytesCount: 14,
            matches: { bytes, data in
                return bytes[0...13] == [0x06, 0x0E, 0x2B, 0x34, 0x02, 0x05, 0x01, 0x01, 0x0D, 0x01, 0x02, 0x01, 0x01, 0x02 ]
            }
        )
    ]
}


extension Data {
    private var mimeType: MimeType? {
        let bytes = readMimeTypeBytes()
        return MimeType.all.first { $0.matches(bytes: bytes, data: self) }
    }
    
    fileprivate func readMimeTypeBytes() -> [UInt8] {
        return readBytes(count: 262)
    }
    
    fileprivate func readBytes(count: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        copyBytes(to: &bytes, count: count)
        return bytes
    }
    
    var uti: UTI? {
        guard let mimeType = self.mimeType else { return nil }
        return UTI(withMimeType: mimeType.mime)
    }
}
