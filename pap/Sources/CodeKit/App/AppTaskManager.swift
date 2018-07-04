//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Dispatch

public class AppTaskManager: NSObject, KeyPathWatchable, AppTaskOperationQueueDelegate {

    fileprivate static let sharedSyncQueue:DispatchQueue = DispatchQueue(label:"com.stells.pap__shared_AppTaskManager")

    private static var sharedManagers = [UInt:AppTaskManager]()

    public static func shared(_ maxConcurrentCount:UInt) -> AppTaskManager{
        guard let manager = sharedManagers[maxConcurrentCount] else{
            return sharedSyncQueue.sync(flags:.barrier){
                let _manager = AppTaskManager(maxConcurrentCount)
                sharedManagers[maxConcurrentCount] = _manager
                return _manager
            }
        }
        return manager
    }

    private let syncQueue:DispatchQueue = DispatchQueue(label:"com.stells.pap__internal_AppTaskManager"+UUID().uuidString)
    private var queuePool = [String: AppTaskOperationQueue]()

    //react
    private var reaction: AppTaskReaction?
    private var reactionToCancel: AppTaskCancellationReaction?

    // when all tasks are finished, this property will be filled.
    @objc dynamic
    public var appIdentifiersFinished:[String]?

    //result collection
    private var staticResponsesForEachApps = [AppInfo: [AppTaskRespondable]]()
    private var staticRequestedWorkItems = [String: AppTaskItem]()
    private var staticFinishedWorkItems = [AppTaskItem]()

    public final var maxConcurrentCount:Int{
        return self.queuePool.count
    }

    public var isRunning:Bool{
        return count > 0
    }

    public var count:Int{
        var iter = queuePool.values.makeIterator()
        var c = 0
        while let q = iter.next() {
            c += q.count
        }
        return c
    }

    private init(_ maxConcurrentCount:UInt=1) {
        assert(maxConcurrentCount>0, "concurrentCount must be 1 or higher.")
        super.init()
        for _ in 0 ..< maxConcurrentCount{
            let q = AppTaskOperationQueue(delegate:self)
            queuePool[q.label] = q
        }
    }

    private func createTask(_ request:AppTaskRequest) -> AppTaskable?{
        let appInfo = request.appType.info

        guard AppLifecycleManager.shared.acquire(appInfo) != nil else {
            assert(false, "Task Creation was failed for an App \(request.appType)")
            return nil
        }
        let taskType = appInfo.appType.taskType
        let taskInfo = AppTaskInfo(request.token, request.param, taskType.self, request.appType)

        if let taskPolicy = request.taskPolicy{
            //if request exactly has taskPolicy, that will have first priority.
            taskInfo.policy = taskPolicy
        }else{
            //or, request.taskPolicy was not defined, inheritance from app config
            taskInfo.policy = appInfo.policy.task
        }

        return taskType.init(taskInfo)
    }

    var currentTaskItems:[AppTaskItem] {
        return queuePool.values.flatMap { q -> [AppTaskItem] in Array(q.iterator()) }
    }

    //TODO: query by all of each request's properties.
    public func query(by requestTokens:[String]) -> [AppTaskInfo] {
        return requestTokens.compactMap { token -> AppTaskInfo? in
            staticRequestedWorkItems[token]?.info
        }
    }

    @discardableResult
    public func request(_ request:AppTaskRequest) -> AppTaskInfo?{
        let info = append(request:request)
        perform(ignoreIfSuspended:true)
        return info
    }

    public func remove(request:AppTaskRequest){
        syncQueue.sync(flags:.barrier){

            guard let queuedTaskItem = staticRequestedWorkItems[request.token]
            , let queueLabel = queuedTaskItem.info.queueLabel
            , let queue = self.queuePool[queueLabel] else {
                print("[!] a queue by the request is unqueued")
                return
            }

            guard let removedItem = (queue.remove { item -> Bool in
                if queue.currentTaskInfo != nil && item.info == queue.currentTaskInfo {
                    return false
                }
                return item.info.requestToken == request.token
            }) else {
                print("[i] The item doest not exist, but try to remove. It might be already dequeued.")
                return
            }

            assert(removedItem.info.requestToken==request.token)
            staticRequestedWorkItems.removeValue(forKey: removedItem.info.requestToken)
        }
    }

    //TODO: improve item append performance.
    //TODO: check conforms TaskParamable type.
    @discardableResult
    public func append(request:AppTaskRequest) -> AppTaskInfo?{
        return syncQueue.sync(flags:.barrier){

            if let queued = self.query(by:[request.token]).first {
                assert(queued.state != .unqueued, "queued.state is unqueued")
                return queued
            }

            guard let task: AppTaskable = createTask(request) else {
                return nil
            }

            let item = AppTaskItem(
                    request: request
                    , info: task.info
                    , task: task
            )

            var queues = Array(queuePool.values)
            if let preferredCount = task.info.policy.estimatedConcurrencyCount {
                assert(preferredCount>0, "preferredCount cannot be lower than 1 if it was preferred.")
                queues = Array(queues[0 ..< min(queues.count, preferredCount)])
            }

            // if queue does not exist, return nil
            if queues.count < 1{
                return nil
            }

            //normally find a queue which has lowest number of child tasks.
            var currentQueue:AppTaskOperationQueue = queues[0]
            for queue in queues {
                if queue.count < currentQueue.count {
                    currentQueue = queue
                }
            }

            print("Assigned a task \(task.info.token) into -> \(currentQueue.label)")

            if task.info.policy.priority == .high {
                currentQueue.enqueue(item, reverse: true)
            }else{
                currentQueue.enqueue(item)
            }

            staticRequestedWorkItems[item.request.token] = item

            return item.task.info
        }
    }
    
