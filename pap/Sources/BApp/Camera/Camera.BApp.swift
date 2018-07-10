//
//  Camera.BApp.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 7. 10..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import AVFoundation

class CameraApp: NSObject, KeyPathWatchable, BApp, AppDockApp, PhotoPickerCollectionViewDisplayableApp {
    public static let taskType: AppTaskable.Type = _CameraAppTask.self
    
    public static let paramType: AppTaskParamable.Type = PHAssetItem<ImageEditStateValue>.self
    
    public private(set) lazy var dockContent: AppDockContent? = CameraAppDockContent()
    
    public static let info = AppInfo(
        identifier: "com.stells.pap.camera"
        , version: "0.1"
        , phase: .develop
        , appType: CameraApp.self
        , displayName: "Camera".localized, description:nil, keywords:nil
        , iconBundleName: nil
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    public required override init() {}
    
    func shouldSelect(item: AppAsset) -> Bool {
        return false
    }
}

private class _CameraAppTask: AppTaskPrototype, AppTaskable {
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){}
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        if let asset = (param as? PHAssetItem<ImageEditStateValue>)?.asset{
            return PHAssetResultItem(asset: asset, contentEditingOutput: nil)
        }
        return nil
    }
}

fileprivate class CameraPreviewLayer: AVCaptureVideoPreviewLayer {
    override func action(forKey event: String) -> CAAction? {
        switch event {
        case "bounds", "position":
            return nil
        default:
            return super.action(forKey: event)
        }
    }
}

fileprivate class CameraView: UIView {
    override class var layerClass: AnyClass {
        return CameraPreviewLayer.self
    }
    
    var captureVideoPreviewLayer: CameraPreviewLayer? {
        return layer as? CameraPreviewLayer
    }
    
    var captureSession: AVCaptureSession?
    lazy var capturePhotoOutput = AVCapturePhotoOutput()
    lazy var capturePhotoSettings: AVCapturePhotoSettings = {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        return settings
    }()
    
    fileprivate var sessionQueue = DispatchQueue(label: "com.stells.internal."+#file, qos: .utility)
    fileprivate var captureQueue = DispatchQueue(label: "com.stells.internal."+#file, qos: .utility)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setUp() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                self.sessionQueue.resume()
            }
        default: break
        }
        
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    private func configureSession() {
        guard
            let captureDevice = AVCaptureDevice.default(for: AVMediaType.video),
            let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice)
            else { return }
        
        captureSession = AVCaptureSession()
        captureSession?.addInput(captureDeviceInput)
        
        capturePhotoOutput.isHighResolutionCaptureEnabled = true
        captureSession?.addOutput(capturePhotoOutput)
        
        captureVideoPreviewLayer?.session = captureSession
    }
    
    func startSession() {
        sessionQueue.async {
            self.captureSession?.startRunning()
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            self.captureSession?.stopRunning()
        }
    }
    
    func takePhoto() {
        sessionQueue.async {
            self.capturePhotoOutput.capturePhoto(with: self.capturePhotoSettings, delegate: self)
        }
    }
    
    override var contentMode: UIViewContentMode {
        didSet {
            switch contentMode {
            case .scaleAspectFit:
                captureVideoPreviewLayer?.videoGravity = .resizeAspect
            case .scaleAspectFill:
                captureVideoPreviewLayer?.videoGravity = .resizeAspectFill
            default: break
            }
        }
    }
}

extension CameraView: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        captureQueue.async {
            print(photo.fileDataRepresentation())
        }
    }
}

fileprivate class CameraAppDockContent: NSObject, KeyPathWatchable, AppDockContent {
    lazy var view: UIView = {
        let cameraView = CameraView(frame: .zero)
        cameraView.contentMode = .scaleAspectFit
        cameraView.setUp()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapToCapture))
        cameraView.addGestureRecognizer(tapGesture)
        
        return cameraView
    }()
    
    var preferences: AppDockContentPreferable? {
        return AppDockContentPreferences()
    }
    
    @objc func tapToCapture(gesture: UITapGestureRecognizer) {
        (view as? CameraView)?.takePhoto()
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        
    }
    
    func didSetContentView(_ view: UIView, dock: AppDock) {
        (view as? CameraView)?.startSession()
    }
    
    func willRemoveContentView() {
        (view as? CameraView)?.stopSession()
    }
}
