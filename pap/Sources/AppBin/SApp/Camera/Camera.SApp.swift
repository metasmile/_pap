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
import Intents

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

extension CameraApp{
    struct CaptureOption: OptionSet {
        public let rawValue: Int

        init(rawValue: Int) {
            self.rawValue = rawValue
        }

        init(_ rawValue: Int) {
            self.rawValue = rawValue
        }

        static let takePhoto = CaptureOption(1 << 0)
        static let livePhoto = CaptureOption(1 << 1)
        static let stillPhoto = CaptureOption(1 << 2)
        static let selfiePhoto = CaptureOption(1 << 3)
        static let selfieWithLivePhoto = CaptureOption(1 << 4)
    }
}

extension CameraApp:UIApplicationDelegateLaunchableApp{

    static var intents: [INIntent] {
        if #available(iOS 12.0, *) {
            let openAppIntent = OpenCameraIntent()
            openAppIntent.mode = .photo
            openAppIntent.appId = CameraApp.info.identifier
            openAppIntent.appName = NSString.deferredLocalizedIntentsString(with: CameraApp.info.displayName) as String
            openAppIntent.suggestedInvocationPhrase = "Open Camera.".localized.localized

            let takeAStillPhotoIntent = TakeAPhotoIntent()
            takeAStillPhotoIntent.cameraMode = .photo
            takeAStillPhotoIntent.appId = CameraApp.info.identifier
            takeAStillPhotoIntent.appName = NSString.deferredLocalizedIntentsString(with: CameraApp.info.displayName) as String
            takeAStillPhotoIntent.captureOption = NSNumber(value: CameraApp.CaptureOption([.takePhoto, .stillPhoto]).rawValue)
            takeAStillPhotoIntent.suggestedInvocationPhrase = "Take A Photo.".localized

            let takeALivePhotoIntent = TakeAPhotoIntent()
            takeALivePhotoIntent.cameraMode = .livePhoto
            takeALivePhotoIntent.appId = CameraApp.info.identifier
            takeALivePhotoIntent.appName = NSString.deferredLocalizedIntentsString(with: CameraApp.info.displayName) as String
            takeALivePhotoIntent.captureOption = NSNumber(value: CameraApp.CaptureOption([.takePhoto, .livePhoto]).rawValue)
            takeALivePhotoIntent.suggestedInvocationPhrase = "Take A Live Photo.".localized

            let takeASelfieIntent = TakeAPhotoIntent()
            takeASelfieIntent.cameraMode = .selfiePhoto
            takeASelfieIntent.appId = CameraApp.info.identifier
            takeASelfieIntent.appName = NSString.deferredLocalizedIntentsString(with: CameraApp.info.displayName) as String
            takeASelfieIntent.captureOption = NSNumber(value: CameraApp.CaptureOption([.takePhoto, .selfiePhoto]).rawValue)
            takeASelfieIntent.suggestedInvocationPhrase = "Take A Selfie.".localized

            let takeASelfieWithLivePhotoIntent = TakeAPhotoIntent()
            takeASelfieWithLivePhotoIntent.cameraMode = .selfieWithLivePhoto
            takeASelfieWithLivePhotoIntent.appId = CameraApp.info.identifier
            takeASelfieWithLivePhotoIntent.appName = NSString.deferredLocalizedIntentsString(with: CameraApp.info.displayName) as String
            takeASelfieWithLivePhotoIntent.captureOption = NSNumber(value: CameraApp.CaptureOption([.takePhoto, .livePhoto, .selfiePhoto]).rawValue)
            takeASelfieWithLivePhotoIntent.suggestedInvocationPhrase = "Take A Selfie With Live Photo.".localized

            let takeAGIFWithLivePhoto = TakeAGIFWithLivePhotoIntent()
            takeAGIFWithLivePhoto.appId = CameraApp.info.identifier
            takeAGIFWithLivePhoto.suggestedInvocationPhrase = "Take A GIF With Live Photo.".localized

            return [openAppIntent, takeAStillPhotoIntent, takeALivePhotoIntent,takeASelfieIntent,takeASelfieWithLivePhotoIntent, takeAGIFWithLivePhoto]
        } else {
            return []
        }
    }

    func didLaunchHandling(with userActivity: NSUserActivity) {
        guard let intent = userActivity.interaction?.intent else{
            return
        }

        if #available(iOS 12.0, *) {
            (self.content as? CameraAppDockContent)?.performWithIntent(intent)
        }
    }

    func didLaunchHandling(with shortcutItem: UIApplicationShortcutItem) {

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
        let launchOption = AppCenter.default.currentInstanceAs(CameraApp.self)?.importedLaunchOption

        cameraView?.captureMetadataComment = launchOption?.identifierToReturn
        cameraView?.startSession()

        (view as? CameraAppView)?.isCompactMode = dock.contentLayoutState != .maximized

        cameraView?.watch(\.capturedResult) {
            if let capturedResult = self.cameraView?.capturedResult, let results = capturedResult.results{
                var data = [AppLaunchOptionsKey: Any]()
                if let photoUrl = results[CaptureProcessorResultKey.photoURL] {
                    data[AppLaunchOptionsKey.PhotoURL] = photoUrl
                }
                if let pairedVideoURL = results[CaptureProcessorResultKey.pairedVideoURL] {
                    data[AppLaunchOptionsKey.PairedVideoURL] = pairedVideoURL
                }

                self.didCaptured(with: data)
            }
        }

        // .CameraAppCaptureOption
        if let captureOption = launchOption?.options?[.CameraAppCaptureOption] as? CameraApp.CaptureOption{
            self.capture(with: captureOption)
        }
    }

    @available(iOS 12.0, *)
    fileprivate func performWithIntent(_ intent:INIntent){

        if let intent = intent as? TakeAPhotoIntent, let optionValue = intent.captureOption?.intValue {

            capture(with: CameraApp.CaptureOption(optionValue))

        }else if let intent = intent as? TakeAGIFWithLivePhotoIntent{

            var launchOption = AppCenter.default.currentInstanceAs(CameraApp.self)?.importedLaunchOption
            launchOption?.identifierToReturn = ConverterApp.info.identifier
            AppCenter.default.currentInstanceAs(CameraApp.self)?.importedLaunchOption = launchOption

            capture(with: [.livePhoto, .takePhoto])
        }
    }

    //TODO: queueing with multiple capture commands
    private func capture(with option:CameraApp.CaptureOption){
        guard let cameraView = cameraView else{
            assert(false, "cameraView is nil")
            return
        }

        if option.contains(.livePhoto) {
            cameraView.isLivePhotoEnabled = true
        }
        else if option.contains(.stillPhoto) {
            cameraView.isLivePhotoEnabled = false
        }

        if option.contains(.takePhoto) {

            if option.contains(.selfiePhoto) && cameraView.cameraPosition == .back {
                let capturedResultId = "capturedResult"
                cameraView.watch(\.capturedResult, id: capturedResultId) {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                        cameraView.switchCaptureDevicePosition()
                    }
                    cameraView.unwatch(forIds: [capturedResultId])
                }

                cameraView.switchCaptureDevicePosition { position in
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                        cameraView.takePhoto()
                    }
                }
            }else{
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    cameraView.takePhoto()
                }
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




