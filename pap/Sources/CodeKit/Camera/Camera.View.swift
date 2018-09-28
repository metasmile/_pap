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

class CameraViewCapturedResult:NSObject{
    let succeed:Bool
    let results:CaptureProcessorResult?

    init(succeed:Bool, result:CaptureProcessorResult?){
        self.succeed = succeed
        self.results = result
    }
}

class CameraView: UIView, PropertyWatchable {
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
    private lazy var capturePhotoOutput = AVCapturePhotoOutput()
    private lazy var currentPhotoSettings: AVCapturePhotoSettings = {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        settings.flashMode = .off
        return settings
    }()
    private(set) lazy var deviceMotion = UIDeviceMotion()

    var configurationDidUpdate: (() -> Void)?
    @objc dynamic
    var capturedResult:CameraViewCapturedResult?
    var captureMetadataComment:String?

    private lazy var sessionQueue = DispatchQueue(label: "com.stells.internal."+#file, qos: .utility)
    
    private lazy var captureVideoDataQueue = DispatchQueue(label: "com.stells.internal."+#file, qos: .utility)
    var captureVideoDataDidUpdate: ((_ sampleBuffer: CMSampleBuffer) -> Void)?

    private lazy var cameraPreviewView = CameraPreviewView(frame: .zero)
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
    
    var capturePreset: AVCaptureSession.Preset = .photo {
        didSet {
            captureSession?.sessionPreset = capturePreset
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

    private func configureSession() {
        captureSession = AVCaptureSession()
        
        guard
            let videoDevice = AVCaptureDevice.default(for: .video),
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            let captureSession = captureSession,
            captureSession.canAddInput(videoDeviceInput)
        else { return }

        beginConfiguration()

        captureSession.addInput(videoDeviceInput)

        try? videoDevice.lockForConfiguration()

        videoDevice.focusMode = .continuousAutoFocus
        videoDevice.exposureMode = .continuousAutoExposure
        videoDevice.unlockForConfiguration()

        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice),
           captureSession.canAddInput(audioDeviceInput) {
            captureSession.addInput(audioDeviceInput)
        }

        capturePhotoOutput.isHighResolutionCaptureEnabled = true

        captureSession.sessionPreset = capturePreset
        captureSession.addOutput(capturePhotoOutput)
        
        let captureVideoDataOutput = AVCaptureVideoDataOutput()
        captureVideoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
        captureVideoDataOutput.setSampleBufferDelegate(self, queue: captureVideoDataQueue)
        captureVideoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(captureVideoDataOutput) {
            captureSession.addOutput(captureVideoDataOutput)
        }

        commitConfiguration()

        cameraPreviewView.setSession(captureSession)
        updateVideoOrientation()
    }

    func startSession() {
        deviceMotion.startUpdates(interval: 0.6)
        sessionQueue.async {
            if self.captureSession == nil {
                self.configureSession()
            }
            self.captureSession?.startRunning()
        }
    }

    func stopSession() {
        deviceMotion.stopUpdates()
        sessionQueue.async {
            self.captureSession?.stopRunning()
        }
    }
    
    func beginConfiguration() {
        captureSession?.beginConfiguration()
    }

    func commitConfiguration() {
        captureSession?.commitConfiguration()
        configurationDidUpdate?()
    }

    var capturesInProgress = Set<CaptureProcessor>()

    func takePhoto(completion:CaptureProcessorCompletionHandler?=nil) {
        guard let _ = self.capturePhotoOutput.connection(with: .video) else { return }
        
        performShutterAnimation()

        let captureProcessor: CaptureProcessor
        let param = CaptureProcessorParam(
                videoDeviceInput: currentVideoDeviceInput
                , deviceOrientation: deviceMotion.orientation
                , metadataComment: captureMetadataComment
        )

        let photoSettings:AVCapturePhotoSettings

        if self.capturePhotoOutput.availablePhotoCodecTypes.contains(.hevc), capturePhotoOutput.isLivePhotoCaptureEnabled {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            photoSettings.livePhotoMovieFileURL = FileURL.temp(UUID().uuidString, UTI.quickTimeMovie, group: FileURL.fileAndQueuePrivateGroup())
            photoSettings.flashMode = self.currentFlashMode
            captureProcessor = CameraViewLivePhotoCaptureProcessor(param: param)
        } else {
            photoSettings = AVCapturePhotoSettings(from: self.currentPhotoSettings)
            captureProcessor = CameraViewStillPhotoCaptureProcessor(param: param)
        }
        photoSettings.isAutoStillImageStabilizationEnabled = capturePhotoOutput.isStillImageStabilizationSupported

        capturesInProgress.insert(captureProcessor)

        // Schedule for the capture delegate to be removed from the set after capture.
        captureProcessor.completionHandler = { [weak self] succeed, result in
            self?.capturesInProgress.remove(captureProcessor)
            self?.capturedResult = CameraViewCapturedResult(succeed: succeed, result: result)
            completion?(succeed, succeed ? result : nil)
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
        let captureDeviceInputs = self.captureSession?.inputs as? [AVCaptureDeviceInput]
        return captureDeviceInputs?.first { $0.device.hasMediaType(mediaType) }
    }

    fileprivate var currentVideoDeviceInput:AVCaptureDeviceInput? {
        return self.currentCaptureDeviceInput(for:.video)
    }

    func switchCaptureDevicePosition(animated: Bool = true, completion:((AVCaptureDevice.Position) -> ())?=nil) {
        guard let currentDevice = self.currentVideoDeviceInput else { return }
        let position: AVCaptureDevice.Position = currentDevice.device.position == .back ? .front : .back

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
            guard let currentDevice = self.currentVideoDeviceInput else { completion?(); return }
            let isLivePhotoEnabled = self.capturePhotoOutput.isLivePhotoCaptureEnabled

            self.beginConfiguration()
            self.captureSession?.removeInput(currentDevice)

            if let newDevice = self.captureDevice(with: position), let deviceInput = try? AVCaptureDeviceInput(device: newDevice), self.captureSession?.canAddInput(deviceInput) == true {
                self.captureSession?.addInput(deviceInput)
            }
            else {
                self.captureSession?.addInput(currentDevice)
            }

            //INFO: keep live photo settings
            if self.capturePhotoOutput.isLivePhotoCaptureEnabled != isLivePhotoEnabled {
                self.capturePhotoOutput.isLivePhotoCaptureEnabled = isLivePhotoEnabled
            }
            
            if let connection = self.capturePhotoOutput.connection(with: .video), connection.isVideoMirroringSupported {
                connection.isVideoMirrored = position == .front
            }

            self.commitConfiguration()

            completion?()
        }
    }

    override var contentMode: UIViewContentMode {
        didSet {
            cameraPreviewView.contentMode = contentMode
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

extension CameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.captureVideoDataDidUpdate?(sampleBuffer)
    }
}

extension CameraView {
    var cameraPosition: AVCaptureDevice.Position {
        get {
            return currentCaptureDeviceInput(for: .video)?.device.position ?? .unspecified
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

extension CameraView {
    var isLivePhotoSupported: Bool {
        return capturePhotoOutput.isLivePhotoCaptureSupported
    }

    var isLivePhotoEnabled: Bool {
        set {
            sessionQueue.async {
                self.capturePhotoOutput.isLivePhotoCaptureEnabled = newValue
                self.configurationDidUpdate?()
            }
        }

        get {
            return capturePhotoOutput.isLivePhotoCaptureEnabled
        }
    }

    var currentFlashMode: AVCaptureDevice.FlashMode {
        set {
            self.currentPhotoSettings.flashMode = newValue
            self.configurationDidUpdate?()
        }
        get {
            return currentPhotoSettings.flashMode
        }
    }
}

extension CameraView {
    func changeFocusMode(_ mode: AVCaptureDevice.FocusMode) {
        guard
            let captureDevice = captureDevice(with: cameraPosition),
            let _ = try? captureDevice.lockForConfiguration()
        else { return }
        
        if captureDevice.isFocusModeSupported(mode) {
            captureDevice.focusMode = mode
        }
        
        captureDevice.unlockForConfiguration()
    }
    
    func changeExposureMode(_ mode: AVCaptureDevice.ExposureMode) {
        guard
            let captureDevice = captureDevice(with: cameraPosition),
            let _ = try? captureDevice.lockForConfiguration()
        else { return }
        
        if captureDevice.isExposureModeSupported(mode) {
            captureDevice.exposureMode = mode
        }
        
        captureDevice.unlockForConfiguration()
    }
}

extension CameraView {
    func pointOfInterest(at location: CGPoint) -> CGPoint {
        let layerPoint = layer.convert(location, to: cameraPreviewView.previewLayer)
        return cameraPreviewView.previewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)
    }
    
    func updatePointOfInterest(at location: CGPoint, showsGuide: Bool = true) {
        let layerPoint = layer.convert(location, to: cameraPreviewView.previewLayer)
        let pointOfInterest = cameraPreviewView.previewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)
        
        sessionQueue.async {
            self.setPointOfInterest(pointOfInterest)
        }
        
        cameraPointOfInterestLayer?.removeFromSuperlayer()
        
        if showsGuide {
            performPointOfInterestAnimation(at: layerPoint)
        }
    }
    
    private func setPointOfInterest(_ pointOfInterest: CGPoint) {
        guard
            let captureDevice = captureDevice(with: cameraPosition),
            let _ = try? captureDevice.lockForConfiguration()
        else { return }
        
        if captureDevice.isFocusPointOfInterestSupported {
            captureDevice.focusPointOfInterest = pointOfInterest
        }
        
        if captureDevice.isExposurePointOfInterestSupported {
            captureDevice.exposurePointOfInterest = pointOfInterest
        }
        
        if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
            captureDevice.focusMode = .continuousAutoFocus
        }
        
        if captureDevice.isExposureModeSupported(.continuousAutoExposure) {
            captureDevice.exposureMode = .continuousAutoExposure
        }
        
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
        shapeLayer.strokeColor = UIColor(red:1, green:0.83, blue:0, alpha:0.95).cgColor
        shapeLayer.lineWidth = 1.0
        
        layer.addSublayer(shapeLayer)
        
        cameraPointOfInterestLayer = shapeLayer
        
        CATransaction.begin()
        
        CATransaction.setAnimationDuration(0.2)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
        
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
        disappearOpacityAnimation.fillMode = kCAFillModeForwards
        disappearOpacityAnimation.isRemovedOnCompletion = false
        shapeLayer.add(disappearOpacityAnimation, forKey: "opacity")
        
        CATransaction.commit()
    }
}

extension CameraView {
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

fileprivate class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        return CameraPreviewLayer.self
    }

    fileprivate var previewLayer: CameraPreviewLayer {
        return layer as! CameraPreviewLayer
    }

    override var contentMode: UIViewContentMode {
        didSet {
            switch contentMode {
            case .scaleAspectFit:
                previewLayer.contentsGravity = kCAGravityResizeAspect
                previewLayer.videoGravity = .resizeAspect
            case .scaleAspectFill:
                previewLayer.contentsGravity = kCAGravityResizeAspectFill
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

        let outerCircle = UIBezierPath(ovalIn: UIEdgeInsetsInsetRect(bounds, UIEdgeInsets(top: outerCircleInset, left: outerCircleInset, bottom: outerCircleInset, right: outerCircleInset)))
        let innerCircle = UIBezierPath(ovalIn: UIEdgeInsetsInsetRect(bounds, UIEdgeInsets(top: innerCircleInset, left: innerCircleInset, bottom: innerCircleInset, right: innerCircleInset)))

        outerCircleLayer.lineWidth = outerCircleLineWidth
        outerCircleLayer.path = outerCircle.cgPath
        innerCircleLayer.path = innerCircle.cgPath
    }
}
