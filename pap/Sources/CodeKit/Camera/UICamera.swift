//
// Created by BLACKGENE on 15.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Photos
import PhotosUI
import PropertyKit

class UICameraCapturedResult:NSObject{
    let succeed:Bool
    let results:UICameraCaptureProcessorResult?

    init(succeed:Bool, result:UICameraCaptureProcessorResult?){
        self.succeed = succeed
        self.results = result
    }
}

class UICamera: UIView, PropertyWatchable {
    private var captureSession: AVCaptureSession? {
        set {
            if let session = newValue {
                cameraPreviewView.setSession(session)
            }
        }
        
        get {
            return cameraPreviewView.session
        }
    }
    
    var preferredRawPhotoEnabled: Bool = false
    var preferredDepthPhotoEnabled: Bool = false
    var preferredLivePhotoEnabled: Bool = false
    var preferredCameraPosition: AVCaptureDevice.Position = .back
    var preferredFlashMode: FlashMode = .off
    var preferredUsingLocation: Bool = false
    var preferredTorchLevel: Float = 1
    
    private lazy var capturePhotoOutput = AVCapturePhotoOutput()
    private lazy var captureMovieOutput = AVCaptureMovieFileOutput()
    
    private(set) lazy var deviceMotion = UIDeviceMotion()
    private(set) lazy var locationManager = LocationManager.shared

    var configurationDidUpdate: (() -> Void)?
    @objc dynamic
    var capturedResult:UICameraCapturedResult?
    var captureMetadataComment:String?

    private lazy var sessionQueue = DispatchQueue(label: "com.stells.internal."+fileName()+UUID().uuidString, qos: .utility)
    private lazy var captureVideoDataQueue = DispatchQueue(label: fileName()+".captureVideoDataQueue."+UUID().uuidString, qos: .utility)
    private lazy var metadataObjectQueue = DispatchQueue(label: fileName()+".metadataObjectsQueue."+UUID().uuidString, qos: .utility)
    private lazy var depthDataOutputQueue = DispatchQueue(label: fileName()+".depthDataOutputQueue."+UUID().uuidString, qos: .utility)
    
    fileprivate var captureVideoDataDidOutput: ((_ sampleBuffer: CMSampleBuffer) -> Void)?
    fileprivate var depthDataDidOutput: ((_ depthData: AVDepthData, _ timestamp: CMTime) -> Void)?
    fileprivate var captureVideoMetadataDidOutput: ((_ metadataObjects: [AVMetadataObject]) -> Void)?

    private lazy var cameraPreviewView = UICameraPreviewView(frame: .zero)
    private var cameraPointOfInterestLayer: CAShapeLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    private func initialize() {
        addSubview(cameraPreviewView)
        cameraPreviewView.fitConstraints(to: self)

        #if targetEnvironment(simulator)
        cameraPreviewView.previewLayer.backgroundColor = UIColor.green.cgColor
        #endif

//        let imageView = UIImageView(image: R.image.scrsJpg())
//        cameraPreviewView.addSubview(imageView)
//        imageView.contentMode = .scaleAspectFit
//        imageView.fitConstraints(to: self)
    }
    
    var capturePreset: AVCaptureSession.Preset = .photo {
        didSet {
            sessionQueue.async {
                self.beginConfiguration()
                self.captureSession?.sessionPreset = self.capturePreset
                self.commitConfiguration()
            }
        }
    }
    
    private var captureVideoDimension: CMVideoDimensions? {
        guard let formatDescription = currentVideoDeviceInput?.device.activeFormat.formatDescription else { return nil }
        return CMVideoFormatDescriptionGetDimensions(formatDescription)
    }
    
    var captureVideoSize: CGSize {
        guard let videoDimensions = captureVideoDimension else { return .zero }
        return CGSize(width: Int(videoDimensions.height), height: Int(videoDimensions.width))
    }
    
    var flashMode: FlashMode = .off {
        didSet {
            sessionQueue.async {
                self.configureTorchMode(self.flashMode.torchMode)
                self.configurationDidUpdate?()
            }
        }
    }

    func startSession(completion:(() -> Void)?=nil) {
        deviceMotion.startUpdates(interval: 0.6)
        if preferredUsingLocation {
            locationManager.startUpdatingLocation()
        }
        sessionQueue.async {
            if self.captureSession == nil {
                self.configureSession()
            }
            self.captureSession?.startRunning()
            self.configureTorchMode(self.flashMode.torchMode)
            self.configurationDidUpdate?()

            completion?()
        }
    }

    func stopSession() {
        deviceMotion.stopUpdates()
        sessionQueue.async {
            self.captureSession?.stopRunning()
            self.captureSession = nil
        }
        locationManager.stopUpdatingLocation()
    }
    
    var capturesInProgress = Set<UICameraCaptureProcessor>()

    override var contentMode: UIView.ContentMode {
        didSet {
            cameraPreviewView.contentMode = contentMode
        }
    }
}

extension UICamera {
    func beginConfiguration() {
        captureSession?.beginConfiguration()
    }
    
    func commitConfiguration() {
        captureSession?.commitConfiguration()
        configurationDidUpdate?()
    }
    
