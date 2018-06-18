//
// Created by BLACKGENE on 20/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import DefaultsKit

private typealias RevertAppParam = PHAssetItem<ImageEditStateValue>
private struct RevertAppResult: TaskResultable{
    fileprivate let asset:PHAsset
    fileprivate let isAdjusted:Bool
}

public class RevertApp: NSObject, KeyPathWatchable, BApp, FinalizableApp, AppManagerDelegatableApp
        , PhotoPickerViewControllerDelegatableApp, PhotoPickerCollectionViewDisplayableApp {
    public static let taskType:Taskable.Type = _RevertAppTask.self

    public static let paramType:TaskParamable.Type = RevertAppParam.self

    public static let info = AppInfo(
            identifier: "com.stells.pap.revert"
            , version: "1.0"
            , phase: .release
            , appType: RevertApp.self
            , displayName: "Revert", description:nil, keywords:nil
            , iconBundleName: R.image.revertBAppIcon.name
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    required public override init(){
        super.init()
    }

    fileprivate var adjustedCache = [String:Bool]()

    func willSetCurrent(oldCurrent: App.Type?) {
        adjustedCache.removeAll()
    }

    func didSetCurrent(previous: App.Type?) {}

//    public func shouldSelect(item: AppAsset) -> Bool {
//        let cacheId = item.asset.localIdentifier
//        if adjustedCache[cacheId] == nil{
//            adjustedCache[cacheId] = item.asset.isAdjusted //TODO: find more fast way
//        }
//        return adjustedCache[cacheId] ?? true
//    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return true
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        let adjustedAssets = result.compactMap { r -> PHAsset? in
            let result = r.result as? RevertAppResult
            return result?.isAdjusted == true ? result?.asset : nil
        }

        guard adjustedAssets.count > 0 else {

            asyncSignal.begin()
            DispatchQueue.main.async {
                UIAlertController.alert("Cannot revert. All selected items have not edited.".localized, completion:{ _ in
                    asyncSignal.end()
                })
            }
            asyncSignal.waitUntilEnd()

            return result
        }

        asyncSignal.begin()

        PHPhotoLibrary.shared().performChanges({
            for asset in adjustedAssets {
                PHAssetChangeRequest(for: asset).revertAssetContentToOriginal()
            }
        }, completionHandler: { success, error in
            if success {
                for asset in adjustedAssets {
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
        return "Starting to check edited photos...".localized
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

//        let cachedAdjusted = AppCenter.default.currentInstanceAs(RevertApp.self)?.adjustedCache
//
//        let adjusted = cachedAdjusted == nil ? _param.asset.isAdjusted : cachedAdjusted?[_param.asset.localIdentifier] == true
//
//        guard adjusted else{
//            throw TaskError.rejectedParam
//        }

        return RevertAppResult(asset: _param.asset, isAdjusted: _param.asset.isAdjusted)
    }
}

