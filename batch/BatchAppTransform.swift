//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import QuartzCore

class BatchApp_Transfrom: BatchApp, BatchAppFinalizable{

    override public class var info: BatchAppInfo{
        get{
            let info = BatchAppInfo("com.stells.batch.transform", self)
            info.displayName = "Transform"
            info.iconImage = ImageSourceItem("batchappicon_transfrom.pdf")
            return info
        }
    }

    private class _TransfromTask: BatchTaskPrototype, BatchTaskable{

        public func cancel(_ async:BatchTaskAsyncSignalable?){
            print("--->", #function, type(of:self), self.info.requestToken)
        }

        public func perform(_ param:BatchTaskParameterable,_ async:BatchTaskAsyncSignalable?) throws -> BatchTaskResultable?  {

            async?.begin()
            param.configs

            let c = CACurrentMediaTime()
            DispatchQueue.global().async {
                sleep(UInt32(arc4random_uniform(2)))
                print("--->", #function, type(of:self), self.info.requestToken, CACurrentMediaTime()-c)
                async?.end()
            }

            async?.stopUntilEnd()

            return nil
        }
    }

    override public func taskClass() -> BatchTaskable.Type {
        return _TransfromTask.self
    }

    public func finalizeTasks(_ response: BatchAppResult, _ asyncSignal: BatchTaskAsyncSignalable) -> BatchAppResult {
//        asyncSignal.begin()

        print("------------->"
                , #function
                , type(of:self)
                , response.results.map{ ($0.info.requestToken, $0.info.token, $0.info.state) }
        )

        print("Result Status ---> total: ", response.results.count)
        let statuses:[BatchTaskState] = [
            .unqueued
            ,.idling
            ,.performing
            ,.cancelled
            ,.failed
            ,.completed
        ]

        for var s in statuses{
            print(s, response.results.filter{ $0.info.state==s }.count)
        }

//        asyncSignal.end()
//        asyncSignal.stopUntilEnd()

        return response
    }
}
