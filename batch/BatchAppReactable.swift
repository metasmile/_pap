//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol BatchAppReactable{
    typealias ProgressHanlder = (
            _ result:BatchAppResult
            , _ progress:Double
            , _ remained:[BatchAppRespondable]
            , _ finished:[BatchAppRespondable]
    ) -> Void

    var progressHandler:ProgressHanlder? { get }
    func when(progress:@escaping ProgressHanlder) -> BatchAppReactable

    typealias FinishHandler = (
            _ results:[BatchAppResult]
            , _ for:[BatchAppRespondable]
    ) -> Void

    var finishHandler:FinishHandler?  { get }
    func when(finish:@escaping FinishHandler) -> BatchAppReactable
}

public class BatchAppReactionItem: ItemObject, BatchAppReactable{
    private(set) public var progressHandler:ProgressHanlder?

    public func when(progress:@escaping ProgressHanlder) -> BatchAppReactable {
        self.progressHandler = progress
        return self
    }

    private(set) public var finishHandler:FinishHandler?

    public func when(finish:@escaping FinishHandler) -> BatchAppReactable {
        self.finishHandler = finish
        return self
    }

    public init(finish: FinishHandler?=nil){
        super.init()
        if let _finish = finish{
            self.when(finish:_finish)
        }
    }
}