    @discardableResult
    private func perform(ignoreIfSuspended:Bool=false) -> Bool {
        if queuePool.count==0 {
            return false
        }

        for queue in queuePool.values {
            if ignoreIfSuspended && queue.suspended{
                return false
            }
            queue.perform()
        }

        return true
    }

    @discardableResult
    public func perform(_ reaction: AppTaskReaction?=nil) -> Bool {
        syncQueue.sync(flags:.barrier){ [unowned self] in
            self.reactionToCancel = nil
            self.reaction = reaction
        }
        return perform(ignoreIfSuspended:false)
    }

    @discardableResult
    public func perform(finished: @escaping AppTaskReactableFinishHandler) -> Bool {
        return perform(AppTaskReaction(finish: finished))
    }

    public func cancel(_ reaction: AppTaskCancellationReaction?=nil){
        syncQueue.sync(flags:.barrier){ [unowned self] in
            self.reaction = nil
            self.reactionToCancel = reaction
        }

        for (_,v) in queuePool {
            v.cancel()
        }
    }

    public func suspend(){
        for (_,v) in queuePool {
            v.suspend()
        }
    }

    func delegatingQueue(from: AppTaskOperationQueue) -> DispatchQueue {
        return DispatchQueue.main
    }

    func willPerformTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskItem) {

    }

    func didFailTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskItem) {
        syncQueue.sync(flags:.barrier){
            countFinishedTaskByEachQueues(queue, workItem)
        }
    }

    func didCompleteTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskItem) {
        syncQueue.sync(flags:.barrier){
            countFinishedTaskByEachQueues(queue, workItem)
        }
    }

    func didCancelTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskItem) {
        syncQueue.sync(flags:.barrier){
            countFinishedTaskByEachQueues(queue, workItem)
        }
    }

    func didFinishAllTasksInQueue(_ queue: AppTaskOperationQueue, _ result: [AppTaskItem]?) {
        
    }

    //counter
    private func countFinishedTaskByEachQueues(_ queue: AppTaskOperationQueue, _ workItem: AppTaskItem) {
        let appType = workItem.request.appType
        let appInfo = appType.info

        if !staticResponsesForEachApps.keys.contains(appInfo){
            staticResponsesForEachApps[appInfo] = [AppTaskRespondable]()
        }
        staticResponsesForEachApps[appInfo]?.append(workItem)

        staticRequestedWorkItems.removeValue(forKey: workItem.info.requestToken)
        staticFinishedWorkItems.append(workItem)

        print("Remaining tasks: ", staticRequestedWorkItems.count)

        //progress
        let creq = staticRequestedWorkItems.count
        let cres = staticFinishedWorkItems.count
        let progress = Float(cres)/Float(creq + cres)

        let remainedResponses = Array(self.staticRequestedWorkItems.values)
        let finishedResponses = self.staticFinishedWorkItems

        DispatchQueue.main.async { [unowned self] in
            self.reaction?.progressHandler?(
                    workItem
                    ,progress
                    ,remainedResponses
                    , finishedResponses
            )
        }
        
        //all finished
        let allFinished = staticRequestedWorkItems.count==0

        if allFinished {
            let staticFinishedWorkItems = self.staticFinishedWorkItems
            let staticResponsesForEachApps = self.staticResponsesForEachApps

            //enter finalize scope after already running main queue
            DispatchQueue.main.async { [unowned self] in

                //will finish
                self.reaction?.willFinishHandler?(staticResponsesForEachApps, staticFinishedWorkItems)

                self.reactionToCancel?.willCancelHandler?()

                self.syncQueue.async{
                    let finalizedStaticResponsesForEachApps = self.finializeAllTasks(staticResponsesForEachApps)

                    //did finish
                    DispatchQueue.main.async { [unowned self] in
                        self.reactionToCancel?.cancellationHandler?()

                        self.reaction?.didFinishHandler?(finalizedStaticResponsesForEachApps, staticFinishedWorkItems)

                        self.appIdentifiersFinished = finalizedStaticResponsesForEachApps.keys.map { info -> String in
                            return info.identifier
                        }
                    }
                }
            }

            //clean buffered results
            self.staticFinishedWorkItems.removeAll()
            self.staticRequestedWorkItems.removeAll()
            self.staticResponsesForEachApps.removeAll()
        }
    }

    private func finializeAllTasks(_ resForEachApps:[AppInfo: [AppTaskRespondable]]) -> [AppInfo: [AppTaskRespondable]] {
        let asyncSignal = AsyncSignal()
        var finalizedResults = [AppInfo: [AppTaskRespondable]]()

        for (appInfo, reses) in resForEachApps{
            guard let appInstance = AppLifecycleManager.shared.acquire(appInfo) else{
                assert(false,"App doest not exist any longer. Check it on lifecycle manager.")
                continue
            }

            if let appInstanceAsFinalizable = appInstance as? FinalizableApp, appInstanceAsFinalizable.shouldFinalize(result: reses, asyncSignal) {
                finalizedResults[appInfo] = appInstanceAsFinalizable.finalize(result: reses, asyncSignal)
            }else{
                finalizedResults[appInfo] = reses
            }

            if appInfo.policy.lifeCycle.instance == .allTasks {
                AppLifecycleManager.shared.discard(appInfo)
                assert(!AppLifecycleManager.shared.acquired.contains(appInfo.identifier))
            }
        }

        return finalizedResults
    }
}
