//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Dispatch

public typealias AppTaskRequest = TaskRequest<App.Type, TaskParamable, AppTaskRespondable>

/*
    Protocols
*/
public protocol AppTaskManagerDelegate: class {
    func didRespond(forCurrent: AppTaskRespondable, progress:Float, remained:[AppTaskRespondable], finished:[AppTaskRespondable])
    func willFinish(forEachApps:[AppInfo:[AppTaskRespondable]], forAll:[AppTaskRespondable])
    func didFinish(forEachApps:[AppInfo:[AppTaskRespondable]], forAll:[AppTaskRespondable])
}

public protocol AppTaskManagerTaskDelegate: AppTaskManagerDelegate {
    func willPerformTask(info: AppTaskRespondable)
    func didCompleteTask(info: AppTaskRespondable)
    func didCancelTask(info: AppTaskRespondable)
    func didFailTask(info: AppTaskRespondable)
}

public class AppTaskManager: AppTaskOperationQueueDelegate {

    fileprivate static let sharedSyncQueue:DispatchQueue = DispatchQueue(label:"com.stells.pap__shared_AppTaskManager")

    private static var _sharedManagers = [UInt:AppTaskManager]()

    public static func shared(_ maxConcurrentCount:UInt) -> AppTaskManager{
        guard let manager = _sharedManagers[maxConcurrentCount] else{
            return sharedSyncQueue.sync(flags:.barrier){
                let _manager = AppTaskManager(maxConcurrentCount)
                _sharedManagers[maxConcurrentCount] = _manager
                return _manager
            }
        }
        return manager
    }

    public weak var delegate:AppTaskManagerDelegate?

    private let syncQueue:DispatchQueue = DispatchQueue(label:"com.stells.pap__internal_AppTaskManager"+UUID().uuidString)
    private var _queuePool = [String: AppTaskOperationQueue]()

    //react
    private var _reactionItem: AppTaskReactable?

    //result collection
    private var _staticResponsesForEachApps = [AppInfo: [AppTaskRespondable]]()
    private var _staticRequestedWorkItems = [String: AppTaskItem]()
    private var _staticFinishedWorkItems = [AppTaskItem]()

    public final var maxConcurrentCount:Int{
        return self._queuePool.count
    }

    public var count:Int{
        var iter = _queuePool.values.makeIterator()
        var c = 0
        while let q = iter.next() {
            c += q.count
        }
        return c
    }

    private init(_ maxConcurrentCount:UInt=1) {
        assert(maxConcurrentCount>0, "concurrentCount must be 1 or higher.")
        for _ in 0 ..< maxConcurrentCount{
            let q = AppTaskOperationQueue(delegate:self)
            _queuePool[q.label] = q
        }
    }

    private func createTask(_ request:AppTaskRequest) -> Taskable?{
        let appInfo = request.appType.info

        guard AppLifecycleManager.shared.acquire(appInfo) != nil else {
            assert(false, "Task Creation was failed for an App \(request.appType)")
            return nil
        }
        let taskType = appInfo.appType.taskType
        let taskInfo = TaskInfo(request.token, request.param, taskType.self, request.appType)

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
        return _queuePool.values.flatMap { q -> [AppTaskItem] in Array(q.iterator()) }
    }

    //TODO: query by all of each request's properties.
    public func query(by requestTokens:[String]) -> [TaskInfo] {
        return requestTokens.compactMap { token -> TaskInfo? in
            _staticRequestedWorkItems[token]?.info
        }
    }

    @discardableResult
    public func request(_ request:AppTaskRequest) -> TaskInfo?{
        let info = append(request:request)
        perform(ignoreIfSuspended:true)
        return info
    }

    public func remove(request:AppTaskRequest){
        syncQueue.sync(flags:.barrier){

            guard let queuedTaskItem = _staticRequestedWorkItems[request.token]
            , let queueLabel = queuedTaskItem.info.queueLabel
            , let queue = self._queuePool[queueLabel] else {
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
            _staticRequestedWorkItems.removeValue(forKey: removedItem.info.requestToken)
        }
    }

    //TODO: improve item append performance.
    //TODO: check conforms TaskParamable type.
    @discardableResult
    public func append(request:AppTaskRequest) -> TaskInfo?{
        return syncQueue.sync(flags:.barrier){

            if let queued = self.query(by:[request.token]).first {
                assert(queued.state != .unqueued, "queued.state is unqueued")
                return queued
            }

            guard let task: Taskable = createTask(request) else {
                return nil
            }

            let item = AppTaskItem(
                    request: request
                    , info: task.info
                    , task: task
            )

            var queues = Array(_queuePool.values)
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

            _staticRequestedWorkItems[item.request.token] = item

            return item.task.info
        }
    }
    
    @discardableResult
    private func perform(ignoreIfSuspended:Bool=false) -> Bool {
        if _queuePool.count==0 {
            return false
        }

        for queue in _queuePool.values {
            if ignoreIfSuspended && queue.suspended{
                return false
            }
            queue.perform()
        }

        return true
    }

    @discardableResult
    public func perform(_ reaction: AppTaskReactable?=nil) -> Bool {
        if reaction != nil{
            syncQueue.sync(flags:.barrier){ [unowned self] in
                self._reactionItem = reaction
            }
        }
        return perform(ignoreIfSuspended:false)
    }

    @discardableResult
    public func perform(finished: @escaping AppTaskReactableFinishHandler) -> Bool {
        return perform(AppTaskReaction(finish: finished))
    }

    public func cancel(){
        for (_,v) in _queuePool{
            v.cancel()
        }
    }

    public func suspend(){
        for (_,v) in _queuePool{
            v.suspend()
        }
    }

    func delegatingQueue(from: AppTaskOperationQueue) -> DispatchQueue {
        return DispatchQueue.main
    }

    func willPerformTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskItem) {
        (self.delegate as? AppTaskManagerTaskDelegate)?.willPerformTask(info: workItem)
    }