    func setUp() {
        guard captureSession == nil else { return }
        
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
    
    private func configureCaptureDevice(_ captureDevice: AVCaptureDevice?) {
        guard let captureDevice = captureDevice, let captureSession = captureSession, let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            return
        }
        
        try? captureDevice.lockForConfiguration()
        
        if let currentCaptureDeviceInput = self.currentVideoDeviceInput {
            captureSession.removeInput(currentCaptureDeviceInput)
            
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }
            else if captureSession.canAddInput(currentCaptureDeviceInput) {
                captureSession.addInput(currentCaptureDeviceInput)
            }
        }
        else if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
        }
        
        configureDepthPhotoEnabled(isDepthPhotoEnabled)
        
        captureDevice.unlockForConfiguration()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: captureDevice)
    }
    
    //INFO: call this using audio recording video
    private func configureAudioDevice(_ captureDevice: AVCaptureDevice?) {
        guard currentAudioDeviceInput == nil else { return }
        
        try? captureDevice?.lockForConfiguration()
        
        if let audioDevice = AVCaptureDevice.default(for: .audio),
            let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice),
            captureSession?.canAddInput(audioDeviceInput) == true {
            captureSession?.addInput(audioDeviceInput)
        }
        
        captureDevice?.unlockForConfiguration()
    }
    
    private func configureSession(with device: AVCaptureDevice? = nil) {
        captureSession = AVCaptureSession()
        
        guard
            let videoDevice = device ?? preferredCaptureDevice(),
            let captureSession = captureSession
            else { return }
        
        beginConfiguration()
        
        configureCaptureDevice(videoDevice)
        
        captureSession.sessionPreset = capturePreset
        
        try? videoDevice.lockForConfiguration()
        
        if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
            videoDevice.focusMode = .continuousAutoFocus
        }
        
        if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
            videoDevice.exposureMode = .continuousAutoExposure
        }
        
        videoDevice.unlockForConfiguration()
        
        capturePhotoOutput.isHighResolutionCaptureEnabled = true
        
        if captureSession.canAddOutput(capturePhotoOutput) {
            captureSession.addOutput(capturePhotoOutput)

            let rawPhotoSupported = capturePhotoOutput.availableRawPhotoPixelFormatTypes.first != nil
            if rawPhotoSupported, false == type(of: self).privateDefaults.isRawPhotoSupported{
                var defaults = type(of: self).privateDefaults
                defaults.isRawPhotoSupported = rawPhotoSupported
            }
        }
        
        configureLivePhotoEnabled(preferredLivePhotoEnabled)
        configureDepthPhotoEnabled(preferredDepthPhotoEnabled)
        flashMode = preferredFlashMode
        
        commitConfiguration()
        
        cameraPreviewView.setSession(captureSession)
        updateVideoOrientation()
    }
}

extension UICamera {
    fileprivate func preferredCaptureDevice() -> AVCaptureDevice? {
        if preferredRawPhotoEnabled {
            return captureDeviceForRawPhoto()
        }
        else {
            return captureDevice(with: preferredCameraPosition)
        }
    }
    
    fileprivate func captureDeviceForRawPhoto() -> AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }
    
    fileprivate func captureDeviceForBack() -> AVCaptureDevice? {
        let deviceType: AVCaptureDevice.DeviceType
        if preferredDepthPhotoEnabled {
            deviceType = .builtInDualCamera
        } else {
            deviceType = .builtInWideAngleCamera
        }
        return AVCaptureDevice.default(deviceType, for: .video, position: .back)
    }
    
    fileprivate func captureDeviceForFront() -> AVCaptureDevice? {
        let deviceType: AVCaptureDevice.DeviceType
        if #available(iOS 11.1, *) {
            if preferredDepthPhotoEnabled {
                deviceType = .builtInTrueDepthCamera
            } else {
                deviceType = .builtInWideAngleCamera
            }
        } else {
            deviceType = .builtInWideAngleCamera
        }
        return AVCaptureDevice.default(deviceType, for: .video, position: .front)
    }
    
    fileprivate func captureDevice(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return position == .front ? captureDeviceForFront() : captureDeviceForBack()
    }
    
    fileprivate func currentCaptureDeviceInput(for mediaType: AVMediaType) -> AVCaptureDeviceInput? {
        let captureDeviceInputs = self.captureSession?.inputs as? [AVCaptureDeviceInput]
        return captureDeviceInputs?.first { $0.device.hasMediaType(mediaType) }
    }
    
    fileprivate var currentVideoDeviceInput:AVCaptureDeviceInput? {
        return currentCaptureDeviceInput(for:.video)
    }
    
    fileprivate var currentAudioDeviceInput:AVCaptureDeviceInput? {
        return currentCaptureDeviceInput(for:.audio)
    }
    
    fileprivate var currentCaptureDevice: AVCaptureDevice? {
        return currentCaptureDeviceInput(for: .video)?.device
    }
    
    func switchCaptureDevicePosition(animated: Bool = true, completion:((AVCaptureDevice.Position) -> ())?=nil) {
        guard let currentDevice = self.currentCaptureDevice else { return }
        let position: AVCaptureDevice.Position = currentDevice.position == .back ? .front : .back
        
        if animated {
            let switchingView = performSwitchCameraPositionAnimation(to: position)
            setCaptureDevicePosition(position) {
                DispatchQueue.main.async {
                    UIView.transition(with: self, duration: 0.5, options: .transitionCrossDissolve, animations: {
                        switchingView.removeFromSuperview()
                    }, completion: nil)
                    
                    completion?(position)
                }
            }
        }
        else {
            setCaptureDevicePosition(position)
        }
    }
    
    private func setCaptureDevicePosition(_ position: AVCaptureDevice.Position, completion: (() -> Void)? = nil) {
        sessionQueue.async {
            self.preferredCameraPosition = position
            
            let isLivePhotoEnabled = self.capturePhotoOutput.isLivePhotoCaptureEnabled
            let isDepthPhotoEnabled = self.preferredDepthPhotoEnabled
            
            self.beginConfiguration()
            
            self.configureCaptureDevice(self.captureDevice(with: position))
            self.configureLivePhotoEnabled(isLivePhotoEnabled)
            self.configureDepthPhotoEnabled(isDepthPhotoEnabled)
            
            if let connection = self.capturePhotoOutput.connection(with: .video), connection.isVideoMirroringSupported {
                connection.isVideoMirrored = position == .front
            }
            
            self.commitConfiguration()
            
            completion?()
        }
    }
}

