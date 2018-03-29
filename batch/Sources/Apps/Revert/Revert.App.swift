//
// Created by BLACKGENE on 20/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import DefaultsKit

private typealias RevertAppParam = PHAssetItem<AppValue>

public class RevertApp: NSObject, KeyPathWatchable, App, FinalizableApp, PersistableApp, AppManagerDelegatableApp, PhotoPickerViewControllerDisplayableApp, PhotoPickerCollectionViewDisplayableApp {
    public static let taskType:Taskable.Type = _RevertAppTask.self

    public static let paramType:TaskParamable.Type = RevertAppParam.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.revert"
            , version: "1.0"
            , phase: .beta
            , appType: RevertApp.self
            , displayName: "Revert"
            , icon: R.image.revertAppIcon.name
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    required public override init(){
        super.init()
    }

    private lazy var adjustedCache = [String:Bool]()

    public func willSetCurrent(oldCurrent: App.Type?) {
        print("willSetCurrent")
        adjustedCache.removeAll()
        print(adjustedCache.count)
    }

    public func isItemEnables(for item: PHAssetItem<AppValue>) -> Bool {
        let cacheId = item.asset.localIdentifier
        if adjustedCache[cacheId] == nil{
            adjustedCache[cacheId] = item.asset.isAdjusted
        }
        return adjustedCache[cacheId] ?? true
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        let resultAssets = result.flatMap { ($0.result as? PHAssetResultable)?.asset }

        guard resultAssets.count > 0 else {
            return result
        }

        asyncSignal.begin()

        PHPhotoLibrary.shared().performChanges({
            for asset in resultAssets{
                PHAssetChangeRequest(for: asset).revertAssetContentToOriginal()
            }
        }, completionHandler: { success, error in
            if !success {
                print("[!] Can't revert asset: \(String(describing: error))")
            }

            asyncSignal.end()
        })

        asyncSignal.stopUntilEnd()
        return result
    }

    public func titleWillBegin() -> String? {
        return "Starting to revert...".localized
    }

    public func titleWillFinalize() -> String? {
        return "Reverting Photos...".localized
    }
}

private class _RevertAppTask: TaskPrototype, Taskable {
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable?){}

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable?) throws -> TaskResultable? {
        assert(param is RevertAppParam, "TaskParamable type of this app is \(RevertAppParam.self)")

        guard let _param = param as? RevertAppParam else{
            throw TaskError.invalidParam
        }

        guard _param.asset.isAdjusted else{
            throw TaskError.rejectedParam
        }

        return PHAssetResultItem(asset:_param.asset, contentEditingOutput: nil)
    }
}

