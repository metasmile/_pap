//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public typealias AppTaskRequest = TaskRequestPrototype<App.Type, TaskParameterable, TaskRespondable>

public protocol AppRespondable {
    var request:AppTaskRequest { get }
    var info: TaskInfo { get }
    var appInfo: AppInfo { get }
}

extension AppRespondable {
    var appInfo: AppInfo {
        get{
            return self.request.appClass.info
        }
    }
}

public protocol AppTaskManagerDelegate: class {
    func didRespond(result: AppResult, progress:Double, remained:[AppRespondable], finished:[AppRespondable])
    func didFinish(results:[AppResult], for:[AppRespondable])
}

public protocol AppTaskManagerTaskDelegate: AppTaskManagerDelegate {
    func willPerformTask(info: AppRespondable)
    func didCompleteTask(info: AppRespondable)
    func didCancelTask(info: AppRespondable)
    func didFailTask(info: AppRespondable)
}

public class AppTaskManager: AppTaskOperationQueueOperationDelegate {

    static let shared = AppTaskManager(8)

    public weak var delegate:AppTaskManagerDelegate?

    let sharedSyncQueue:DispatchQueue = DispatchQueue(label:"com.stells.batch__internal_AppTaskManager")

    private var _queuePool = [String: AppTaskOperationQueue]()
    private var _requestedWorkItems = [String: AppTaskWorkItem]()

    private var _reactionItem: AppReactable?

    //TODO: improve queue assign performance
    private var _currentQueue: AppTaskOperationQueue {
        print("load queues",_queuePool.map{ $0.value.count } )
        return (_queuePool.min { a, b in a.value.count < b.value.count })!.value
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
        for var qn in 0 ..< maxConcurrentCount{
            let q = AppTaskOperationQueue(delegate:self)
            _queuePool[q.label] = q
        }
    }

    private func createTask(_ request:AppTaskRequest) -> Taskable?{
        let appInfo = request.appClass.info

        guard let appInstance = AppLifecycleManager.shared.acquire(appInfo)
        , let task = appInstance.instantiateTask(request.token)

                else {
            assert(false, "Task Creation was failed for an App \(request.appClass)")
            return nil
        }
        return Optional(task)
    }

    private func getCurrentWorkItems() -> [AppTaskWorkItem] {
        return _queuePool.values.flatMap { q -> [AppTaskWorkItem] in
            Array(q.iterator())
        }
    }

    public func query(by requestTokens:[String]) -> [TaskInfo] {
        return requestTokens.flatMap { token -> TaskInfo? in
            _requestedWorkItems[token]?.info
        }
    }

    public func request(_ request:AppTaskRequest) -> TaskInfo?{
        let info = append(request:request)
        perform(true)
        return info
    }

    public func remove(request:AppTaskRequest){
        sharedSyncQueue.sync(flags:.barrier){

            guard let queuedTaskItem = _requestedWorkItems[request.token]
            , let queueLabel = queuedTaskItem.info.queueLabel
            , let queue = self._queuePool[queueLabel]

                    else {
                assert(false, "a queue by the request is unqueued")
                return
            }

            guard let removedItem = (queue.remove { item -> Bool in
                if queue.currentTask != nil && item.info == queue.currentTask {
                    return false
                }
                return item.info.requestToken == request.token
            })
                    else {
                print("[i] The item doest not exist, but try to remove. It might be already dequeued.")
                return
            }

            assert(removedItem.info.requestToken==request.token)
            _requestedWorkItems.removeValue(forKey: removedItem.info.requestToken)
        }
    }

    //TODO: improve item append performance.
    public func append(request:AppTaskRequest) -> TaskInfo?{
        return sharedSyncQueue.sync(flags:.barrier){

            if let queued = self.query(by:[request.token]).first {
                assert(queued.state != .unqueued, "queued.state is unqueued")
                return queued
            }

            guard let task: Taskable = createTask(request) else {
                return nil
            }

            let item = AppTaskWorkItem(
                    request: request
                    , info: task.info
                    , task: task
                    , result: nil
            )

            self._currentQueue.enqueue(item)
            _requestedWorkItems[item.request.token] = item

            return item.task.info
        }
    }

    private func perform(_ preventIfSuspended:Bool=false) -> Bool {
        if _queuePool.count==0 {
            return false
        }

        for var queue in _queuePool.values{
            if preventIfSuspended && queue.suspended{
                return false
            }
            queue.perform()
        }

        return true
    }