extension UICamera {
    private var currentPhotoSettings: AVCapturePhotoSettings {
        let photoSettings: AVCapturePhotoSettings
        
        if self.capturePhotoOutput.isLivePhotoCaptureEnabled {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            photoSettings.livePhotoMovieFileURL = FileURL.temp(UUID().uuidString, UTI.quickTimeMovie, group: FileURL.fileAndQueuePrivateGroup())
            photoSettings.isAutoStillImageStabilizationEnabled = capturePhotoOutput.isStillImageStabilizationSupported
        }
        else if preferredRawPhotoEnabled, let availableRawFormat = self.capturePhotoOutput.availableRawPhotoPixelFormatTypes.first {
            photoSettings = AVCapturePhotoSettings(rawPixelFormatType: availableRawFormat, processedFormat: [AVVideoCodecKey: AVVideoCodecType.hevc])
            
            // RAW capture is incompatible with digital image stabilization.
            photoSettings.isAutoStillImageStabilizationEnabled = false
        }
        else {
            photoSettings = AVCapturePhotoSettings()
            photoSettings.isAutoStillImageStabilizationEnabled = capturePhotoOutput.isStillImageStabilizationSupported
        }
        
        photoSettings.isHighResolutionPhotoEnabled = capturePhotoOutput.isHighResolutionCaptureEnabled
        photoSettings.flashMode = flashMode.flashMode
        
        photoSettings.isDepthDataDeliveryEnabled = capturePhotoOutput.isDepthDataDeliveryEnabled
        if #available(iOS 12.0, *) {
            photoSettings.isPortraitEffectsMatteDeliveryEnabled = capturePhotoOutput.isPortraitEffectsMatteDeliveryEnabled
        }
        return photoSettings
    }
    
    func takePhoto(completion:UICameraCaptureProcessorCompletionHandler?=nil) {
        guard let _ = self.capturePhotoOutput.connection(with: .video) else { return }
        
        performShutterAnimation()
        
        let captureProcessor: UICameraCaptureProcessor
        let param = UICameraCaptureProcessorParam(
            videoDeviceInput: currentVideoDeviceInput
            , deviceOrientation: deviceMotion.orientation
            , metadataComment: captureMetadataComment
        )
        
        if self.isRawPhotoEnabled {
            captureProcessor = UICameraRawPhotoCaptureProcessor(param: param)
        }
        else if capturePhotoOutput.isLivePhotoCaptureEnabled {
            captureProcessor = UICameraLivePhotoCaptureProcessor(param: param)
        }
        else {
            captureProcessor = UICameraStillPhotoCaptureProcessor(param: param)
        }
        
        capturesInProgress.insert(captureProcessor)
        
        // Schedule for the capture delegate to be removed from the set after capture.
        captureProcessor.completionHandler = { [weak self] succeed, result in
            self?.capturesInProgress.remove(captureProcessor)
            self?.capturedResult = UICameraCapturedResult(succeed: succeed, result: result)
            completion?(succeed, succeed ? result : nil)
        }
        
        sessionQueue.async {
            self.capturePhotoOutput.capturePhoto(with: self.currentPhotoSettings, delegate: captureProcessor)
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

extension UICamera {
    func setCapturePhoto() {
        sessionQueue.async {
            guard let captureSession = self.captureSession else { return }
            
            self.beginConfiguration()
            
            captureSession.removeOutput(self.captureMovieOutput)
            captureSession.sessionPreset = .photo
            
            self.commitConfiguration()
        }
    }
    
    func setCaptureMovie() {
        sessionQueue.async {
            guard let captureSession = self.captureSession else { return }
            
            if captureSession.canAddOutput(self.captureMovieOutput) {
                self.beginConfiguration()
                
                captureSession.addOutput(self.captureMovieOutput)
                captureSession.sessionPreset = .high
                
                if let connection = self.captureMovieOutput.connection(with: .video) {
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode = .auto
                    }
                }
                
                self.commitConfiguration()
            }
        }
    }
}

extension UICamera: AVCaptureDepthDataOutputDelegate {
    func setDepthDataOutput(_ updateBlock: ((_ depthData: AVDepthData, _ timestamp: CMTime) -> Void)?) {
        self.depthDataDidOutput = updateBlock
        
        sessionQueue.async {
            guard let captureSession = self.captureSession else { return }
            
            let depthDataOutput = AVCaptureDepthDataOutput()
            depthDataOutput.alwaysDiscardsLateDepthData = true
            depthDataOutput.isFilteringEnabled = true
            depthDataOutput.setDelegate(self, callbackQueue: self.depthDataOutputQueue)
            
            if captureSession.canAddOutput(depthDataOutput) {
                self.beginConfiguration()
                captureSession.addOutput(depthDataOutput)
                self.commitConfiguration()
            }
        }
    }
    
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didDrop depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection, reason: AVCaptureOutput.DataDroppedReason) {
        
    }
    
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        self.depthDataDidOutput?(depthData, timestamp)
    }
}

