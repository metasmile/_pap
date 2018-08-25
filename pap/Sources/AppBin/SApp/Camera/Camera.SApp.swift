//
//  Camera.SApp.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 7. 10..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import PhotosUI
import PropertyKit

protocol CameraAppDefaults: AppDefaults, AppUICameraViewOptions {
    //INFO: extend app-specific properties if needed,
    // app developer can manually implement, decide or define whether storing values or getting default in app scope.
}

extension Defaults: CameraAppDefaults {
    var isLivePhotoEnabled: Bool {
        set { set(newValue); papLog.app.defaults.log(value:newValue) }
        get { return get(or: false) }
    }

    var cameraPosition: AVCaptureDevice.Position {
        set { set(newValue.rawValue); papLog.app.defaults.log(value:newValue.rawValue) }
        get { return AVCaptureDevice.Position(rawValue: get(or: AVCaptureDevice.Position.back.rawValue)) ?? .back }
    }

    var cameraFlashMode: AVCaptureDevice.FlashMode {
        set { set(newValue.rawValue); papLog.app.defaults.log(value:newValue.rawValue) }
        get { return AVCaptureDevice.FlashMode(rawValue: get(or: AVCaptureDevice.FlashMode.off.rawValue)) ?? .off }
    }
}

class CameraApp: NSObject, PropertyWatchable, SApp, LaunchableApp, AppDockApp, PhotoPickerCollectionViewDisplayableApp, AVCaptureDeviceApp {
    public static let taskType: AppTaskable.Type = _CameraAppTask.self
    
    public static let paramType: AppTaskParamable.Type = AppAsset.self
    
    public private(set) lazy var content: AppDockContent? = CameraAppDockContent()
    
    public static let info = AppInfo(
        identifier: "com.stells.pap.camera"
        , version: "1.0"
        , phase: .release
        , appType: CameraApp.self
        , displayName: "Camera".localized
        , description: "Robust Standard Built-In Camera for Capturing Live Photos."
        , keywords:["Camera", "Capture","Take a photo", "Video", "Record"]
        , iconBundleName: R.image.cameraSAppIcon.name
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    public required override init() {}
    
    func shouldSelect(item: AppAsset) -> Bool {
        return false
    }

    func didResign(current: App.Type?) {

    }

    fileprivate var importedLaunchOption: AppLaunchOptions? = nil

    func didLaunch(previous: App.Type?, withOption: AppLaunchOptions?) {
        importedLaunchOption = withOption

        papLog.app.launch(with: withOption)
    }
}

class CameraAppView: AppUICameraView {}

fileprivate class CameraAppDockContent: NSObject, PropertyWatchable, AppDockContent, AppDockDelegate {
    lazy var view: UIView = {
        return CameraAppView(frame: .zero, options:CameraApp.defaults as! CameraAppDefaults)
    }()

    private var cameraView: CameraView? {
        return (view as? CameraAppView)?.cameraView
    }

    var preferences: AppDockContentPreferable? {
        var pref = AppDockContentPreferences()
        pref.preferredHeight = 300
        return pref
    }

    func willSetContentView(_ view: UIView, dock: AppDock) {

    }

    func didSetContentView(_ view: UIView, dock: AppDock) {
        cameraView?.captureMetadataComment = AppCenter.default.currentInstanceAs(CameraApp.self)?.importedLaunchOption?.identifierToReturn

        cameraView?.startSession()

        (view as? CameraAppView)?.isCompactMode = dock.contentLayoutState != .maximized

        cameraView?.capturedHandler = { succeed, results in
            if let results = results{

                var data = [AppLaunchOptionsKey:Any]()
                if let photoUrl = results[CaptureProcessorResultKey.photoURL]{
                    data[AppLaunchOptionsKey.PhotoURL] = photoUrl
                }
                if let pairedVideoURL = results[CaptureProcessorResultKey.pairedVideoURL]{
                    data[AppLaunchOptionsKey.PairedVideoURL] = pairedVideoURL
                }

                self.didCaptured(with:data)
            }
        }
    }
    
    func didCaptured(with data:[AppLaunchOptionsKey:Any]){
        if let option = AppCenter.default.currentInstanceAs(CameraApp.self)?.importedLaunchOption
            , let id = option.identifierToReturn {

            AppCenter.default.openApp(identifier: id, options: AppLaunchOptions(options: data), animation:true)
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




