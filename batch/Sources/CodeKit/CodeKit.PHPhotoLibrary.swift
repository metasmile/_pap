//
// Created by BLACKGENE on 14.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos


extension PHPhotoLibrary{

    //TODO: universal types.
    public func saveAsAnyAndWait(items:[Any]){

        // [[URL]]
        let urlsItems = items.compactMap { item -> [URL]? in
            var urls = item as? [URL]
            if urls == nil, let url = item as? URL{
                urls = [url]
            }
            return urls
        }
        saveAs(urlGroups: urlsItems)
    }

    private func saveAs(urlGroups:[[URL]]){

        try? PHPhotoLibrary.shared().performChangesAndWait {

            for urls in urlGroups {

                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true

                for url in urls{
                    let uti = UTI(withURL: url)

                    if uti.conforms(to: UTI.image) {
                        request.addResource(with: .photo, fileURL: url, options: options)
                    }
                    else if uti.conforms(to: UTI.movie) {
                        if urls.contains(where: { UTI(withURL: $0).conforms(to: UTI.image) }) == true {
                            request.addResource(with: .pairedVideo, fileURL: url, options: options)
                        }
                        else {
                            request.addResource(with: .video, fileURL: url, options: options)
                        }
                    }
                }
            }
        }
    }
}