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
        , iconBundleName: R.image.cameraBAppIcon.name
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
    
    fileprivate func captureDevice(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if #available(iOS 11.1, *) {
            return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInTelephotoCamera, .builtInTrueDepthCamera, .builtInWideAngleCamera], mediaType: .video, position: .unspecified).devices.first { $0.position == position }
        } else {
            return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInTelephotoCamera, .builtInWideAngleCamera], mediaType: .video, position: .unspecified).devices.first { $0.position == position }
        }
    }
    
    fileprivate func currentCaptureDeviceInput(for mediaType: AVMediaType) -> AVCaptureDeviceInput? {
        let captureDeviceInputs = self.captureSession.inputs as? [AVCaptureDeviceInput]
        return captureDeviceInputs?.first { $0.device.hasMediaType(mediaType) }
    }
    
    func switchCameraPosition() {
        sessionQueue.async {
            guard let currentDevice = self.currentCaptureDeviceInput(for: .video) else { return }
            let position: AVCaptureDevice.Position = currentDevice.device.position == .back ? .front : .back
            
            self.captureSession.beginConfiguration()
            self.captureSession.removeInput(currentDevice)
            
            if let newDevice = self.captureDevice(with: position), let deviceInput = try? AVCaptureDeviceInput(device: newDevice), self.captureSession.canAddInput(deviceInput) {
                self.captureSession.addInput(deviceInput)
            }
            else {
                self.captureSession.addInput(currentDevice)
            }
            self.captureSession.commitConfiguration()
            
            self.capturePhotoOutput.isLivePhotoCaptureEnabled = self.capturePhotoOutput.isLivePhotoCaptureSupported
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
        
        cameraView.addGestureRecognizer(tapGesture)
        
        return cameraView
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapToCapture))
    private var optionViewHeightLayout: NSLayoutConstraint?
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
        let optionView = UIView(frame: .zero)
        optionView.backgroundColor = .black
        addSubview(optionView)
        
        optionView.translatesAutoresizingMaskIntoConstraints = false
        optionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        optionView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        optionView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        optionViewHeightLayout = optionView.heightAnchor.constraint(equalToConstant: 0)
        optionViewHeightLayout?.isActive = true
        
        addSubview(cameraView)
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        cameraView.topAnchor.constraint(equalTo: optionView.bottomAnchor).isActive = true
        cameraView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        let widthLayout = cameraView.widthAnchor.constraint(equalTo: widthAnchor)
        widthLayout.priority = .defaultLow
        widthLayout.isActive = true
        
        let heightLayout = cameraView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor)
        heightLayout.priority = .defaultLow
        heightLayout.isActive = true
        
        cameraAspectRatioLayout = cameraView.heightAnchor.constraint(equalTo: cameraView.widthAnchor, multiplier: 4 / 3)
        cameraAspectRatioLayout?.isActive = true
        
        let controlView = UIView(frame: .zero)
        controlView.backgroundColor = .black
        addSubview(controlView)
        
        controlView.translatesAutoresizingMaskIntoConstraints = false
        controlView.topAnchor.constraint(equalTo: cameraView.bottomAnchor).isActive = true
        controlView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        controlView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        controlView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        let captureButton = UIButton(type: .system)
        captureButton.setTitle("Capture", for: .normal)
        captureButton.addTarget(self, action: #selector(self.tapToCapture), for: .touchUpInside)
        addSubview(captureButton)
        
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
        captureButton.centerXAnchor.constraint(equalTo: controlView.centerXAnchor).isActive = true
        captureButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        
        let captureButtonCenterYLayout = captureButton.centerYAnchor.constraint(equalTo: controlView.centerYAnchor)
        captureButtonCenterYLayout.priority = .defaultLow
        captureButtonCenterYLayout.isActive = true
        
        let switchButton = UIButton(type: .system)
        switchButton.setTitle("Switch", for: .normal)
        switchButton.addTarget(self, action: #selector(self.switchCamera), for: .touchUpInside)
        addSubview(switchButton)
        
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        switchButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
        switchButton.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor).isActive = true
        
        let switchButtonCenterYLayout = switchButton.centerYAnchor.constraint(equalTo: optionView.centerYAnchor)
        switchButtonCenterYLayout.priority = .defaultLow
        switchButtonCenterYLayout.isActive = true
    }
    
    @objc func tapToCapture(sender: Any) {
        cameraView.takePhoto()
    }
    
    @objc func switchCamera(sender: Any) {
        cameraView.switchCameraPosition()
    }
    
    var isCompactMode: Bool = true {
        didSet {
            optionViewHeightLayout?.isActive = false
            if isCompactMode {
                optionViewHeightLayout?.constant = 0
            }
            else {
                optionViewHeightLayout?.constant = 44
            }
            optionViewHeightLayout?.isActive = true
            
            tapGesture.isEnabled = isCompactMode
        }
    }
}

fileprivate class CameraAppDockContent: NSObject, KeyPathWatchable, AppDockContent, AppDockDelegate {
    lazy var view: UIView = {
        return CameraAppView(frame: .zero)
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
