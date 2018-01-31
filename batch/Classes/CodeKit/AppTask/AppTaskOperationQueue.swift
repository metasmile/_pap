//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol AppTaskOperationQueueDelegate: class {
    func mainOperationQueue() -> DispatchQueue

    func willPerformTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskWorkItem)
    func didCompleteTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskWorkItem)
    func didCancelTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskWorkItem)
    func didFailTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskWorkItem)

    func didFinishAllTasksInQueue(_ queue: AppTaskOperationQueue, _ result: AppTaskResultItem)
}

class AppTaskOperationQueue: ItemQueue<AppTaskWorkItem> {

    private var finshedQueue = ItemQueue<AppTaskWorkItem>()
    private weak var delegate: AppTaskOperationQueueDelegate?

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

    required init(delegate: AppTaskOperationQueueDelegate) {
        self.delegate = delegate
    }

    //overriden
    final func isEnqueued(_ item: AppTaskWorkItem) -> Bool{
        return self.iterator().contains { e -> Bool in
            e.info.requestToken == item.info.requestToken
        }
    }

    override func enqueue(_ item: AppTaskWorkItem, reverse: Bool=false) {
        if isEnqueued(item) { return }

        item.info.queueLabel = self.label
        item.info.state = .idling
        super.enqueue(item, reverse:reverse)
    }

    //external interface
    private var mainOperationQueue:DispatchQueue {
        return self.delegate?.mainOperationQueue() ?? DispatchQueue.main
    }

    private func dispatchState(_ item: AppTaskWorkItem, _ state: TaskState) -> Bool{
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
        let queueResult = AppTaskResultItem(finished: self.finshedQueue.dequeueAll())
        self.mainOperationQueue.async {
            self.delegate?.didFinishAllTasksInQueue(self, queueResult)
        }
    }

    private func tryItem(_ item: inout AppTaskWorkItem, _ async: TaskAsyncSignalable, cancel:Bool=false){
        guard !cancel && self.dispatchState(item, .performing) else{
            item.task.cancel(async)
            self.dispatchState(item, .cancelled)
            return
        }

        do {
            item.result = try item.task.perform(item.request.param, async)

            self.dispatchState(item, .completed)

        } catch _ {
            self.dispatchState(item, .failed)
        }
    }

    func perform() {
        if suspended{
            suspended = false
            return
        }

        guard var item = self.peek() else {
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

            self.tryItem(&item, self.asyncSignal, cancel: _cancelled)

            self.mainOperationQueue.async{

                // dequeue
                guard let finishedItem = self.dequeue() else {
                    assert(false,"dequeued item must not be nil at here.")
                    return
                }
                self.finshedQueue.enqueue(finishedItem)

                // discard app if configured
                if finishedItem.appInfo.lifeCycleUnit == .task {
                    AppLifecycleManager.shared.discard(finishedItem.appInfo)
                    assert(!AppLifecycleManager.shared.acquired.contains(finishedItem.appInfo.identifier))
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
