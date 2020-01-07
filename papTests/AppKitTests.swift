//
// Created by BLACKGENE on 26/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import XCTest

@testable import pap

class AppTaskTests: XCTestCase {
    let taskMan = AppTaskManager(4)

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

    func test_AppTaskManager_concurrentCount(){

        class TestPreferredConcurrentCountApp: App {
            public static let taskType: AppTaskable.Type = _TestConcurrentCountAppTask.self

            public static let paramType: AppTaskParamable.Type = TestTaskParam.self

            public static let info = AppInfo(
                    identifier: "com.stells.batch.TestPreferredConcurrentCountApp"
                    , version: "0.1"
                    , phase: .develop
                    , appType: TestPreferredConcurrentCountApp.self
                    , displayName: "TestPreferredConcurrentCountApp", description:nil, keywords:nil
                    , icon: nil
                    , themeColor: nil, policy: AppPolicy.default
                    , minOSVersion: nil
            )
            public required init() {}
        }

        class _TestConcurrentCountAppTask: AppTaskPrototype, AppTaskable {
            override var info: AppTaskInfo {
                let info = super.info

                info.policy.estimatedConcurrencyCount = 2

                return info
            }

            public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){}

            public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
                async.begin()
                DispatchQueue.global().async{
                    sleep(UInt32(arc4random_uniform(2)))
                    async.end()
                }
                async.waitUntilEnd()
                return TestTaskResult(id:(param as! TestTaskParam).id)
            }
        }

        let e = self.expectation(description: "request will be succeed.")

        for i in 0..<50{
            let request = AppTaskRequest(TestPreferredConcurrentCountApp.self, TestTaskParam(id:i))
//            request.taskPolicy = TaskPolicy.default

            taskMan.append(request: request)
        }

        let performed = taskMan.perform(AppTaskReaction { dictionary, respondables in
            e.fulfill()
        })

        XCTAssertTrue(performed)
        waitForExpectations(timeout: 1000) { (e) in
            XCTAssertTrue(true)
        }
    }

    func test_AppGroup(){
        var appGroupIndexes = [String:Int]()
        let apps:[App.Type] = [SiriApp.self, ConverterApp.self, FinderApp.self, MemoCamApp.self,CleanerApp.self]

        for g in apps.sorted(by:{ (app1, app2) -> Bool in
            return app1.group.priority < app2.group.priority

        }) where appGroupIndexes[g.group.identifier] == nil{
            appGroupIndexes[g.group.identifier] = appGroupIndexes.keys.count
        }

        XCTAssertTrue(appGroupIndexes.keys.count==3)

        var groupingApps = [[App.Type]]()
        for app in apps {
            let group:Int
            if let indexOfGroupedApp = appGroupIndexes[app.group.identifier] {
                group = indexOfGroupedApp
            } else {
                group = 0
            }
            groupingApps[group].append(app)
        }

        print(groupingApps)
    }
}

public protocol AIDetectorApp: App{}
extension AIDetectorApp{
    public static var group: AppGroup{
        return AppGroup(identifier: "1", priority: 0, name: nil)
    }
}

public protocol PhotoManApp: App{}
extension PhotoManApp{
    public static var group: AppGroup{
        return AppGroup(identifier: "2", priority: 41, name: nil)
    }
}

extension FinderApp: AIDetectorApp{}
extension MemoCamApp: AIDetectorApp{}

extension ConverterApp: PhotoManApp{}
extension CleanerApp: PhotoManApp{}

