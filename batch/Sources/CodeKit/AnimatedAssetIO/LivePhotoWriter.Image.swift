//
//  LivePhotoWriter.Image.swift
//  Live Photos
//
//  Originally Created by genadyo (github.com/genadyo).
//  Newly Written by metasmile (github.com/metasmile) on 9/12/16.
//

import Foundation
import MobileCoreServices
import ImageIO

public class LivePhotoImageResourceWriter: NSObject {
    private let kFigAppleMakerNote_AssetIdentifier = "17"

    @discardableResult
    public func write(from fromUrl:URL, to toUrl: URL, assetIdentifier : String) -> Bool {
        guard let data = fromUrl.asData else {
            return false
        }

        let updatedData:Data
        if let metadata = data.getMetadata(){
            updatedData = data.updateMetadata(with: metadata, dictionary: ImageMetadata.Dictionary.MakerApple, property: kFigAppleMakerNote_AssetIdentifier, value: assetIdentifier)
        }else{
            updatedData = data.setMetadata(with: [ImageMetadata.Dictionary.MakerApple: [kFigAppleMakerNote_AssetIdentifier:assetIdentifier]] )
        }

        do {
            try updatedData.write(to: toUrl)
            return true

        } catch _ {}

        return false
    }
}