extension UICamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    func setCaptureVideoDataOutput(_ updateBlock: ((_ sampleBuffer: CMSampleBuffer) -> Void)?) {
        self.captureVideoDataDidOutput = updateBlock
        
        sessionQueue.async {
            guard let captureSession = self.captureSession else { return }
            
            let captureVideoDataOutput = AVCaptureVideoDataOutput()
            captureVideoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
            captureVideoDataOutput.alwaysDiscardsLateVideoFrames = true
            captureVideoDataOutput.setSampleBufferDelegate(self, queue: self.captureVideoDataQueue)
            
            if captureSession.canAddOutput(captureVideoDataOutput) {
                self.beginConfiguration()
                captureSession.addOutput(captureVideoDataOutput)
                self.commitConfiguration()
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.captureVideoDataDidOutput?(sampleBuffer)
    }
}

extension UICamera: AVCaptureMetadataOutputObjectsDelegate {
    func setMetadataOutput(types metadataObjectTypes: [AVMetadataObject.ObjectType]? = nil, updateBlock: (([AVMetadataObject]) -> Void)?) {
        self.captureVideoMetadataDidOutput = updateBlock
        
        sessionQueue.async {
            guard let captureSession = self.captureSession else { return }
            
            self.beginConfiguration()
            
            let metadataOutput = AVCaptureMetadataOutput()
            metadataOutput.setMetadataObjectsDelegate(self, queue: self.metadataObjectQueue)
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
            }
            
            metadataOutput.metadataObjectTypes = metadataObjectTypes ?? metadataOutput.availableMetadataObjectTypes
            
            self.commitConfiguration()
        }
    }
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        self.captureVideoMetadataDidOutput?(metadataObjects.map {
            cameraPreviewView.previewLayer.transformedMetadataObject(for: $0) ?? $0
        })
    }
}

extension UICamera {
    var cameraPosition: AVCaptureDevice.Position {
        get {
            return currentCaptureDevice?.position ?? .unspecified
        }
        set {
            setCaptureDevicePosition(newValue)
        }
    }

    private func snapshotWithBlur() -> UIView {
        let view = UIView(frame: .zero)
        if let snapshot = snapshotView(afterScreenUpdates: true) {
            view.addSubview(snapshot)
        }

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.addSubview(blurView)
        blurView.fitConstraints(to: view)

        return view
    }

    private func performSwitchCameraPositionAnimation(to position: AVCaptureDevice.Position) -> UIView {
        let switchingView = snapshotWithBlur()
        addSubview(switchingView)
        switchingView.fitConstraints(to: self)

        UIView.transition(with: self, duration: 0.5, options: position == .back ? .transitionFlipFromLeft : .transitionFlipFromRight, animations: nil, completion: nil)

        return switchingView
    }
}

extension UICamera {
    var isLivePhotoSupported: Bool {
// https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Cameras/Cameras.html#//apple_ref/doc/uid/TP40013599-CH107-SW15
//
// iPhone
//        iPhone 8
//        iPhone 8 Plus
//        iPhone X
//        iPhone 7
//        iPhone 7 Plus
//        iPhone 6s
//        iPhone 6s Plus
//        iPhone SE
//        (X) iPhone 6
//        (X) iPhone 6 Plus
// iPad
//        iPad Pro
//        10.5-inch
//        12.9-inch (2nd generation)
//        iPad (5th generation)
//        (X) iPad Pro (12.9-inch)
//        iPad Pro (9.7-inch)
        return capturePhotoOutput.isLivePhotoCaptureSupported
    }
    
    var isLivePhotoEnabled: Bool {
        set {
            sessionQueue.async {
                self.beginConfiguration()
                
                if self.isRawPhotoEnabled {
                    self.configureCaptureDevice(self.captureDeviceForBack())
                }
                
                self.preferredLivePhotoEnabled = newValue
                self.configureLivePhotoEnabled(newValue)
                
                self.commitConfiguration()
            }
        }
        
        get {
            return capturePhotoOutput.isLivePhotoCaptureEnabled
        }
    }
    
    fileprivate func configureLivePhotoEnabled(_ enabled: Bool) {
        if self.capturePhotoOutput.isLivePhotoCaptureSupported, self.capturePhotoOutput.isLivePhotoCaptureEnabled != enabled {
            self.capturePhotoOutput.isLivePhotoCaptureEnabled = enabled
            
            self.configureAudioDevice(currentCaptureDevice)
        }
    }
}

extension UICamera {
    // https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Cameras/Cameras.html#//apple_ref/doc/uid/TP40013599-CH107-SW15
//
// iPhone
//        iPhone 8
//        iPhone 8 Plus
//        iPhone X
//        iPhone 7
//        iPhone 7 Plus
//        iPhone 6s
//        iPhone 6s Plus
//        iPhone SE
//        (X) iPhone 6
//        (X) iPhone 6 Plus
// iPad
//        iPad Pro
//        10.5-inch
//        12.9-inch (2nd generation)
//        (X) iPad (5th generation)
//        (X) iPad Pro (12.9-inch)
//        iPad Pro (9.7-inch)

    //INFO: worst case - next runtime guaranteed
    static var isRawPhotoSupported: Bool {
        return UICamera.privateDefaults.isRawPhotoSupported
    }
    
