//
// Created by BLACKGENE on 26/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension NSObject{

    //HELLO: all the operations such as perform, request, cancel, suspend is time,queue-independent
    func helloAppTaskManager() {

        //HELLO: this means max 3 parrellel queues will be performed.
        AppTaskManager.shared(2)

        //HELLO: start immediately.
        let firstRequest = AppTaskRequest(
                HelloTypedBatchApp.self
                , HelloTypedBatchApp.paramClass.init(sources: [UIImage()], configs: [TransformEditItem()])
        )
        AppTaskManager.shared(2).request(firstRequest)

        //HELLO: append first to start lazily
        AppTaskManager.shared(2).append(request:AppTaskRequest(
                HelloTypedBatchApp.self
                , HelloTypedBatchApp.paramClass.init(sources: [UIImage()], configs: [TransformEditItem()])
        ))


        //HELLO: independent result of the request for each completion block
        let appCls = HelloTypedBatchApp.self
        let p = appCls.paramClass.init(sources: [UIImage()], configs: [TransformEditItem()])
        let r = AppTaskRequest(appCls, p) { res, cancel in
            res.info.state == .performing

            //HELLO: need to cancel (inout &cancel)
            cancel = true
         }
        AppTaskManager.shared(2).append(request:r)

        AppTaskManager.shared(2).append(request:AppTaskRequest(
                HelloTypedBatchApp.self

                //HELLO: can use already typed App-dependent parameter object via AppClass.paramClass.init( ... )
                , HelloTypedBatchApp.paramClass.init(sources: [UIImage() /* or PHAsset */], configs: [TransformEditItem()])
        ))

        
        //HELLO: start with reaction item
        let reaction = AppTaskReaction().when(progress:{ result, progress, remained, finished in
            //HELLO: progress -> whole progress. 0-1
            //HELLO: result -> lastly finished result for now
            //HELLO: remained -> remaining tasks
            //HELLO: finished -> finished tasks until now

        }).when(finish: { results, allResults, forResponses in
            //HELLO: results -> Whole results.
            //HELLO: forResponses -> forResponses request info etc...

            results.first?.key.identifier
        })

        let started = AppTaskManager.shared(2).perform(reaction)

        //HELLO: pause.
        AppTaskManager.shared(2).suspend()

        //HELLO: restart
        AppTaskManager.shared(2).perform()

        //HELLO: remove from current queue. can remove request while .idling
        AppTaskManager.shared(2).remove(request: firstRequest)

        //HELLO: cancel all apps.
        AppTaskManager.shared(2).cancel()
    }
}
