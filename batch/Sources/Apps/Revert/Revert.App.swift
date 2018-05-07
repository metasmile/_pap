//
// Created by BLACKGENE on 20/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import DefaultsKit

private typealias RevertAppParam = PHAssetItem<ImageEditStateValue>

public class RevertApp: NSObject, KeyPathWatchable, BApp, FinalizableApp, AppManagerDelegatableApp, PhotoPickerViewControllerDelegatableApp, PhotoPickerCollectionViewDisplayableApp {
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

    fileprivate var adjustedCache = [String:Bool]()

    func willSetPrevious(newCurrent: App.Type?) {
        adjustedCache.removeAll()
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        let cacheId = item.asset.localIdentifier
        if adjustedCache[cacheId] == nil{
            adjustedCache[cacheId] = item.asset.isAdjusted //TODO: find more fast way
        }
        return adjustedCache[cacheId] ?? true
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        let resultAssets = result.compactMap { ($0.result as? PHAssetResultable)?.asset }

        guard resultAssets.count > 0 else {
            return result
        }

        asyncSignal.begin()

        PHPhotoLibrary.shared().performChanges({
            for asset in resultAssets{
                PHAssetChangeRequest(for: asset).revertAssetContentToOriginal()
            }
        }, completionHandler: { success, error in
            if success {
                for asset in resultAssets{
                    self.adjustedCache[asset.localIdentifier] = false
                }
            }else{
                print("[!] Can't revert asset: \(String(describing: error))")
            }
            asyncSignal.end()
        })

        asyncSignal.waitUntilEnd()
        return result
    }

    public var titleWillBegin: String? {
        return "Starting to revert...".localized
    }

    public var titleWillFinalize: String? {
        return "Reverting Photos...".localized
    }
}

private class _RevertAppTask: TaskPrototype, Taskable {
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){}

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {
        assert(param is RevertAppParam, "TaskParamable type of this app is \(RevertAppParam.self)")

        guard let _param = param as? RevertAppParam else{
            throw TaskError.invalidParam
        }

        let cachedAdjusted = (AppLifecycleManager.shared.acquire(RevertApp.info) as? RevertApp)?.adjustedCache

        let adjusted = cachedAdjusted == nil ? _param.asset.isAdjusted : cachedAdjusted?[_param.asset.localIdentifier] == true

        guard adjusted else{
            throw TaskError.rejectedParam
        }

        return PHAssetResultItem(asset:_param.asset, contentEditingOutput: nil)
    }
}