    var isRawPhotoEnabled: Bool {
        set {
            sessionQueue.async {
                self.preferredRawPhotoEnabled = newValue
                
                self.beginConfiguration()
                
                if newValue {
                    self.configureCaptureDevice(self.captureDeviceForRawPhoto())
                    self.configureLivePhotoEnabled(false)
                }
                else {
                    self.configureCaptureDevice(self.preferredCaptureDevice())
                    self.configureLivePhotoEnabled(self.preferredLivePhotoEnabled)
                    self.configureDepthPhotoEnabled(self.preferredDepthPhotoEnabled)
                }
                
                self.commitConfiguration()
            }
        }
        
        get {
            return preferredRawPhotoEnabled && self.currentPhotoSettings.rawPhotoPixelFormatType != 0
        }
    }
}

extension UICamera {
    static var isDepthPhotoSupported:Bool{
        if #available(iOS 12.0, *) {
            return !AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInTelephotoCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified).devices.isEmpty
        }
        else {
            return !AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInTelephotoCamera], mediaType: .video, position: .unspecified).devices.isEmpty
        }
    }

    var isDepthPhotoEnabled: Bool {
        set {
            sessionQueue.async {
                self.preferredDepthPhotoEnabled = newValue
                
                let isLivePhotoEnabled = self.capturePhotoOutput.isLivePhotoCaptureEnabled
                self.beginConfiguration()
                self.configureCaptureDevice(self.captureDevice(with: self.cameraPosition))
                self.configureLivePhotoEnabled(isLivePhotoEnabled)
                self.configureDepthPhotoEnabled(newValue)
                self.commitConfiguration()
            }
        }
        
        get {
            return preferredDepthPhotoEnabled && (self.cameraPosition == .front ? self.isPortraitEffectsMatteEnabled : self.isDepthDataEnabled)
        }
    }
    
    fileprivate func configureDepthPhotoEnabled(_ enabled: Bool) {
        if self.capturePhotoOutput.isDepthDataDeliverySupported {
            self.capturePhotoOutput.isDepthDataDeliveryEnabled = enabled
        }
        
        if #available(iOS 12.0, *), self.capturePhotoOutput.isPortraitEffectsMatteDeliverySupported {
            //POLICY: (because of memory issue)
            // When Capture Live Photo with Back Camera, Disabled Delivering Portrait Effects Matte
            if isLivePhotoEnabled, self.cameraPosition == .back {
                self.capturePhotoOutput.isPortraitEffectsMatteDeliveryEnabled = false
            }
            else {
                self.capturePhotoOutput.isPortraitEffectsMatteDeliveryEnabled = enabled
            }
        }
        
        if let availableFormats = currentCaptureDevice?.activeFormat.supportedDepthDataFormats {
            if let depthFormat = availableFormats.first(where: { format in
                let pixelFormatType = CMFormatDescriptionGetMediaSubType(format.formatDescription)
                return (pixelFormatType == kCVPixelFormatType_DepthFloat16 ||
                    pixelFormatType == kCVPixelFormatType_DepthFloat32)
            }) {
                try? currentCaptureDevice?.lockForConfiguration()
                currentCaptureDevice?.activeDepthDataFormat = depthFormat
                currentCaptureDevice?.unlockForConfiguration()
            }
        }
        
//        let availableFormats = self.videoCaptureDevice.activeFormat.supportedDepthDataFormats
//        let depthFormat = availableFormats.first(where: { format in
//            let pixelFormatType = CMFormatDescriptionGetMediaSubType(format.formatDescription)
//            return (pixelFormatType == kCVPixelFormatType_DepthFloat16 ||
//                pixelFormatType == kCVPixelFormatType_DepthFloat32)
//        })
//
//        // Set the capture device to use that depth format.
//        self.captureSession.beginConfiguration()
//        self.videoCaptureDevice.activeDepthDataFormat = depthFormat
//        self.captureSession.commitConfiguration()
    }
}

extension UICamera {
    fileprivate var isDepthDataSupported: Bool {
        return self.capturePhotoOutput.isDepthDataDeliverySupported
    }
    
    fileprivate var isDepthDataEnabled: Bool {
        return self.capturePhotoOutput.isDepthDataDeliveryEnabled
    }
}

extension UICamera {
    fileprivate var isPortraitEffectsMatteSupported: Bool {
        if #available(iOS 12.0, *) {
            return self.capturePhotoOutput.isPortraitEffectsMatteDeliverySupported
        }
        else {
            return false
        }
    }
    
    fileprivate var isPortraitEffectsMatteEnabled: Bool {
        if #available(iOS 12.0, *) {
            return self.capturePhotoOutput.isPortraitEffectsMatteDeliveryEnabled
        } else {
            return false
        }
    }
}

extension UICamera {
    var isUsingLocationSupported: Bool {
        return !locationManager.disabledLocation
    }
    
    var usingLocation: Bool {
        set {
            preferredUsingLocation = newValue
            
            if newValue {
                locationManager.startUpdatingLocation {
                    self.configurationDidUpdate?()
                }
            }
            else {
                locationManager.stopUpdatingLocation {
                    self.configurationDidUpdate?()
                }
            }
        }
        get {
            return locationManager.updatingLocation
        }
    }
}

extension UICamera {
    func zoom(_ scale: CGFloat) {
        let animated = (scale - videoZoomFactor).magnitude > 3
        if animated {
            setVideoZoomFactor(scale, withRate: 100)
        }
        else {
            videoZoomFactor = scale
        }
    }
    
