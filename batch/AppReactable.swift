//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol AppReactable {
    typealias ProgressHanlder = (
            _ result: AppResult
            , _ progress:Double
            , _ remained:[AppRespondable]
            , _ finished:[AppRespondable]
    ) -> Void

    var progressHandler:ProgressHanlder? { get }
    func when(progress:@escaping ProgressHanlder) -> AppReactable

    typealias FinishHandler = (
            _ results:[AppResult]
            , _ for:[AppRespondable]
    ) -> Void

    var finishHandler:FinishHandler?  { get }
    func when(finish:@escaping FinishHandler) -> AppReactable
}

public class AppReactionItem: ItemObject, AppReactable {
    private(set) public var progressHandler:ProgressHanlder?

    public func when(progress:@escaping ProgressHanlder) -> AppReactable {
        self.progressHandler = progress
        return self
    }

    private(set) public var finishHandler:FinishHandler?

    public func when(finish:@escaping FinishHandler) -> AppReactable {
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