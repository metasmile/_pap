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

extension CameraApp: UIApplicationDelegateLaunchableApp{
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

extension CameraApp{
    fileprivate struct CameraAppIntentOption: OptionSet {
        public let rawValue: Int
        
        init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        init(_ rawValue: Int) {
            self.rawValue = rawValue
        }
        
        static let takePhoto = CameraAppIntentOption(1 << 0)
        static let livePhoto = CameraAppIntentOption(1 << 1)
        static let stillPhoto = CameraAppIntentOption(1 << 2)
        static let selfiePhoto = CameraAppIntentOption(1 << 3)
        static let selfieWithLivePhoto = CameraAppIntentOption(1 << 4)
    }
    
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
            takeAStillPhotoIntent.launchOption = NSNumber(value: CameraAppIntentOption([.takePhoto, .stillPhoto]).rawValue)
            takeAStillPhotoIntent.suggestedInvocationPhrase = "Take A Photo.".localized
            
            let takeALivePhotoIntent = TakeAPhotoIntent()
            takeALivePhotoIntent.cameraMode = .livePhoto
            takeALivePhotoIntent.appId = CameraApp.info.identifier
            takeALivePhotoIntent.appName = NSString.deferredLocalizedIntentsString(with: CameraApp.info.displayName) as String
            takeALivePhotoIntent.launchOption = NSNumber(value: CameraAppIntentOption([.takePhoto, .livePhoto]).rawValue)
            takeALivePhotoIntent.suggestedInvocationPhrase = "Take A Live Photo.".localized

            let i_t_s = TakeAPhotoIntent()
            i_t_s.cameraMode = .selfiePhoto
            i_t_s.appId = CameraApp.info.identifier
            i_t_s.appName = NSString.deferredLocalizedIntentsString(with: CameraApp.info.displayName) as String
            i_t_s.launchOption = NSNumber(value: CameraAppIntentOption([.takePhoto, .selfiePhoto]).rawValue)
            i_t_s.suggestedInvocationPhrase = "Take A Selfie.".localized

            let i_t_l_s = TakeAPhotoIntent()
            i_t_l_s.cameraMode = .selfieWithLivePhoto
            i_t_l_s.appId = CameraApp.info.identifier
            i_t_l_s.appName = NSString.deferredLocalizedIntentsString(with: CameraApp.info.displayName) as String
            i_t_l_s.launchOption = NSNumber(value: CameraAppIntentOption([.takePhoto, .livePhoto, .selfiePhoto]).rawValue)
            i_t_l_s.suggestedInvocationPhrase = "Take A Selfie With Live Photo.".localized
            
            return [openAppIntent, takeAStillPhotoIntent, takeALivePhotoIntent,i_t_s,i_t_l_s]
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
    }

    @available(iOS 12.0, *)
    fileprivate func performWithIntent(_ intent:INIntent){
        if let cameraView = self.cameraView
        , let intent = intent as? TakeAPhotoIntent
        , let optionValue = intent.launchOption?.intValue {
            
            let option = CameraApp.CameraAppIntentOption(optionValue)
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
                            self.cameraView?.switchCaptureDevicePosition()
                        }
                        cameraView.unwatch(forIds: [capturedResultId])
                    }

                    self.cameraView?.switchCaptureDevicePosition { position in
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