    var isZoomEnabled: Bool {
        return videoMinZoomFactor != videoMaxZoomFactor
    }
    
    private var videoZoomRange: ClosedRange<CGFloat> {
        return (videoMinZoomFactor...videoMaxZoomFactor)
    }
    
    var videoMinZoomFactor: CGFloat {
        return self.currentCaptureDevice?.activeFormat.videoMinZoomFactorForDepthDataDelivery ?? 1
    }
    
    var videoMaxZoomFactor: CGFloat {
        return self.currentCaptureDevice?.activeFormat.videoMaxZoomFactorForDepthDataDelivery ?? 1
    }
    
    private(set) var videoZoomFactor: CGFloat {
        set {
            sessionQueue.async {
                guard let captureDevice = self.currentCaptureDevice else { return }
                try? captureDevice.lockForConfiguration()
                captureDevice.videoZoomFactor = newValue.clamped(to: self.videoZoomRange)
                captureDevice.unlockForConfiguration()
                
                DispatchQueue.main.async {
                    self.resetFocusAndExposure(showsGuide: false)
                }
            }
        }
        
        get {
            return currentCaptureDevice?.videoZoomFactor ?? 1
        }
    }
    
    private func setVideoZoomFactor(_ scale: CGFloat, withRate rate: Float) {
        sessionQueue.async {
            guard let captureDevice = self.currentCaptureDevice else { return }
            try? captureDevice.lockForConfiguration()
            if captureDevice.isRampingVideoZoom {
                captureDevice.cancelVideoZoomRamp()
            }
            captureDevice.ramp(toVideoZoomFactor: scale.clamped(to: self.videoZoomRange), withRate: rate)
            captureDevice.unlockForConfiguration()
            
            DispatchQueue.main.async {
                self.resetFocusAndExposure(showsGuide: false)
            }
        }
    }
}

extension UICamera {
    public enum FlashMode: Int {
        case off
        case on
        case auto
        case torch
        
        var flashMode: AVCaptureDevice.FlashMode {
            switch self {
            case .off: return .off
            case .on: return .on
            case .auto: return .auto
            default: return .off
            }
        }
        
        var torchMode: AVCaptureDevice.TorchMode {
            switch self {
            case .torch: return .on
            default: return .off
            }
        }
    }
    
    fileprivate func configureTorchMode(_ torchMode: AVCaptureDevice.TorchMode) {
        guard currentCaptureDevice?.hasTorch == true else { return }
        
        if torchMode == .on {
            configureTorchLevel(preferredTorchLevel)
        }
        else {
            try? currentCaptureDevice?.lockForConfiguration()
            currentCaptureDevice?.torchMode = torchMode
            currentCaptureDevice?.unlockForConfiguration()
        }
    }
    
    var torchLevel: Float {
        set {
            sessionQueue.async {
                self.configureTorchLevel(newValue)
                self.configurationDidUpdate?()
            }
        }
        
        get {
            return currentCaptureDevice?.torchLevel ?? preferredTorchLevel
        }
    }
    
    private func configureTorchLevel(_ level: Float) {
        guard currentCaptureDevice?.hasTorch == true else { return }
        
        try? currentCaptureDevice?.lockForConfiguration()
        
        if level > 0, let _ = try? currentCaptureDevice?.setTorchModeOn(level: level) {
            preferredTorchLevel = level
        }
        else {
            preferredTorchLevel = 1
        }
        
        currentCaptureDevice?.unlockForConfiguration()
    }
}

extension UICamera {
    @objc func subjectAreaDidChange() {
        resetFocusAndExposure()
    }
    
    func changeFocusMode(_ mode: AVCaptureDevice.FocusMode) {
        try? currentCaptureDevice?.lockForConfiguration()
        
        if currentCaptureDevice?.isFocusModeSupported(mode) == true {
            currentCaptureDevice?.focusMode = mode
        }
        
        currentCaptureDevice?.unlockForConfiguration()
    }
    
    func changeExposureMode(_ mode: AVCaptureDevice.ExposureMode) {
        try? currentCaptureDevice?.lockForConfiguration()
        
        if currentCaptureDevice?.isExposureModeSupported(mode) == true {
            currentCaptureDevice?.exposureMode = mode
        }
        
        currentCaptureDevice?.unlockForConfiguration()
    }
}

