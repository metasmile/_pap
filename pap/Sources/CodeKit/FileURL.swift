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
        return FileURL.temporaryURL(self, uti, group:group)
    }

    func documentURL(_ uti:UTI?, group:String?=nil) -> URL{
        return FileURL.documentURL(self, uti, group:group)
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
    public static func discardMatchedDocumentURLs(_ pathComponents:String?, _ uti:UTI?=nil, group:String?=nil) -> [URL]{
        return discardMatchedURLs(DocumentsBaseURL, pathComponents, uti, group: group)
    }

    public static func matchedDocumentURLs(_ pathComponents:String?, _ uti:UTI?=nil, group:String?=nil) -> [URL]{
        return matchedURLs(DocumentsBaseURL, pathComponents, uti, group: group)
    }

    public static func documentURL(_ pathComponents:String, _ uti:UTI?=nil, group:String?=nil) -> URL {
        return acquireURL(DocumentsBaseURL, pathComponents, uti, group:group)
    }


    /*
    Temporary
    */
    public static func discardMatchedTemporaryURLs(_ pathComponents:String?, _ uti:UTI?=nil, group:String?=nil) -> [URL]{
        return discardMatchedURLs(TemporaryBaseURL, pathComponents, uti, group: group)
    }

    public static func matchedTemporaryURLs(_ pathComponents:String?, _ uti:UTI?=nil, group:String?=nil) -> [URL]{
        return matchedURLs(TemporaryBaseURL, pathComponents, uti, group: group)
    }

    public static func temporaryURL(_ pathComponents:String, _ uti:UTI?=nil, group:String?=nil) -> URL {
        return acquireURL(TemporaryBaseURL, pathComponents, uti, group:group)
    }

    /*
        common
    */
    private static var URLsByBaseURL = [URL:[URL]]()
    private static func getURLsBy(_ BaseURL:URL) -> [URL]{
        if let urls = URLsByBaseURL[BaseURL]{
            return urls
        }
        let urls = [URL]()
        URLsByBaseURL[BaseURL] = urls
        return urls
    }

    public static func acquireURL(_ BaseURL:URL, _ pathComponents:String, _ uti:UTI?, group:String?=nil) -> URL {
        let url = createURL(BaseURL, pathComponents, uti, group: group)
        var urls = getURLsBy(BaseURL)
        urls.append(url)
        URLsByBaseURL[BaseURL] = urls
        return url
    }

    private static func createURL(_ BaseURL:URL, _ pathComponents:String, _ uti:UTI?, group:String?=nil) -> URL {
        let relativeURL = BaseURL

        //TODO: recursive dir create
//        if let group = group {
//            relativeURL = URL(fileURLWithPath: group, isDirectory: true, relativeTo: relativeURL)
//        }else{
//            relativeURL = BaseURL
//        }

//        var isDir : ObjCBool = false
//        if !FileManager.default.fileExists(atPath: relativeURL.path, isDirectory:&isDir), isDir.boolValue {
//            try? FileManager.default.createDirectory(atPath: relativeURL.path, withIntermediateDirectories: true, attributes: nil)
//        }

        var url = relativeURL.appendingPathComponent(pathComponents)
        if let ext = uti?.fileExtension{
            url = url.appendingPathExtension(ext)
        }

        return url
    }

    public static func discardMatchedURLs(_ baseURL:URL, _ pathComponents:String?, _ uti:UTI?, group:String?=nil) -> [URL]{
        var removedURLs = [URL]()
        let targetURLsInBaseURL = matchedURLs(baseURL, pathComponents, uti, group: group)
        var urlsInBaseURL = getURLsBy(baseURL)

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

    public static func discardAllURLs(_ pathComponents:String?=nil, _ uti:UTI?=nil, group:String?=nil) -> [URL]{
        var removedURLs = [URL]()
        for baseurl in self.URLsByBaseURL.keys{
            removedURLs.append(contentsOf: discardMatchedURLs(baseurl, pathComponents, uti, group:group))
        }
        return removedURLs
    }

    public static func matchedURLs(_ baseURL:URL, _ pathComponents:String?, _ uti:UTI?, group:String?=nil) -> [URL] {
        // .jpg -> pathComponents -> group(dir)
        return getURLsBy(baseURL).filter { url in

            if let uti = uti, uti != UTI(withURL: url) {
                return false
            }

            if let pathComponents = pathComponents{
                let fileURL = createURL(baseURL, pathComponents, uti, group:group)
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
