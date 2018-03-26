//
// Created by BLACKGENE on 26/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import XCTest
@testable import batch

class AppTaskTests: XCTestCase {
    let taskMan = AppTaskManager.shared(4)

    override func setUp() {

        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_AppTaskManager_requests(){
        let e = self.expectation(description: "request will be succeed.")

        for i in 0..<50{
            taskMan.append(request: AppTaskRequest(TestApp.self, TestTaskParam(id:i)))
        }

        let performed = taskMan.perform(AppTaskReaction { dictionary, respondables in
            e.fulfill()
        })

        XCTAssertTrue(performed)
        waitForExpectations(timeout: 10) { (e) in
            XCTAssertTrue(true)
        }
    }

    func test_AppTaskManager_suspend(){
        let e = self.expectation(description: "request will be succeed.")

        for i in 0..<50{
            taskMan.append(request: AppTaskRequest(TestApp.self, TestTaskParam(id:i)))
        }

        let performed = taskMan.perform { dictionary, respondables in
            e.fulfill()
        }

        XCTAssertTrue(performed)
        DispatchQueue.global().async{
            self.taskMan.suspend()
            print("suspended until 7 secs ...")
            sleep(7)
            self.taskMan.perform()
        }

        waitForExpectations(timeout: pow(10,8)) { (e) in
            XCTAssertTrue(true)
        }
    }

    func test_AppTaskManager_remove(){
        let e = self.expectation(description: "request will be succeed.")

        let rqs = [Int](0..<50).map{ i -> AppTaskRequest in
            AppTaskRequest(TestApp.self, TestTaskParam(id:i))
        }
        let removalRqs = rqs[4..<8]

        for r in rqs{
            taskMan.append(request: r)
        }

        let performed = taskMan.perform { dictionary, respondables in
            print(respondables.count,rqs.count-removalRqs.count)
            if respondables.count == rqs.count-removalRqs.count{
                e.fulfill()
            }else{
                XCTFail()
            }
        }

        for r in removalRqs{
            self.taskMan.remove(request:r)
        }

        XCTAssertTrue(performed)

        waitForExpectations(timeout: pow(10,8)) { (e) in
            XCTAssertTrue(true)
        }
    }
}