extension UICamera {
    private func pointOfInterest(at location: CGPoint) -> CGPoint {
        let layerPoint = layer.convert(location, to: cameraPreviewView.previewLayer)
        return cameraPreviewView.previewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)
    }
    
    func resetFocusAndExposure(showsGuide: Bool = true) {
        focusAndExposure(at: CGPoint(x: width / 2, y: height / 2), focusMode: .continuousAutoFocus, exposureMode: .continuousAutoExposure, monitorSubjectAreaChange: false, showsGuide: showsGuide)
    }
    
    func focusAndExposure(at location: CGPoint, focusMode: AVCaptureDevice.FocusMode = .autoFocus, exposureMode: AVCaptureDevice.ExposureMode = .autoExpose, monitorSubjectAreaChange: Bool = true, showsGuide: Bool = true) {
        let layerPoint = layer.convert(location, to: cameraPreviewView.previewLayer)
        let pointOfInterest = cameraPreviewView.previewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)
        
        sessionQueue.async {
            self.configurePointOfInterest(pointOfInterest, focusMode: focusMode, exposureMode: exposureMode, monitorSubjectAreaChange: monitorSubjectAreaChange)
        }
        
        cameraPointOfInterestLayer?.removeFromSuperlayer()
        
        if showsGuide {
            performPointOfInterestAnimation(at: layerPoint)
        }
    }
    
    private func configurePointOfInterest(_ pointOfInterest: CGPoint, focusMode: AVCaptureDevice.FocusMode = .continuousAutoFocus, exposureMode: AVCaptureDevice.ExposureMode = .continuousAutoExposure,  monitorSubjectAreaChange: Bool = true) {
        guard
            let captureDevice = currentCaptureDevice
        else { return }
        
        try? captureDevice.lockForConfiguration()
        
        if captureDevice.isFocusPointOfInterestSupported {
            captureDevice.focusPointOfInterest = pointOfInterest
        }
        
        if captureDevice.isExposurePointOfInterestSupported {
            captureDevice.exposurePointOfInterest = pointOfInterest
        }
        
        if captureDevice.isFocusModeSupported(focusMode) {
            captureDevice.focusMode = focusMode
        }
        
        if captureDevice.isExposureModeSupported(exposureMode) {
            captureDevice.exposureMode = exposureMode
        }
        
        captureDevice.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
        
        captureDevice.unlockForConfiguration()
    }
    
    private func performPointOfInterestAnimation(at pointOfInterest: CGPoint) {
        let size = CGSize(width: 75, height: 75)
        let rect = CGRect(origin: CGPoint(x: pointOfInterest.x - size.width / 2.0, y: pointOfInterest.y - size.height / 2.0), size: size)
        
        let endPath = UIBezierPath(rect: rect)
        endPath.move(to: CGPoint(x: rect.minX + size.width / 2.0, y: rect.minY))
        endPath.addLine(to: CGPoint(x: rect.minX + size.width / 2.0, y: rect.minY + 5.0))
        endPath.move(to: CGPoint(x: rect.maxX, y: rect.minY + size.height / 2.0))
        endPath.addLine(to: CGPoint(x: rect.maxX - 5.0, y: rect.minY + size.height / 2.0))
        endPath.move(to: CGPoint(x: rect.minX + size.width / 2.0, y: rect.maxY))
        endPath.addLine(to: CGPoint(x: rect.minX + size.width / 2.0, y: rect.maxY - 5.0))
        endPath.move(to: CGPoint(x: rect.minX, y: rect.minY + size.height / 2.0))
        endPath.addLine(to: CGPoint(x: rect.minX + 5.0, y: rect.minY + size.height / 2.0))
        
        let startPath = UIBezierPath(cgPath: endPath.cgPath)
        let scaleAroundCenterTransform = CGAffineTransform(translationX: -pointOfInterest.x, y: -pointOfInterest.y).concatenating(CGAffineTransform(scaleX: 2.0, y: 2.0).concatenating(CGAffineTransform(translationX: pointOfInterest.x, y: pointOfInterest.y)))
        startPath.apply(scaleAroundCenterTransform)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = endPath.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.lineWidth = 1.0
        
        layer.addSublayer(shapeLayer)
        
        cameraPointOfInterestLayer = shapeLayer
        
        CATransaction.begin()
        
        CATransaction.setAnimationDuration(0.2)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut))
        
        CATransaction.setCompletionBlock {
            if shapeLayer.superlayer != nil {
                shapeLayer.removeFromSuperlayer()
                self.cameraPointOfInterestLayer = nil
            }
        }
        
        let appearPathAnimation = CABasicAnimation(keyPath: "path")
        appearPathAnimation.fromValue = startPath.cgPath
        appearPathAnimation.toValue = endPath.cgPath
        shapeLayer.add(appearPathAnimation, forKey: "path")
        
        let appearOpacityAnimation = CABasicAnimation(keyPath: "opacity")
        appearOpacityAnimation.fromValue = 0.0
        appearOpacityAnimation.toValue = 1.0
        shapeLayer.add(appearOpacityAnimation, forKey: "opacity")
        
        let disappearOpacityAnimation = CABasicAnimation(keyPath: "opacity")
        disappearOpacityAnimation.fromValue = 1.0
        disappearOpacityAnimation.toValue = 0.0
        disappearOpacityAnimation.beginTime = CACurrentMediaTime() + 0.8
        disappearOpacityAnimation.fillMode = CAMediaTimingFillMode.forwards
        disappearOpacityAnimation.isRemovedOnCompletion = false
        shapeLayer.add(disappearOpacityAnimation, forKey: "opacity")
        
        CATransaction.commit()
    }
}

extension UICamera {
    func updateVideoOrientation() {
        guard let connection = capturePhotoOutput.connection(with: .video), connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = currentVideoOrientation
    }
    
    var currentVideoOrientation: AVCaptureVideoOrientation {
        switch deviceMotion.orientation {
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        case .portraitUpsideDown: return .portraitUpsideDown
        default: return .portrait
        }
    }
}

