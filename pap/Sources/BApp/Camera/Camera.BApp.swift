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
    
    private lazy var captureSession = AVCaptureSession()
    private lazy var capturePhotoOutput = AVCapturePhotoOutput()
    private lazy var defaultCapturePhotoSettings: AVCapturePhotoSettings = {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        return settings
    }()
    
    var configurationDidUpdate: (() -> Void)?
    
    private var sessionQueue = DispatchQueue(label: "com.stells.internal."+#file, qos: .utility)
    private var photoURL: URL?
    
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
        
        configurationDidUpdate?()
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
        performShutterAnimation()
        
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
            
            self.configurationDidUpdate?()
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
    
    func performShutterAnimation(_ completion: (() -> Void)? = nil) {
        let duration = 0.1
        
        CATransaction.begin()
        
        if let completion = completion {
            CATransaction.setCompletionBlock(completion)
        }
        
        let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadeOutAnimation.fromValue = 1.0
        fadeOutAnimation.toValue = 0.0
        layer.add(fadeOutAnimation, forKey: "opacity")
        
        let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
        fadeInAnimation.fromValue = 0.0
        fadeInAnimation.toValue = 1.0
        fadeInAnimation.beginTime = CACurrentMediaTime() + duration * 2.0
        layer.add(fadeInAnimation, forKey: "opacity")
        
        CATransaction.commit()
    }
}

extension CameraView {
    var isLivePhotoSupported: Bool {
        return capturePhotoOutput.isLivePhotoCaptureSupported
    }
    
    var isLivePhotoEnabled: Bool {
        set {
            capturePhotoOutput.isLivePhotoCaptureEnabled = newValue
            self.configurationDidUpdate?()
        }
        
        get {
            return capturePhotoOutput.isLivePhotoCaptureEnabled
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
        cameraView.contentMode = .scaleAspectFill
        cameraView.setUp()
        
        cameraView.addGestureRecognizer(tapGesture)
        
        return cameraView
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapToCapture))
    private var optionViewHeightLayout: NSLayoutConstraint?
    private var cameraAspectRatioLayout: NSLayoutConstraint?
    
    fileprivate var primaryColor = UIColor(red: 0.97, green: 0.8, blue: 0.27, alpha: 1) // 248    204    70
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        intialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        intialize()
    }
    
    private func intialize() {
        tintColor = UIColor.white
        
        let optionView = UIView(frame: .zero)
        optionView.backgroundColor = .black
        addSubview(optionView)
        
        optionView.translatesAutoresizingMaskIntoConstraints = false
        optionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        optionView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        optionView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        optionViewHeightLayout = optionView.heightAnchor.constraint(equalToConstant: 0)
        optionViewHeightLayout?.isActive = true
        
        let livePhotoButton = UIButton(type: .system)
        livePhotoButton.setImage(livePhotoBadgeIcon, for: .normal)
        livePhotoButton.addTarget(self, action: #selector(self.toggleLivePhotoEnabled), for: .touchUpInside)
        optionView.addSubview(livePhotoButton)
        
        livePhotoButton.translatesAutoresizingMaskIntoConstraints = false
        livePhotoButton.centerXAnchor.constraint(equalTo: optionView.centerXAnchor).isActive = true
        livePhotoButton.topAnchor.constraint(equalTo: optionView.topAnchor).isActive = true
        livePhotoButton.bottomAnchor.constraint(equalTo: optionView.bottomAnchor).isActive = true
        livePhotoButton.widthAnchor.constraint(equalTo: optionView.heightAnchor, multiplier: 1).isActive = true
        
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
        
        cameraView.configurationDidUpdate = {
            DispatchQueue.main.async {
                livePhotoButton.setImage(self.livePhotoBadgeIcon, for: .normal)
                livePhotoButton.tintColor = self.cameraView.isLivePhotoEnabled ? self.primaryColor : nil
            }
        }
    }
    
    private var livePhotoBadgeIcon: UIImage {
        return { () -> UIImage in
            guard cameraView.isLivePhotoSupported else { return PHLivePhotoView.livePhotoBadgeImage(options: .liveOff) }
            return cameraView.isLivePhotoEnabled ? PHLivePhotoView.livePhotoBadgeImage(options: .overContent) : PHLivePhotoView.livePhotoBadgeImage(options: .liveOff)
        }().withRenderingMode(.alwaysTemplate)
    }
    
    @objc func tapToCapture(sender: Any) {
        cameraView.takePhoto()
    }
    
    @objc func switchCamera(sender: Any) {
        cameraView.switchCameraPosition()
    }
    
    @objc func toggleLivePhotoEnabled(sender: Any) {
        guard cameraView.isLivePhotoSupported else { return }
        cameraView.isLivePhotoEnabled = !cameraView.isLivePhotoEnabled
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
