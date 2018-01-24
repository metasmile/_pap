//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


struct BatchAppTaskWorkItem: TaskRespondable, BatchAppRespondable, Equatable {
    let request:BatchAppTaskRequest
    let info: TaskInfo
    let task: Taskable

    fileprivate(set) var result: TaskResultable?
}

extension BatchAppTaskWorkItem {

    // if canceled by requester, return false, passed, return true
    func response(_ state: TaskState) -> Bool{
        task.info.state = state
        var canceled = false
        request.responseHandler?(self, &canceled)
        return !canceled
    }

    static func ==(lhs: BatchAppTaskWorkItem, rhs: BatchAppTaskWorkItem) -> Bool {
        let lhsInfo = lhs.info, rhsInfo = rhs.info
        return lhsInfo.token == rhsInfo.token
                && lhsInfo.requestToken == rhsInfo.requestToken
                && lhsInfo.taskType == rhs.info.taskType
                && lhsInfo.state == rhsInfo.state
    }
}

struct BatchTaskOperationQueueResultItem {
    var finished:[BatchAppTaskWorkItem]?
}

protocol BatchTaskOperationQueueOperationDelegate: class {
    func mainOperationQueue() -> DispatchQueue

    func willPerformTask(_ queue: BatchAppTaskOperationQueue, _ workItem: BatchAppTaskWorkItem)
    func didCompleteTask(_ queue: BatchAppTaskOperationQueue, _ workItem: BatchAppTaskWorkItem)
    func didCancelTask(_ queue: BatchAppTaskOperationQueue, _ workItem: BatchAppTaskWorkItem)
    func didFailTask(_ queue: BatchAppTaskOperationQueue, _ workItem: BatchAppTaskWorkItem)

    func didFinishAllTasksInQueue(_ queue: BatchAppTaskOperationQueue, _ result: BatchTaskOperationQueueResultItem)
}

class BatchAppTaskOperationQueue: ItemQueue<BatchAppTaskWorkItem> {

    private var finshedQueue = ItemQueue<BatchAppTaskWorkItem>()
    private weak var delegate: BatchTaskOperationQueueOperationDelegate?

    private(set) public var currentTask: TaskInfo?
    private(set) public var cancelled = false
    private(set) public var suspended = false

    private let queue:DispatchQueue = DispatchQueue(
            label: "com.stells_internal_\(UUID().uuidString)"
            , qos: .utility
            , attributes: []
            , autoreleaseFrequency: .workItem
            , target: nil
    )

    private let asyncSignal = TaskDefaultSignal()

    internal var label:String{
        return self.queue.label
    }

    required init(delegate: BatchTaskOperationQueueOperationDelegate) {
        self.delegate = delegate
    }

    //overriden
    final func isEnqueued(_ item: BatchAppTaskWorkItem) -> Bool{
        return self.iterator().contains { e -> Bool in
            e.info.requestToken == item.info.requestToken
        }
    }

    override func enqueue(_ item: BatchAppTaskWorkItem, reverse: Bool=false) {
        if isEnqueued(item) { return }

        item.info.queueLabel = self.label
        item.info.state = .idling
        super.enqueue(item, reverse:reverse)
    }

    //external interface
    private var mainOperationQueue:DispatchQueue {
        return self.delegate?.mainOperationQueue() ?? DispatchQueue.main
    }

    private func dispatchState(_ item: BatchAppTaskWorkItem, _ state: TaskState) -> Bool{
        let response = item.response(state)

        let d = self.delegate

        var exe:(() -> Void)?

        switch(item.info.state){
        case .performing:
            exe = { d?.willPerformTask(self, item) }

        case .cancelled:
            exe = { d?.didCancelTask(self, item) }

        case .failed:
            exe = { d?.didFailTask(self, item) }

        case .completed:
            exe = { d?.didCompleteTask(self, item) }

        default:
            assert(false, "item.info.state was wrongly setted [state]" + String(describing:item.info.state))
        }

        if let _exe = exe{
            self.mainOperationQueue.async(execute: _exe)
        }

        print("> "
                , item.info.state
                , item.task.info.requestToken, "->"
                , item.task.info.token, "->"
                , self.queue.label)

        return response
    }

    private func dispatchFinishedResults(){
        let queueResult = BatchTaskOperationQueueResultItem(finished: self.finshedQueue.dequeueAll())
        self.mainOperationQueue.async {
            self.delegate?.didFinishAllTasksInQueue(self, queueResult)
        }
    }

    private func tryItem(_ item: BatchAppTaskWorkItem, _ async: TaskAsyncSignalable, cancel:Bool=false){
        guard !cancel && self.dispatchState(item, .performing) else{
            item.task.cancel(async)
            self.dispatchState(item, .cancelled)
            return
        }

        do {
            var _mutableItem = item
            _mutableItem.result = try item.task.perform(item.request.param, async)
            self.dispatchState(_mutableItem, .completed)

        } catch _ {
            self.dispatchState(item, .failed)
        }
    }

    func perform() {
        if suspended{
            suspended = false
            return
        }

        guard let item = self.peek() else {
            if currentTask != nil {
                currentTask = nil
                cancelled = false

                dispatchFinishedResults()

                print("-------> finished queue", self.queue.label)
            }
            return
        }

        guard currentTask?.token != item.info.token else {
            return
        }
        assert(item.info != nil, "item.info must not be nil")

        currentTask = item.info

        let _cancelled = self.cancelled

        queue.async { [unowned self] in

            self.tryItem(item, self.asyncSignal, cancel: _cancelled)

            self.mainOperationQueue.async{

                // dequeue
                guard let finishedItem = self.dequeue() else {
                    assert(false,"dequeued item must not be nil at here.")
                    return
                }
                self.finshedQueue.enqueue(finishedItem)

                // discard app if configured
                if finishedItem.appInfo.lifeCycleUnit == .task {
                    BatchAppLifecycleManager.shared.discard(finishedItem.appInfo)
                    assert(!BatchAppLifecycleManager.shared.acquired.contains(finishedItem.appInfo.identifier))
                }

                // perform next task
                self.perform()
            }
        }
    }

    func cancel(){
        assert(self.count>0, "There is not existed any items, but tried to cancel.")
        assert(cancelled==false, "cancelled is already true. What's wrong??")

        if self.count==0{
            return
        }

        cancelled = true

        if currentTask == nil{
            perform()
        }
    }

    func suspend(){
        if self.count==0 || currentTask == nil{
            return
        }

        suspended = true
    }
}