/*
CameraPreviewLayer
*/
fileprivate class CameraPreviewLayer: AVCaptureVideoPreviewLayer, CALayerDelegate {
    override func action(forKey event: String) -> CAAction? {
        switch event {
        case "transform", "bounds", "position": return NSNull()
        default: return super.action(forKey: event)
        }
    }

    func action(for layer: CALayer, forKey event: String) -> CAAction? {
        return action(forKey: event)
    }

    override init(session: AVCaptureSession) {
        super.init(session: session)
        initialize()
    }

    override init() {
        super.init()
        initialize()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    override init(sessionWithNoConnection session: AVCaptureSession) {
        super.init(sessionWithNoConnection: session)
        initialize()
    }

    private func initialize() {
        sublayers?.forEach { $0.delegate = self }
    }
}

fileprivate class UICameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        return CameraPreviewLayer.self
    }

    fileprivate var previewLayer: CameraPreviewLayer {
        return layer as! CameraPreviewLayer
    }

    override var contentMode: UIView.ContentMode {
        didSet {
            switch contentMode {
            case .scaleAspectFit:
                previewLayer.contentsGravity = CALayerContentsGravity.resizeAspect
                previewLayer.videoGravity = .resizeAspect
            case .scaleAspectFill:
                previewLayer.contentsGravity = CALayerContentsGravity.resizeAspectFill
                previewLayer.videoGravity = .resizeAspectFill
            default: break
            }
        }
    }

    func setSession(_ session:AVCaptureSession){
        previewLayer.session = session
    }

    var session: AVCaptureSession? {
        return previewLayer.session
    }
}

final class CaptureButton: UIControl {
    private lazy var outerCircleLayer = CAShapeLayer()
    private lazy var innerCircleLayer = CAShapeLayer()
    
    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    private func initialize() {
        backgroundColor = .clear

        outerCircleLayer.strokeColor = UIColor.white.cgColor
        outerCircleLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(outerCircleLayer)

        innerCircleLayer.strokeColor = UIColor.clear.cgColor
        innerCircleLayer.fillColor = UIColor.white.cgColor
        layer.addSublayer(innerCircleLayer)

        addTarget(self, action: #selector(self.pressed), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(self.released), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
    }

    @objc func pressed(sender: Any) {
        let scale: CGFloat = 0.9
        var transform = CATransform3DIdentity
        transform = CATransform3DTranslate(transform, bounds.width / 2, bounds.height / 2, 0)
        transform = CATransform3DScale(transform, scale, scale, 1)
        transform = CATransform3DTranslate(transform, -bounds.width / 2, -bounds.height / 2, 0)

        innerCircleLayer.transform = transform
    }

    @objc func released(sender: Any) {
        innerCircleLayer.transform = CATransform3DIdentity
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let scale = remap(bounds.height, 0, 64, 0, 1)
        let inset = remap(scale, 0, 1, bounds.height * 0.1, 0)
        let outerCircleLineWidth: CGFloat = remap(scale, 0, 1, 0, 6)
        let outerCircleInset = outerCircleLineWidth / 2 + inset
        let innerCircleInset = outerCircleLineWidth + remap(scale, 0, 1, 0, 2) + inset

        let outerCircle = UIBezierPath(ovalIn: bounds.inset(by:UIEdgeInsets(top: outerCircleInset, left: outerCircleInset, bottom: outerCircleInset, right: outerCircleInset)))
        let innerCircle = UIBezierPath(ovalIn: bounds.inset(by:UIEdgeInsets(top: innerCircleInset, left: innerCircleInset, bottom: innerCircleInset, right: innerCircleInset)))

        outerCircleLayer.lineWidth = outerCircleLineWidth
        outerCircleLayer.path = outerCircle.cgPath
        innerCircleLayer.path = innerCircle.cgPath
    }
}

final class ZoomButton: UIControl {
    private lazy var outerCircleLayer = CAShapeLayer()
    var zoomFactor: CGFloat = 1 {
        didSet {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            textLabel.text = (formatter.string(from: NSNumber(value: Float(zoomFactor))) ?? String(format: "%.2f", zoomFactor)) + "x"
        }
    }
    
    private lazy var textLabel: UILabel = UILabel(frame: .zero)
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        backgroundColor = .clear
        
        outerCircleLayer.strokeColor = UIColor.white.cgColor
        outerCircleLayer.fillColor = UIColor.black.withAlphaComponent(0.25).cgColor
        layer.addSublayer(outerCircleLayer)
        
        addSubview(textLabel)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4).isActive = true
        trailingAnchor.constraint(equalTo: textLabel.trailingAnchor, constant: 4).isActive = true
        textLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        textLabel.textAlignment = .center
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = 0.5
        textLabel.font = UIFont.systemFont(ofSize: 10)
        textLabel.textColor = .white
        textLabel.text = "1x"
        
        addTarget(self, action: #selector(self.pressed), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(self.released), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
    }
    
    @objc func pressed(sender: Any) {
        let scale: CGFloat = 0.9
        
        UIView.animateAsSpring(0.3, animations: {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        })
    }
    
    @objc func released(sender: Any) {
        UIView.animateAsSpring(0.3, animations: {
            self.transform = CGAffineTransform.identity
        })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let outerCircle = UIBezierPath(ovalIn: bounds.inset(by: UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)))
        outerCircleLayer.lineWidth = 1
        outerCircleLayer.path = outerCircle.cgPath
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let touchBounds = bounds.inset(by: UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10))
        if touchBounds.contains(point) {
            return self
        }
        else {
            return super.hitTest(point, with: event)
        }
    }
}

private protocol UICameraPrivateDefaults: PropertyDefaults{
    var isRawPhotoSupported: Bool {get set}
}

extension Defaults: UICameraPrivateDefaults {
    var isRawPhotoSupported: Bool {
        set { set(newValue); }
        get { return get(or:false) }
    }
}

extension UICamera{
    fileprivate static let privateDefaults:UICameraPrivateDefaults = Defaults(suiteName: fileName())
}
