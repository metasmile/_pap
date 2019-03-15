//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Dispatch

public protocol AppTaskRespondable {
    var request: AppTaskRequest { get }
    var result: AppTaskResultable? { get }
    var info: AppTaskInfo { get }
}

extension AppTaskRespondable {
    public var appInfo:AppInfo{
        return self.request.appType.info
    }
}


/*
    Reactable
*/

// Appable
public typealias AppTaskReactableProgressHanlder = (
        _ progressedResult: AppTaskRespondable
        , _ progress:Progress
        , _ remainedResponses:[AppTaskRespondable]
        , _ completedResponses:[AppTaskRespondable]
) -> Void

public typealias AppTaskReactableFinishHandler = (
        _ byApps:[AppInfo: [AppTaskRespondable]]
        , _ forAllResponses:[AppTaskRespondable]
) -> Void

public typealias AppTaskReactableWillFinishHandler = (
        _ byApps:[AppInfo: [AppTaskRespondable]]
        , _ forAllResponses:[AppTaskRespondable]
) -> Void

public class AppTaskCancellationReaction: ItemObject {
    //progress
    private(set) public var cancellationHandler: (() -> ())?

    @discardableResult
    public func did(cancel:@escaping (() -> ())) -> Self {
        self.cancellationHandler = cancel
        return self
    }

    //finalize
    private(set) public var willCancelHandler: (() -> ())?

    @discardableResult
    public func will(cancel:@escaping (() -> ())) -> Self {
        self.willCancelHandler = cancel
        return self
    }

    public init(didCancel: (() -> ())?=nil){
        super.init()

        if let cancel = didCancel {
            self.did(cancel: cancel)
        }
    }
}

public class AppTaskReaction: ItemObject {
    internal(set) public var targetQueue:DispatchQueue?

    //progress
    private(set) public var progressHandler: AppTaskReactableProgressHanlder?

    @discardableResult
    public func when(progress:@escaping AppTaskReactableProgressHanlder) -> Self {
        self.progressHandler = progress
        return self
    }

    //finalize
    private(set) public var willFinishHandler: AppTaskReactableWillFinishHandler?

    @discardableResult
    public func will(finish:@escaping AppTaskReactableWillFinishHandler) -> Self {
        self.willFinishHandler = finish
        return self
    }

    //finish
    private(set) public var didFinishHandler: AppTaskReactableFinishHandler?

    @discardableResult
    public func did(finish:@escaping AppTaskReactableFinishHandler) -> Self {
        self.didFinishHandler = finish
        return self
    }

    public init(finish: AppTaskReactableFinishHandler?=nil){
        super.init()

        if let finish = finish{
            self.did(finish: finish)
        }
    }
}


