//
// Created by BLACKGENE on 26/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension NSObject{

    func helloAppTaskManager() {

        //HELLO: this means max 3 parrellel queues will be performed.
        AppTaskManager.shared(3)

        AppTaskManager.shared(3).append(request:AppTaskRequest(
                TransformApp.self
                , TransformAppParam(sources: [UIImage() /* or PHAsset */], configs: [EditItem()])
        ))

        AppTaskManager.shared(3).append(request:AppTaskRequest(
                HelloTypedBatchApp.self
                , HelloTypedBatchApp.paramClass.init(sources: [UIImage() /* or PHAsset */], configs: [EditItem()])
        ))

    }
}