//
// Created by BLACKGENE on 21.05.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension String{
    func temporaryURL(_ uti:UTI?, group:String?=nil) -> URL{
        return FileURL.temp(self, uti, group:group)
    }

    func documentURL(_ uti:UTI?, group:String?=nil) -> URL{
        return FileURL.document(self, uti, group:group)
    }
}

public struct FileURL {
    public static var tempBase:URL {
        if #available(iOS 10.0, *) {
            return FileManager.default.temporaryDirectory
        } else {
            return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        }
    }

    public static var documentsBase:URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    public static func fileAndQueuePrivateGroup(_ file:String=#file) -> String{
        return filePrivateGroup(file)+"_"+queuePrivateGroup()
    }

    public static func filePrivateGroup(_ file:String=#file) -> String{
        return codefile(file)
    }

    public static func queuePrivateGroup(_ queueName:String=DispatchQueue.currentLabel) -> String{
        return queueName.replace("/", "") //path splitter not allowed.
    }

    /*
    Document
    */
    public static func document(_ pathComponents:String, _ uti:UTI?=nil, group:String?=nil) -> URL {
        return create(documentsBase, pathComponents, uti, group:group)
    }


    /*
    Temporary
    */
    public static func temp(_ pathComponents:String, _ uti:UTI?=nil, group:String?=nil) -> URL {
        return create(tempBase, pathComponents, uti, group:group)
    }

    public static func create(_ BaseURL:URL, _ pathComponents:String, _ uti:UTI?, group:String?=nil) -> URL {
        var dirURL = BaseURL

        if let group = group {
            dirURL = URL(fileURLWithPath: group, isDirectory: true, relativeTo: dirURL)
        }else{
            dirURL = BaseURL
        }

        var url = dirURL.appendingPathComponent(pathComponents)
        if let uti = uti{
            if let utiExtension = uti.fileExtension {
                url = url.appendingPathExtension(utiExtension)
            }else{
                print("[!] WARNING: Not found file extension for UTI '\(uti.rawValue)'. Using manually provided file extension '\(url.pathExtension)'.")
                assert(url.pathExtension.count>0, "Path extension is empty.")
            }
        }

        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        }catch let e{
            print(e)
        }

        return url
    }
}


public struct FileCollectableURL {
    /*
    Document
    */
    public static func discardMatchedInDocument(_ pathComponents:String?, _ uti:UTI?=nil, group:String?=nil) -> [URL]{
        return discardMatched(FileURL.documentsBase, pathComponents, uti, group: group)
    }

    public static func matchedInDocument(_ pathComponents:String?, _ uti:UTI?=nil, group:String?=nil) -> [URL]{
        return matched(FileURL.documentsBase, pathComponents, uti, group: group)
    }

    public static func acquireDocument(_ pathComponents:String, _ uti:UTI?=nil, group:String?=nil) -> URL {
        return acquire(FileURL.documentsBase, pathComponents, uti, group:group)
    } 


    /*
    Temporary
    */
    public static func discardMatchedInTemp(_ pathComponents:String?, _ uti:UTI?=nil, group:String?=nil) -> [URL]{
        return discardMatched(FileURL.tempBase, pathComponents, uti, group: group)
    }

    public static func matchedInTemp(_ pathComponents:String?, _ uti:UTI?=nil, group:String?=nil) -> [URL]{
        return matched(FileURL.tempBase, pathComponents, uti, group: group)
    }

    public static func acquireTemp(_ pathComponents:String, _ uti:UTI?=nil, group:String?=nil) -> URL {
        return acquire(FileURL.tempBase, pathComponents, uti, group:group)
    } 

    /*
        common
    */
    private static var URLsByBaseURL = [URL:[URL]]()

    private static let FileCollectableURLSyncQueue = DispatchQueue(label: "com.stells.internal_FileCollectableURLSyncQueue")

    private static func setURLs(_ BaseURL:URL, _ urls:[URL]) {
        FileCollectableURLSyncQueue.sync(flags: .barrier) {
            URLsByBaseURL[BaseURL] = urls
        }
    }

    private static func getURLs(_ BaseURL:URL) -> [URL]{
        if let urls = URLsByBaseURL[BaseURL]{
            return urls
        }
        let urls = [URL]()
        setURLs(BaseURL, urls)
        return urls
    }

    private static func getBaseURLs() -> [URL]{
        return Array(URLsByBaseURL.keys)
    }

    public static func acquire(_ BaseURL:URL, _ pathComponents:String, _ uti:UTI?, group:String?=nil) -> URL {
        let url = FileURL.create(BaseURL, pathComponents, uti, group: group)
        var urls = getURLs(BaseURL)
        urls.append(url)
        setURLs(BaseURL, urls)
        return url
    }

    @discardableResult
    public static func discardMatched(_ baseURL:URL, _ pathComponents:String?, _ uti:UTI?, group:String?=nil) -> [URL]{
        var removedURLs = [URL]()
        let targetURLsInBaseURL = matched(baseURL, pathComponents, uti, group: group)
        var urlsInBaseURL = getURLs(baseURL)

        for url in targetURLsInBaseURL {
            if let index = urlsInBaseURL.index(where:{ $0 == url }) {
                urlsInBaseURL.remove(at: index)
                removedURLs.append(url)

                try? FileManager.default.removeItem(at: url)
            }else{
                assert(false, "index for \(url.absoluteString) was not found")
            }
        }

        setURLs(baseURL, urlsInBaseURL)
        return removedURLs
    }

    @discardableResult
    public static func discardAll(_ pathComponents:String?=nil, _ uti:UTI?=nil, group:String?=nil) -> [URL]{
        var removedURLs = [URL]()
        for baseurl in getBaseURLs(){
            removedURLs.append(contentsOf: discardMatched(baseurl, pathComponents, uti, group:group))
        }
        return removedURLs
    }

    public static func matched(_ baseURL:URL, _ pathComponents:String?, _ uti:UTI?, group:String?=nil) -> [URL] {
        // .jpg -> pathComponents -> group(dir)
        return getURLs(baseURL).filter { url in

            if let uti = uti, uti != UTI(withURL: url) {
                return false
            }

            if let pathComponents = pathComponents{
                let fileURL = FileURL.create(baseURL, pathComponents, uti, group:group)
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
