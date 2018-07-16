//
//  Camera.BApp.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 7. 10..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import PhotosUI
import DefaultsKit

protocol CameraAppDefaults: AppDefaults, AppUICameraViewOptions {
    //INFO: extend app-specific properties if needed,
    // app developer can manually implement, decide or define whether storing values or getting default in app scope.
}

extension Defaults: CameraAppDefaults {
    var isLivePhotoEnabled: Bool {
        set { set(newValue) }
        get { return get(or: false) }
    }

    var cameraPosition: AVCaptureDevice.Position {
        set { set(newValue.rawValue) }
        get { return AVCaptureDevice.Position(rawValue: get(or: AVCaptureDevice.Position.back.rawValue)) ?? .back }
    }
}

class CameraApp: NSObject, KeyPathWatchable, BApp, LaunchableApp, AppDockApp, PhotoPickerCollectionViewDisplayableApp {
    public static let taskType: AppTaskable.Type = _CameraAppTask.self
    
    public static let paramType: AppTaskParamable.Type = PHAssetItem<ImageEditStateValue>.self
    
    public private(set) lazy var dockContent: AppDockContent? = CameraAppDockContent()
    
    public static let info = AppInfo(
        identifier: "com.stells.pap.camera"
        , version: "1.0"
        , phase: .release
        , appType: CameraApp.self
        , displayName: "Camera".localized, description:nil, keywords:nil
        , iconBundleName: R.image.cameraBAppIcon.name
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    public required override init() {}
    
    func shouldSelect(item: AppAsset) -> Bool {
        return false
    }

    func didResign(current: App.Type?) {

    }

    fileprivate var importedLaunchOption: AppLaunchOption? = nil

    func didLaunch(previous: App.Type?, withOption: AppLaunchOption?) {
        importedLaunchOption = withOption
    }
}

class CameraAppView: AppUICameraView {}

fileprivate class CameraAppDockContent: NSObject, KeyPathWatchable, AppDockContent, AppDockDelegate {
    lazy var view: UIView = {
        return CameraAppView(frame: .zero, options:CameraApp.defaults as! CameraAppDefaults)
    }()

    private var cameraView: CameraView? {
        return (view as? CameraAppView)?.cameraView
    }

    var preferences: AppDockContentPreferable? {
        let pref = AppDockContentPreferences()
        return pref
    }

    func willSetContentView(_ view: UIView, dock: AppDock) {

    }

    func didSetContentView(_ view: UIView, dock: AppDock) {
        cameraView?.startSession()

        if let pref = preferences, view.bounds.height > pref.preferredHeight {
            (view as? CameraAppView)?.isCompactMode = false
        }
        
        var capturedHandlerResult:CaptureProcessorResult?
        cameraView?.capturedHandler = { succeed, results in
            capturedHandlerResult = results

//            if let results = capturedHandlerResult{
//                let data = [
//                    AppLaunchOptionsKey.capturedPhotoURL: results[CaptureProcessorResultKey.photoURL]
//                    , AppLaunchOptionsKey.capturedPairedVideoURL: results[CaptureProcessorResultKey.pairedVideoURL]
//                ]
//                self.didCaptured(with:data)
//            }
        }
        
        PHPhotoLibraryManager.default.watch(\.changes) {
            guard let changeInstance = PHPhotoLibraryManager.default.changes else {
                return
            }
            
            if let results = capturedHandlerResult, let last = PHAssets.fetched.results?.last{
                if let insertedAssets = changeInstance.changeDetails(for: last)?.insertedObjects{
                    for asset in insertedAssets {
                        
                        let data = [
                            AppLaunchOptionsKey.PHAsset: asset
                            , AppLaunchOptionsKey.PhotoURL: results[CaptureProcessorResultKey.photoURL]
                            , AppLaunchOptionsKey.PairedVideoURL: results[CaptureProcessorResultKey.pairedVideoURL]
                        ]
                        self.didCaptured(with:data)
                        break
                    }
                }
            }
        }
    }
    
    func didCaptured(with data:[AppLaunchOptionsKey:Any?]){
        if let option = AppCenter.default.currentInstanceAs(CameraApp.self)?.importedLaunchOption
            , let id = option.identifierToReturn{

            AppCenter.default.openApp(identifier: id, options:AppLaunchOption(options: data), animation:true)
        }
    }

    func willRemoveContentView() {
        cameraView?.stopSession()
    }

    var delegate: AppDockDelegate? {
        return self
    }

    func dockWillExpand(_ dock: AppDock) {
        (view as? CameraAppView)?.isCompactMode = false
    }

    func dockWillContract(_ dock: AppDock) {
        (view as? CameraAppView)?.isCompactMode = true
    }
}

private class _CameraAppTask: AppTaskPrototype, AppTaskable {
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){}
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        return nil
    }
}




