//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public typealias AppTaskRequest = TaskRequest<Appable.Type, TaskParamable, AppTaskRespondable>

public protocol AppTaskManagerDelegate: class {
    func didRespond(forCurrent: AppTaskRespondable, progress:Float, remained:[AppTaskRespondable], finished:[AppTaskRespondable])
    func didFinish(forEachApps:[AppInfo:[AppTaskRespondable]], forAll:[AppTaskRespondable])
}

public protocol AppTaskManagerTaskDelegate: AppTaskManagerDelegate {
    func willPerformTask(info: AppTaskRespondable)
    func didCompleteTask(info: AppTaskRespondable)
    func didCancelTask(info: AppTaskRespondable)
    func didFailTask(info: AppTaskRespondable)
}

public class AppTaskManager: AppTaskOperationQueueDelegate {

    fileprivate static let sharedSyncQueue:DispatchQueue = DispatchQueue(label:"com.stells.batch__shared_AppTaskManager")

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

    private let syncQueue:DispatchQueue = DispatchQueue(label:"com.stells.batch__internal_AppTaskManager"+UUID().uuidString)
    private var _queuePool = [String: AppTaskOperationQueue]()

    //react
    private var _reactionItem: AppTaskReactable?

    //result collection
    private var _staticResponsesForEachApps = [AppInfo: [AppTaskRespondable]]()
    private var _staticRequestedWorkItems = [String: AppTaskWorkItem]()
    private var _staticRespondedWorkItems = [AppTaskWorkItem]()

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
        for _ in 0 ..< maxConcurrentCount{
            let q = AppTaskOperationQueue(delegate:self)
            _queuePool[q.label] = q
        }
    }

    private func createTask(_ request:AppTaskRequest) -> Taskable?{
        let appInfo = request.appClass.info

        guard let _ = AppLifecycleManager.shared.acquire(appInfo) else {
            assert(false, "Task Creation was failed for an App \(request.appClass)")
            return nil
        }

        let taskClass = appInfo.appClass.taskClass
        let task = taskClass.init(TaskInfo(request.token, taskClass.self))
        return Optional(task)
    }

    private func getCurrentWorkItems() -> [AppTaskWorkItem] {
        return _queuePool.values.flatMap { q -> [AppTaskWorkItem] in
            Array(q.iterator())
        }
    }

    //TODO: query by all of each request's properties.
    public func query(by requestTokens:[String]) -> [TaskInfo] {
        return requestTokens.flatMap { token -> TaskInfo? in
            _staticRequestedWorkItems[token]?.info
        }
    }

    @discardableResult
    public func request(_ request:AppTaskRequest) -> TaskInfo?{
        let info = append(request:request)
        perform(true)
        return info
    }

    public func remove(request:AppTaskRequest){
        syncQueue.sync(flags:.barrier){

            guard let queuedTaskItem = _staticRequestedWorkItems[request.token]
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

            let item = AppTaskWorkItem(
                    request: request
                    , info: task.info
                    , task: task
            )

            self._currentQueue.enqueue(item)
            _staticRequestedWorkItems[item.request.token] = item

            return item.task.info
        }
    }
    
    @discardableResult
    private func perform(_ preventIfSuspended:Bool=false) -> Bool {
        if _queuePool.count==0 {
            return false
        }

        for queue in _queuePool.values {
            if preventIfSuspended && queue.suspended{
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

        syncQueue.sync(flags:.barrier){
            _countFinishedTaskByEachQueues(queue, workItem)
        }
    }

    func didCompleteTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskWorkItem) {
        (self.delegate as? AppTaskManagerTaskDelegate)?.didCompleteTask(info: workItem)

        syncQueue.sync(flags:.barrier){
            _countFinishedTaskByEachQueues(queue, workItem)
        }
    }

    func didCancelTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskWorkItem) {
        (self.delegate as? AppTaskManagerTaskDelegate)?.didCancelTask(info: workItem)

        syncQueue.sync(flags:.barrier){
            _countFinishedTaskByEachQueues(queue, workItem)
        }
    }

    func didFinishAllTasksInQueue(_ queue: AppTaskOperationQueue, _ result: [AppTaskWorkItem]?) {

//        if let finishedWorkItems = result.finished{
//            syncQueue.sync(flags:.barrier){
//                for var workItem in finishedWorkItems{
//                    _countFinishedTaskByEachQueues(queue, workItem)
//                }
//            }
//        }
    }

    //counter
    //TODO: multi-apps for each requestToken

    private func _countFinishedTaskByEachQueues(_ queue: AppTaskOperationQueue, _ workItem: AppTaskWorkItem) {
        let appClass = workItem.request.appClass
        let appInfo = appClass.info

        if !_staticResponsesForEachApps.keys.contains(appInfo){
            _staticResponsesForEachApps[appInfo] = [AppTaskRespondable]()
        }
        _staticResponsesForEachApps[appInfo]?.append(workItem)

        _staticRespondedWorkItems.append(workItem)
        _staticRequestedWorkItems.removeValue(forKey: workItem.info.requestToken)

        print("Remaining tasks: ", _staticRequestedWorkItems.count)

        //progress
        let creq = _staticRequestedWorkItems.count
        let cres = _staticRespondedWorkItems.count
        let progress = Float(cres)/Float(creq + cres)
        let remainedResponses = Array(self._staticRequestedWorkItems.values)
        let finishedResponses = self._staticRespondedWorkItems

        self.mainOperationQueue().async { [unowned self] in

            self.delegate?.didRespond(forCurrent: workItem
                    , progress: progress
                    , remained: remainedResponses
                    , finished: finishedResponses)

            self._reactionItem?.progressHandler?(
                    workItem
                    ,progress
                    ,remainedResponses
                    ,finishedResponses
            )
        }

        //all finished
        if _staticRequestedWorkItems.count==0 {
            let responseForEachApps = self._finializeAllAppTasks(_staticResponsesForEachApps)
            let respondedWorkItems = self._staticRespondedWorkItems

            self.mainOperationQueue().async { [unowned self] in
                self._reactionItem?.finishHandler?(responseForEachApps, respondedWorkItems)
                self.delegate?.didFinish(forEachApps: responseForEachApps, forAll: respondedWorkItems)
            }

            //clean buffered results
            _staticRespondedWorkItems.removeAll()
            _staticRequestedWorkItems.removeAll()
            _staticResponsesForEachApps.removeAll()
        }
    }

    private func _finializeAllAppTasks(_ resForEachApps:[AppInfo: [AppTaskRespondable]]) -> [AppInfo: [AppTaskRespondable]] {
        let asyncSignal = TaskDefaultSignal()
        var finalizedResults = [AppInfo: [AppTaskRespondable]]()

        for (appInfo, reses) in resForEachApps{
            guard let appInstance = AppLifecycleManager.shared.acquire(appInfo) else{
                assert(false,"App doest not exist any longer. Check it on lifecycle manager.")
                continue
            }

            if let appInstanceAsFinalizable = appInstance as? FinalizableAppable {
                finalizedResults[appInfo] = appInstanceAsFinalizable.finalize(result: reses, asyncSignal)
            }else{
                finalizedResults[appInfo] = reses
            }

            if appInfo.lifeCycleUnit == .performCycle {
                AppLifecycleManager.shared.discard(appInfo)
                assert(!AppLifecycleManager.shared.acquired.contains(appInfo.identifier))
            }
        }

        return finalizedResults
    }
}