    func didFailTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskItem) {
        (self.delegate as? AppTaskManagerTaskDelegate)?.didFailTask(info: workItem)

        syncQueue.sync(flags:.barrier){
            _countFinishedTaskByEachQueues(queue, workItem)
        }
    }

    func didCompleteTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskItem) {
        (self.delegate as? AppTaskManagerTaskDelegate)?.didCompleteTask(info: workItem)

        syncQueue.sync(flags:.barrier){
            _countFinishedTaskByEachQueues(queue, workItem)
        }
    }

    func didCancelTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskItem) {
        (self.delegate as? AppTaskManagerTaskDelegate)?.didCancelTask(info: workItem)

        syncQueue.sync(flags:.barrier){
            _countFinishedTaskByEachQueues(queue, workItem)
        }
    }

    func didFinishAllTasksInQueue(_ queue: AppTaskOperationQueue, _ result: [AppTaskItem]?) {
        
    }

    //counter
    //TODO: multi-apps for each requestToken

    private func _countFinishedTaskByEachQueues(_ queue: AppTaskOperationQueue, _ workItem: AppTaskItem) {
        let appType = workItem.request.appType
        let appInfo = appType.info

        if !_staticResponsesForEachApps.keys.contains(appInfo){
            _staticResponsesForEachApps[appInfo] = [AppTaskRespondable]()
        }
        _staticResponsesForEachApps[appInfo]?.append(workItem)

        _staticRequestedWorkItems.removeValue(forKey: workItem.info.requestToken)
        _staticFinishedWorkItems.append(workItem)

        print("Remaining tasks: ", _staticRequestedWorkItems.count)

        //progress
        let creq = _staticRequestedWorkItems.count
        let cres = _staticFinishedWorkItems.count
        let progress = Float(cres)/Float(creq + cres)

        let remainedResponses = Array(self._staticRequestedWorkItems.values)
        let finishedResponses = self._staticFinishedWorkItems

        DispatchQueue.main.async { [unowned self] in
            self.delegate?.didRespond(forCurrent: workItem
                    , progress: progress
                    , remained: remainedResponses
                    , finished: finishedResponses)

            self._reactionItem?.progressHandler?(
                    workItem
                    ,progress
                    ,remainedResponses
                    , finishedResponses
            )
        }
        
        //all finished
        let allFinished = _staticRequestedWorkItems.count==0

        if allFinished {
            let staticFinishedWorkItems = self._staticFinishedWorkItems
            let staticResponsesForEachApps = self._staticResponsesForEachApps

            //enter finalize scope after already running main queue
            DispatchQueue.main.async { [unowned self] in

                //will finish
                self.delegate?.willFinish(forEachApps: staticResponsesForEachApps, forAll: staticFinishedWorkItems)
                self._reactionItem?.willFinishHandler?(staticResponsesForEachApps, staticFinishedWorkItems)

                self.syncQueue.async{
                    let finalized_staticResponsesForEachApps = self._finializeAllTasks(staticResponsesForEachApps)

                    //did finish
                    DispatchQueue.main.async { [unowned self] in
                        self.delegate?.didFinish(forEachApps: finalized_staticResponsesForEachApps, forAll: staticFinishedWorkItems)
                        self._reactionItem?.didFinishHandler?(finalized_staticResponsesForEachApps, staticFinishedWorkItems)
                    }
                }
            }

            //clean buffered results
            _staticFinishedWorkItems.removeAll()
            _staticRequestedWorkItems.removeAll()
            _staticResponsesForEachApps.removeAll()
        }
    }

    private func _finializeAllTasks(_ resForEachApps:[AppInfo: [AppTaskRespondable]]) -> [AppInfo: [AppTaskRespondable]] {
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

            if appInfo.policy.lifeCycleUnit == .allTasks {
                AppLifecycleManager.shared.discard(appInfo)
                assert(!AppLifecycleManager.shared.acquired.contains(appInfo.identifier))
            }
        }

        return finalizedResults
    }
}
