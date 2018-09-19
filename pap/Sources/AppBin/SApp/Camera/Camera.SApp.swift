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

import Intents

extension CameraApp: IntentableApp {
    struct IntentLaunchOption: OptionSet {
        public let rawValue: Int
        
        init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        init(_ rawValue: Int) {
            self.rawValue = rawValue
        }
        
        static let takePhoto = IntentLaunchOption(1 << 0)
        static let livePhoto = IntentLaunchOption(1 << 1)
        static let stillPhoto = IntentLaunchOption(1 << 2)
    }
    
    static var intents: [INIntent] {
        if #available(iOS 12.0, *) {
            let openAppIntent = OpenCameraIntent()
            openAppIntent.mode = .photo
            openAppIntent.appId = CameraApp.info.identifier
            openAppIntent.appName = NSString.deferredLocalizedIntentsString(with: CameraApp.info.displayName) as String
            openAppIntent.suggestedInvocationPhrase = "Open Camera".localized
            
            let takeAPhotoIntent = TakeAPhotoIntent()
            takeAPhotoIntent.appId = CameraApp.info.identifier
            takeAPhotoIntent.appName = NSString.deferredLocalizedIntentsString(with: CameraApp.info.displayName) as String
            takeAPhotoIntent.launchOption = NSNumber(value: IntentLaunchOption.takePhoto.rawValue)
            takeAPhotoIntent.suggestedInvocationPhrase = "Fire The Shutter".localized //TODO: run this intent while camera app is opened
            
            let takeAStillPhotoIntent = TakeAPhotoIntent()
            takeAStillPhotoIntent.cameraMode = .photo
            takeAStillPhotoIntent.appId = CameraApp.info.identifier
            takeAStillPhotoIntent.appName = NSString.deferredLocalizedIntentsString(with: CameraApp.info.displayName) as String
            takeAStillPhotoIntent.launchOption = NSNumber(value: IntentLaunchOption([.takePhoto, .stillPhoto]).rawValue)
            takeAStillPhotoIntent.suggestedInvocationPhrase = "Take A Photo".localized
            
            let takeALivePhotoIntent = TakeAPhotoIntent()
            takeALivePhotoIntent.cameraMode = .livePhoto
            takeALivePhotoIntent.appId = CameraApp.info.identifier
            takeALivePhotoIntent.appName = NSString.deferredLocalizedIntentsString(with: CameraApp.info.displayName) as String
            takeALivePhotoIntent.launchOption = NSNumber(value: IntentLaunchOption([.takePhoto, .livePhoto]).rawValue)
            takeALivePhotoIntent.suggestedInvocationPhrase = "Take A Live Photo".localized
            
            return [openAppIntent, takeAPhotoIntent, takeAStillPhotoIntent, takeALivePhotoIntent]
        } else {
            return []
        }
    }
}

//@available(iOS 12.0, *)
//class IntentHandler: INExtension {
//    override func handler(for intent: INIntent) -> Any? {
//        guard intent is TakeAPhotoIntent else { return nil }
//        return TakeAPhotoIntentHandler()
//    }
//}
//
//@available(iOS 12.0, *)
//public class TakeAPhotoIntentHandler: NSObject, TakeAPhotoIntentHandling {
//    public func handle(intent: TakeAPhotoIntent, completion: @escaping (TakeAPhotoIntentResponse) -> Void) {
//        let response = TakeAPhotoIntentResponse(code: .success, userActivity: nil)
//        response.mode = intent.mode
//        response.userActivity = NSUserActivity(activityType: NSStringFromClass(TakeAPhotoIntent.self))
//        completion(response)
//    }
//}

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
        
        if let optionValue = AppCenter.default.currentInstanceAs(CameraApp.self)?.importedLaunchOption?.options?[AppLaunchOptionsKey.Intent] as? NSNumber {
            let option = CameraApp.IntentLaunchOption(optionValue.intValue)
            if option.contains(.livePhoto) {
                self.cameraView?.isLivePhotoEnabled = true
            }
            else if option.contains(.stillPhoto) {
                self.cameraView?.isLivePhotoEnabled = false
            }
            
            if option.contains(.takePhoto) {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                    self.cameraView?.takePhoto()
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




