//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol AppTaskOperationQueueDelegate: class {
    func delegatingQueue(from:AppTaskOperationQueue) -> DispatchQueue

    func willPerformTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskItem)
    func didCompleteTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskItem)
    func didCancelTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskItem)
    func didFailTask(_ queue: AppTaskOperationQueue, _ workItem: AppTaskItem)

    func didFinishAllTasksInQueue(_ queue: AppTaskOperationQueue, _ result: [AppTaskItem]?)
}

class AppTaskOperationQueue: ItemQueue<AppTaskItem> {

    private var finshedQueue = ItemQueue<AppTaskItem>()
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

    private let asyncSignal = AsyncSignal()

    internal var label:String{
        return self.queue.label
    }

    required init(delegate: AppTaskOperationQueueDelegate) {
        self.delegate = delegate
    }

    //overriden
    final func isEnqueued(_ item: AppTaskItem) -> Bool{
        return self.iterator().contains { e -> Bool in
            e.info.requestToken == item.info.requestToken
        }
    }

    override func enqueue(_ item: AppTaskItem, reverse: Bool=false) {
        if isEnqueued(item) { return }

        item.info.queueLabel = self.label
        item.info.state = .idling
        super.enqueue(item, reverse:reverse)
    }

    //external interface
    private var _delegatingQueue:DispatchQueue {
        return self.delegate?.delegatingQueue(from: self) ?? DispatchQueue.main
    }

    private func dispatchFinishedForEach(item: AppTaskItem) {
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
            self._delegatingQueue.async(execute: _exe)
        }

        print("> "
                , item.info.state
                , item.task.info.requestToken, "->"
                , item.task.info.token, "->"
                , self.queue.label)
    }

    private func dispatchFinishedAll(){
        assert(self.count==0)
        assert(self.finshedQueue.count>0)
        print("dispatchFinishedResults", self.count, self.finshedQueue.count)

        let queueResult = self.finshedQueue.dequeueAll()
        self._delegatingQueue.async {
            self.delegate?.didFinishAllTasksInQueue(self, queueResult)
        }
    }

    private func tryItem(_ item: AppTaskItem, _ async: AsyncManualSignalable & AsyncControllableSignable, cancel:Bool=false){
        let param = item.request.param

        guard !cancel && item.response(.performing) else{
            async.done()
            item.task.cancel(param, async)
            item.response(.cancelled)
            return
        }

        do {

            if let result = try item.task.perform(param, async){
                item.result = result
                item.response(.completed)
                return
            }

            throw TaskError.invalidResult

        } catch let e as TaskError {
            async.done()
            item.response(.failed, e)

        } catch {
            async.done()
            item.response(.failed, TaskError.unknown)
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

                dispatchFinishedAll()

                print("-------> finished queue", self.queue.label)
            }
            return
        }

        guard currentTask?.token != item.info.token else {
            return
        }

        currentTask = item.info

        let _cancelled = self.cancelled

        queue.async { [unowned self] in

            self.tryItem(item, self.asyncSignal, cancel: _cancelled)

            self._delegatingQueue.async{

                // dequeue
                guard let finishedItem = self.dequeue() else {
                    assert(false,"dequeued item must not be nil at here.")
                    return
                }
                self.finshedQueue.enqueue(finishedItem)
                self.dispatchFinishedForEach(item:finishedItem)


                // discard app if configured
                if finishedItem.appInfo.policy.lifeCycleUnit == .singleTask {
                    AppLifecycleManager.shared.discard(finishedItem.appInfo)
                    assert(!AppLifecycleManager.shared.acquired.contains(finishedItem.appInfo.identifier))
                }

                // perform next task
                self.perform()
            }
        }
    }

    func cancel(){
        assert(cancelled==false, "cancelled is already true. What's wrong??")
        if cancelled || self.count==0{
            return
        }

        //cancel currently progressing item
        if let currentItem = self.peek() {
            //FIXME: not work in queue??
//            queue.async(flags:.barrier){ [unowned self] in
                self.tryItem(currentItem, self.asyncSignal, cancel: true)
//            }
        }

        //set cancel flag and then from next item may cancel before it performs.
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