    public func perform(_ reaction: AppReactable?=nil) -> Bool {
        if reaction != nil{
            sharedSyncQueue.sync(flags:.barrier){ [unowned self] in
                self._reactionItem = reaction
            }
        }
        return perform(false)
    }

    public func cancel(){
        _queuePool.forEach { (k,v) in v.cancel() }
    }

    public func suspend(){
        _queuePool.forEach { (k,v) in v.suspend() }
    }

    func mainOperationQueue() -> DispatchQueue{
        return DispatchQueue.main
    }

    func willPerformTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskWorkItem) {
        (self.delegate as? AppTaskManagerTaskDelegate)?.willPerformTask(info: workItem)
    }

    func didFailTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskWorkItem) {
        (self.delegate as? AppTaskManagerTaskDelegate)?.didFailTask(info: workItem)
    }

    func didCompleteTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskWorkItem) {
        (self.delegate as? AppTaskManagerTaskDelegate)?.didCompleteTask(info: workItem)
    }

    func didCancelTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskWorkItem) {
        (self.delegate as? AppTaskManagerTaskDelegate)?.didCancelTask(info: workItem)
    }

    func didFinishAllTasksInQueue(_ queue: AppTaskOperationQueue, _ result: AppTaskOperationQueueResultItem) {

        if let finishedWorkItems = result.finished{
            sharedSyncQueue.sync(flags:.barrier){
                for var workItem in finishedWorkItems{
                    _countFinishedTaskByEachQueues(queue, workItem)
                }
            }
        }
    }

    //counter
    //TODO: multi-apps for each requestToken
    private var _responsesForEachApps = [String: AppResult]()
    private var _respondedWorkItems = [AppRespondable]()

    private func _countFinishedTaskByEachQueues(_ queue: AppTaskOperationQueue, _ workItem: AppTaskWorkItem) {
        let appClass = workItem.request.appClass
        let appInfo = appClass.info
        let appId = appInfo.identifier

        if !_responsesForEachApps.keys.contains(appId){
            _responsesForEachApps[appId] = AppResult(info: appInfo, results: [TaskRespondable]())
        }
        _responsesForEachApps[appId]?.results.append(workItem)

        _respondedWorkItems.append(workItem)
        _requestedWorkItems.removeValue(forKey: workItem.info.requestToken)

        print("Remaining tasks: ",_requestedWorkItems.count)

        //progress
        if let currentResult = _responsesForEachApps[appId]{
            let creq = _requestedWorkItems.count
            let cres = _respondedWorkItems.count
            let progress = Double(cres)/Double(creq + cres)
            let remainedResponses = Array(self._requestedWorkItems.values)

            self.mainOperationQueue().async { [unowned self] in

                self.delegate?.didRespond(result: currentResult
                        , progress: progress
                        , remained: remainedResponses
                        , finished: self._respondedWorkItems)

                self._reactionItem?.progressHandler?(
                        currentResult
                        ,progress
                        ,remainedResponses
                        ,self._respondedWorkItems
                )
            }
        }

        //all finished
        if _requestedWorkItems.count==0 {
            let finalResults = self._finializeAllAppTasks(_responsesForEachApps)
            let respondedWorkItems = self._respondedWorkItems

            self.mainOperationQueue().async { [unowned self] in
                self._reactionItem?.finishHandler?(finalResults, respondedWorkItems)
                self.delegate?.didFinish(results: finalResults, for: respondedWorkItems)
            }

            //clean buffered results
            _requestedWorkItems.removeAll()
            _responsesForEachApps.removeAll()
        }
    }

    private func _finializeAllAppTasks(_ resultByApps:[String: AppResult]) -> [AppResult] {
        let asyncSignal = TaskDefaultSignal()
        var finalizedResults = [AppResult]()

        for var result in resultByApps.values {
            guard let appInstance = AppLifecycleManager.shared.acquire(result.info) else{
                assert(false,"App doest not exist any longer. Check it on lifecycle manager.")
                continue
            }

            if let appInstanceAsFinalizable = appInstance as? AppFinalizable {
                finalizedResults.append(appInstanceAsFinalizable.finalizeTasks(result, asyncSignal))
            }else{
                finalizedResults.append(result)
            }

            if result.info.lifeCycleUnit == .performCycle {
                AppLifecycleManager.shared.discard(result.info)
                assert(!AppLifecycleManager.shared.acquired.contains(result.info.identifier))
            }
        }

        return finalizedResults
    }
}
