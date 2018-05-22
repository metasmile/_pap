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

public var DocumentsBaseURL:URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}

public func CodeFileName(_ _file:String=#file) -> String{
    return URL(fileURLWithPath: _file).deletingPathExtension().lastPathComponent
}

extension String{
    func temporaryURL(_ uti:UTI?, group:String?=nil) -> URL{
        return FileURL.temp(self, uti, group:group)
    }

    func documentURL(_ uti:UTI?, group:String?=nil) -> URL{
        return FileURL.document(self, uti, group:group)
    }
}

public struct FileURL {
    public static func fileAndQueuePrivateGroup(_ file:String=#file) -> String{
        return filePrivateGroup(file)+"_"+queuePrivateGroup()
    }

    public static func filePrivateGroup(_ file:String=#file) -> String{
        return CodeFileName(file)
    }

    public static func queuePrivateGroup(_ queueName:String=DispatchQueue.currentLabel) -> String{
        return queueName
    }

    /*
    Document
    */
    public static func discardMatchedInDocument(_ pathComponents:String?, _ uti:UTI?=nil, group:String?=nil) -> [URL]{
        return discardMatched(DocumentsBaseURL, pathComponents, uti, group: group)
    }

    public static func matchedInDocument(_ pathComponents:String?, _ uti:UTI?=nil, group:String?=nil) -> [URL]{
        return matched(DocumentsBaseURL, pathComponents, uti, group: group)
    }

    public static func document(_ pathComponents:String, _ uti:UTI?=nil, group:String?=nil) -> URL {
        return acquire(DocumentsBaseURL, pathComponents, uti, group:group)
    }


    /*
    Temporary
    */
    public static func discardMatchedInTemp(_ pathComponents:String?, _ uti:UTI?=nil, group:String?=nil) -> [URL]{
        return discardMatched(TemporaryBaseURL, pathComponents, uti, group: group)
    }

    public static func matchedInTemp(_ pathComponents:String?, _ uti:UTI?=nil, group:String?=nil) -> [URL]{
        return matched(TemporaryBaseURL, pathComponents, uti, group: group)
    }

    public static func temp(_ pathComponents:String, _ uti:UTI?=nil, group:String?=nil) -> URL {
        return acquire(TemporaryBaseURL, pathComponents, uti, group:group)
    }

    /*
        common
    */
    private static var URLsByBaseURL = [URL:[URL]]()
    private static func getURLBy(_ BaseURL:URL) -> [URL]{
        if let urls = URLsByBaseURL[BaseURL]{
            return urls
        }
        let urls = [URL]()
        URLsByBaseURL[BaseURL] = urls
        return urls
    }

    public static func acquire(_ BaseURL:URL, _ pathComponents:String, _ uti:UTI?, group:String?=nil) -> URL {
        let url = create(BaseURL, pathComponents, uti, group: group)
        var urls = getURLBy(BaseURL)
        urls.append(url)
        URLsByBaseURL[BaseURL] = urls
        return url
    }

    private static func create(_ BaseURL:URL, _ pathComponents:String, _ uti:UTI?, group:String?=nil) -> URL {
        var dirURL = BaseURL

        if let group = group {
            dirURL = URL(fileURLWithPath: group, isDirectory: true, relativeTo: dirURL)
        }else{
            dirURL = BaseURL
        }

        var url = dirURL.appendingPathComponent(pathComponents)
        if let ext = uti?.fileExtension{
            url = url.appendingPathExtension(ext)
        }

        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)

        return url
    }

    public static func discardMatched(_ baseURL:URL, _ pathComponents:String?, _ uti:UTI?, group:String?=nil) -> [URL]{
        var removedURLs = [URL]()
        let targetURLsInBaseURL = matched(baseURL, pathComponents, uti, group: group)
        var urlsInBaseURL = getURLBy(baseURL)

        for url in targetURLsInBaseURL {
            if let index = urlsInBaseURL.index(where:{ $0 == url }) {
                urlsInBaseURL.remove(at: index)
                removedURLs.append(url)

                try? FileManager.default.removeItem(at: url)
            }else{
                assert(false, "index for \(url.absoluteString) was not found")
            }
        }

        URLsByBaseURL[baseURL] = urlsInBaseURL
        return removedURLs
    }

    public static func discardAll(_ pathComponents:String?=nil, _ uti:UTI?=nil, group:String?=nil) -> [URL]{
        var removedURLs = [URL]()
        for baseurl in self.URLsByBaseURL.keys{
            removedURLs.append(contentsOf: discardMatched(baseurl, pathComponents, uti, group:group))
        }
        return removedURLs
    }

    public static func matched(_ baseURL:URL, _ pathComponents:String?, _ uti:UTI?, group:String?=nil) -> [URL] {
        // .jpg -> pathComponents -> group(dir)
        return getURLBy(baseURL).filter { url in

            if let uti = uti, uti != UTI(withURL: url) {
                return false
            }

            if let pathComponents = pathComponents{
                let fileURL = create(baseURL, pathComponents, uti, group:group)
                if url.lastPathComponent != fileURL.lastPathComponent{
                    return false
                }
            }

            if let group = group, group != url.deletingLastPathComponent().lastPathComponent {
                return false
            }

            return true
        }
    }
}
