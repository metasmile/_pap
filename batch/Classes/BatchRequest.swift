//
//  BatchRequest.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 3..
//  Copyright © 2017년 Stells. All rights reserved.
//

import UIKit
import Photos

struct BatchEditRequestResult {
    var asset: PHAsset
    var contentEditingOutput: PHContentEditingOutput
}

class BatchRequest: NSObject {
    func cancel() {
        
    }
}

class BatchEditRequest: BatchRequest {
    fileprivate var batchEditItem: BatchEditItem?
    
    init(_ batchEditItem: BatchEditItem) {
        super.init()
        
        self.batchEditItem = batchEditItem
    }
    
    func perform(_ progress: ((Float) -> Void)? = nil, _ completion: ((BatchEditRequestResult?) -> Void)? = nil) {
        guard let batchEditItem = batchEditItem else {
            completion?(nil)
            return
        }
        
        batchEditItem.runEditing(progress) { (asset, contentEditingOutput) in
            var result: BatchEditRequestResult?
            if let asset = asset, let contentEditingOutput = contentEditingOutput {
                result = BatchEditRequestResult(asset: asset, contentEditingOutput: contentEditingOutput)
            }
            completion?(result)
        }
    }
}

class BatchEditSequenceRequest: BatchRequest {
    fileprivate var batchQueue = TaskQueue()
    fileprivate var requests: [BatchEditRequest]?
    
    func perform(_ requests: [BatchEditRequest], _ progressHandler: ((Float, Int?) -> Void)? = nil, _ completionHandler: (([BatchEditRequestResult]) -> Void)? = nil) {
        self.requests = requests
        
        let numberOfRequests = requests.count
        var results = [BatchEditRequestResult]()
        
        let progressPerRequest = 1 / Float(numberOfRequests)
        
        for (idx, request) in requests.enumerated() {
            autoreleasepool {
                self.batchQueue.addTask({
                    request.perform({ progress in
                        progressHandler?(Float(idx) / Float(numberOfRequests) + progressPerRequest * progress, nil)
                    }) { result in
                        if let result = result {
                            results.append(result)
                        }
                        progressHandler?(Float(idx + 1) / Float(numberOfRequests), idx)
                        
                        self.batchQueue.performNext()
                    }
                })
            }
        }
        
        batchQueue.setFinishBlock {
            completionHandler?(results)
        }
        batchQueue.performNext()
    }
    
    override func cancel() {
        batchQueue.cancel()
        
        guard let requests = self.requests else { return }
        for request in requests {
            request.batchEditItem?.cancelEditing()
        }
    }
}
