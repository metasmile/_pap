//
// Created by BLACKGENE on 21.05.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public var TemporaryBaseURL:URL {
    if #available(iOS 10.0, *) {
        return FileManager.default.temporaryDirectory
    } else {
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }
}

extension String{
    func temporaryURL(_ uti:UTI?, group:String?=nil) -> URL{
        return FileURL.temporaryURL(self, uti, group:group)
    }
}


public struct FileURL {
    private static var URLsInTemporary = [URL]()
    private static var URLsInDocument = [URL]()

    public static func removeTemporaryFiles(_ identifier:String?, _ uti:UTI?, group:String?=nil){
        let targetURLs = URLsInTemporary.filter { url in

            print(identifier,  url.deletingPathExtension().lastPathComponent)
            if let identifier = identifier, url.deletingPathExtension().lastPathComponent != identifier{
                return false
            }

            print(uti?.fileExtension, url.pathExtension)
            if let uti = uti, uti != UTI(withExtension: url.pathExtension){
                return false
            }

            print(group, url.deletingLastPathComponent().lastPathComponent)
            if let group = group, group != url.deletingLastPathComponent().lastPathComponent{
                return false
            }

            return true
        }

        for url in targetURLs{
            if let index = URLsInTemporary.index(where:{ $0 == url }) {
                try? FileManager.default.removeItem(at: url)
                URLsInTemporary.remove(at: index)
            }
        }
    }

    public static func temporaryURL(_ identifier:String, _ uti:UTI?, group:String?=nil) -> URL {
        var baseURL = TemporaryBaseURL
        if let group = group {
            baseURL = URL(fileURLWithPath: group, isDirectory: true, relativeTo: TemporaryBaseURL)
        }else{
            baseURL = TemporaryBaseURL
        }

        var url = baseURL.appendingPathComponent(identifier)
        if let ext = uti?.fileExtension{
            url = url.appendingPathExtension(ext)
        }

        URLsInTemporary.append(url)

        return url
    }
}
