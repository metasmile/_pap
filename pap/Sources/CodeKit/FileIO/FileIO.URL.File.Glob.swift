//
// Created by BLACKGENE on 22.05.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

// e.g. FileURL.glob(FileURL.tempBase.path+"/*") -> all files in temp dir
// e.g. FileURL.glob(FileURL.tempBase.path+"/*.png") -> png files in temp dir

#if os(Linux)
import Glibc

let system_glob = Glibc.glob
#else
import Darwin

let system_glob = Darwin.glob
#endif

extension FileURL{
    public static func glob(_ pattern: String) -> [URL] {
        var gt = glob_t()
        let cPattern = strdup(pattern)
        defer {
            globfree(&gt)
            free(cPattern)
        }

        let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
        if system_glob(cPattern, flags, nil, &gt) == 0 {
#if os(Linux)
            let matchc = gt.gl_pathc
#else
            let matchc = gt.gl_matchc
#endif
#if swift(>=4.1)
            return (0..<Int(matchc)).compactMap { index in
                if let path = String(validatingUTF8: gt.gl_pathv[index]!) {
                    return URL(fileURLWithPath: path)
                }

                return nil
            }
#else
            return (0..<Int(matchc)).flatMap { index in
                if let path = String(validatingUTF8: gt.gl_pathv[index]!) {
                    return Path(path)
                }
                return nil
            }
#endif
        }

        // GLOB_NOMATCH
        return []
    }
}
