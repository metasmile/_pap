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
    
    lazy var captureSession = AVCaptureSession()
    lazy var capturePhotoOutput = AVCapturePhotoOutput()
    lazy var defaultCapturePhotoSettings: AVCapturePhotoSettings = {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        return settings
    }()
    
    fileprivate var sessionQueue = DispatchQueue(label: "com.stells.internal."+#file, qos: .utility)
    
    fileprivate var photoURL: URL?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        
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
            let videoDevice = AVCaptureDevice.default(for: .video),
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            captureSession.canAddInput(videoDeviceInput)
            else { return }
        
        captureSession.beginConfiguration()
        
        captureSession.addInput(videoDeviceInput)
        
        if let audioDevice = AVCaptureDevice.default(for: .audio),
            let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice),
            captureSession.canAddInput(audioDeviceInput) {
            captureSession.addInput(audioDeviceInput)
        }
        
        capturePhotoOutput.isHighResolutionCaptureEnabled = true
        capturePhotoOutput.isLivePhotoCaptureEnabled = capturePhotoOutput.isLivePhotoCaptureSupported
        
        captureSession.sessionPreset = .photo
        captureSession.addOutput(capturePhotoOutput)
        
        captureSession.commitConfiguration()
        
        captureVideoPreviewLayer?.session = captureSession
        
        //TODO: 이거 제 카메라 찰칵찰칵 시끄러서 라이브 켜놓은거임ㅋㅋ
        capturePhotoOutput.isLivePhotoCaptureEnabled = capturePhotoOutput.isLivePhotoCaptureSupported
    }
    
    func startSession() {
        sessionQueue.async {
            self.captureSession.startRunning()
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            self.captureSession.stopRunning()
        }
    }
    
    var capturesInProgress = Set<CameraViewCaptureProcessor>()
    
    func takePhoto() {
        let captureProcessor: CameraViewCaptureProcessor
        
        let photoSettings: AVCapturePhotoSettings
        if self.capturePhotoOutput.availablePhotoCodecTypes.contains(.hevc), capturePhotoOutput.isLivePhotoCaptureEnabled {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            photoSettings.livePhotoMovieFileURL = FileURL.temp(UUID().uuidString, UTI.quickTimeMovie, group: FileURL.fileAndQueuePrivateGroup())
            captureProcessor = CameraViewLivePhotoCaptureProcessor()
        } else {
            photoSettings = AVCapturePhotoSettings(from: self.defaultCapturePhotoSettings)
            captureProcessor = CameraViewStillPhotoCaptureProcessor()
        }
        photoSettings.flashMode = .auto
        photoSettings.isAutoStillImageStabilizationEnabled = capturePhotoOutput.isStillImageStabilizationSupported
        
        capturesInProgress.insert(captureProcessor)
        
        // Schedule for the capture delegate to be removed from the set after capture.
        captureProcessor.completionHandler = { [weak self] in
            self?.capturesInProgress.remove(captureProcessor)
        }
        
        sessionQueue.async {
            self.capturePhotoOutput.capturePhoto(with: photoSettings, delegate: captureProcessor)
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

//https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/capturing_still_and_live_photos/capturing_and_saving_live_photos

fileprivate class CameraViewCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    var completionHandler: () -> () = {}
    lazy var captureQueue = DispatchQueue(label: "com.stells.internal."+#file, qos: .utility)
}

fileprivate class CameraViewStillPhotoCaptureProcessor: CameraViewCaptureProcessor {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let url = FileURL.temp(UUID().uuidString, UTI.jpeg, group: FileURL.fileAndQueuePrivateGroup())
        guard let _ = try? photo.fileDataRepresentation()?.write(to: url) else { return }
        
        captureQueue.async {
            let signal = AsyncSignal()
            
            signal.begin()
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
            }, completionHandler: { (success, info) in
                signal.end()
                self.completionHandler()
            })
            signal.waitUntilEnd()
        }
    }
}

fileprivate class CameraViewLivePhotoCaptureProcessor: CameraViewCaptureProcessor {
    private var photoURL: URL?
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        captureQueue.async {
            guard let photoURL = self.photoURL else { return }
            
            let signal = AsyncSignal()
            
            signal.begin()
            PHPhotoLibrary.shared().performChanges({
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true
                
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, fileURL: photoURL, options: options)
                creationRequest.addResource(with: .pairedVideo, fileURL: outputFileURL, options: options)
            }, completionHandler: { (success, info) in
                signal.end()
            })
            signal.waitUntilEnd()
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        captureQueue.async {
            let url = FileURL.temp(UUID().uuidString, UTI.jpeg, group: FileURL.fileAndQueuePrivateGroup())
            guard let _ = try? photo.fileDataRepresentation()?.write(to: url) else { return }
            self.photoURL = url
        }
    }
}

fileprivate class CameraAppView: UIView {
    lazy var cameraView: CameraView = {
        let cameraView = CameraView(frame: .zero)
        cameraView.contentMode = .scaleAspectFit
        cameraView.setUp()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapToCapture))
        cameraView.addGestureRecognizer(tapGesture)
        
        return cameraView
    }()
    
    private var cameraAspectRatioLayout: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        intialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        intialize()
    }
    
    private func intialize() {
        addSubview(cameraView)
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        cameraView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        cameraView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        let widthLayout = cameraView.widthAnchor.constraint(equalTo: widthAnchor)
        widthLayout.priority = .defaultLow
        widthLayout.isActive = true
        
        let heightLayout = cameraView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor)
        heightLayout.priority = .defaultLow
        heightLayout.isActive = true
        
        cameraAspectRatioLayout = cameraView.heightAnchor.constraint(equalTo: cameraView.widthAnchor, multiplier: 4 / 3)
        cameraAspectRatioLayout?.isActive = true
    }
    
    @objc func tapToCapture(gesture: UITapGestureRecognizer) {
        cameraView.takePhoto()
    }
}

fileprivate class CameraAppDockContent: NSObject, KeyPathWatchable, AppDockContent {
    lazy var view: UIView = {
        return CameraAppView(frame: .zero)
    }()
    
    private var cameraView: CameraView? {
        return (view as? CameraAppView)?.cameraView
    }
    
    var preferences: AppDockContentPreferable? {
        return AppDockContentPreferences()
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        
    }
    
    func didSetContentView(_ view: UIView, dock: AppDock) {
        cameraView?.startSession()
    }
    
    func willRemoveContentView() {
        cameraView?.stopSession()
    }
}
