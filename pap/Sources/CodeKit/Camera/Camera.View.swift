//
// Created by BLACKGENE on 15.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Photos
import PhotosUI

class CameraView: UIView {
    private lazy var captureSession = AVCaptureSession()
    private lazy var capturePhotoOutput = AVCapturePhotoOutput()
    private lazy var defaultCapturePhotoSettings: AVCapturePhotoSettings = {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        return settings
    }()
    private lazy var deviceMotion = UIDeviceMotion()

    var configurationDidUpdate: (() -> Void)?
    var capturedHandler:CaptureProcessorCompletionHandler?

    private lazy var sessionQueue = DispatchQueue(label: "com.stells.internal."+#file, qos: .utility)

    private lazy var cameraPreviewView = CameraPreviewView(frame: .zero)

    private var blurredSnapshotView: UIView?

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

        captureSession.sessionPreset = .photo
        captureSession.addOutput(capturePhotoOutput)

        commitConfiguration()

        cameraPreviewView.setSession(captureSession)
    }

    func startSession() {
        deviceMotion.startUpdates()
        sessionQueue.async {
            self.captureSession.startRunning()
        }
    }

    func stopSession() {
        deviceMotion.stopUpdates()
        sessionQueue.async {
            self.captureSession.stopRunning()
        }
    }

    func beginConfiguration() {
        captureSession.beginConfiguration()
    }

    func commitConfiguration() {
        captureSession.commitConfiguration()
        configurationDidUpdate?()
    }

    var capturesInProgress = Set<CaptureProcessor>()

    func takePhoto() {
        performShutterAnimation()

        let captureProcessor: CaptureProcessor
        let param = CaptureProcessorParameter(videoDeviceInput: self.currentVideoDeviceInput, deviceOrientation: deviceMotion.orientation)

        let photoSettings: AVCapturePhotoSettings
        if self.capturePhotoOutput.availablePhotoCodecTypes.contains(.hevc), capturePhotoOutput.isLivePhotoCaptureEnabled {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            photoSettings.livePhotoMovieFileURL = FileURL.temp(UUID().uuidString, UTI.quickTimeMovie, group: FileURL.fileAndQueuePrivateGroup())
            captureProcessor = CameraViewLivePhotoCaptureProcessor(parameter: param)
        } else {
            photoSettings = AVCapturePhotoSettings(from: self.defaultCapturePhotoSettings)
            captureProcessor = CameraViewStillPhotoCaptureProcessor(parameter: param)
        }
        photoSettings.flashMode = .auto
        photoSettings.isAutoStillImageStabilizationEnabled = capturePhotoOutput.isStillImageStabilizationSupported

        capturesInProgress.insert(captureProcessor)

        // Schedule for the capture delegate to be removed from the set after capture.
        captureProcessor.completionHandler = { [weak self] succeed, result in
            self?.capturesInProgress.remove(captureProcessor)
            self?.capturedHandler?(succeed, succeed ? result : nil)
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

    fileprivate var currentVideoDeviceInput:AVCaptureDeviceInput? {
        return self.currentCaptureDeviceInput(for:.video)
    }

    func switchCaptureDevicePosition(animated: Bool = true) {
        guard let currentDevice = self.currentVideoDeviceInput else { return }
        let position: AVCaptureDevice.Position = currentDevice.device.position == .back ? .front : .back

        if animated {
            let switchingView = performSwitchCameraPositionAnimation(to: position)
            setCaptureDevicePosition(position) {
                DispatchQueue.main.async {
                    UIView.transition(with: self, duration: 0.5, options: .transitionCrossDissolve, animations: {
                        switchingView.removeFromSuperview()
                    }, completion: nil)
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
            self.captureSession.removeInput(currentDevice)

            if let newDevice = self.captureDevice(with: position), let deviceInput = try? AVCaptureDeviceInput(device: newDevice), self.captureSession.canAddInput(deviceInput) {
                self.captureSession.addInput(deviceInput)
            }
            else {
                self.captureSession.addInput(currentDevice)
            }

            //INFO: keep live photo settings
            if self.capturePhotoOutput.isLivePhotoCaptureEnabled != isLivePhotoEnabled {
                self.capturePhotoOutput.isLivePhotoCaptureEnabled = isLivePhotoEnabled
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

    private var captureVideoPreviewLayer: CameraPreviewLayer? {
        return layer as? CameraPreviewLayer
    }

    override var contentMode: UIViewContentMode {
        didSet {
            switch contentMode {
            case .scaleAspectFit:
                captureVideoPreviewLayer?.contentsGravity = kCAGravityResizeAspect
                captureVideoPreviewLayer?.videoGravity = .resizeAspect
            case .scaleAspectFill:
                captureVideoPreviewLayer?.contentsGravity = kCAGravityResizeAspectFill
                captureVideoPreviewLayer?.videoGravity = .resizeAspectFill
            default: break
            }
        }
    }

    func setSession(_ session:AVCaptureSession){
        captureVideoPreviewLayer?.session = session
    }

    var session: AVCaptureSession? {
        return captureVideoPreviewLayer?.session
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

        let scale = min(1, bounds.height / 72)

        let inset = scale < 1 ? bounds.height * 0.1 : 0
        let outerCircleLineWidth: CGFloat = scale < 1 ? 4 * scale : 6
        let outerCircleInset = outerCircleLineWidth / 2 + inset
        let innerCircleInset = outerCircleLineWidth + (scale < 1 ? 3 * scale : 2) + inset

        let outerCircle = UIBezierPath(ovalIn: UIEdgeInsetsInsetRect(bounds, UIEdgeInsets(top: outerCircleInset, left: outerCircleInset, bottom: outerCircleInset, right: outerCircleInset)))
        let innerCircle = UIBezierPath(ovalIn: UIEdgeInsetsInsetRect(bounds, UIEdgeInsets(top: innerCircleInset, left: innerCircleInset, bottom: innerCircleInset, right: innerCircleInset)))

        outerCircleLayer.lineWidth = outerCircleLineWidth
        outerCircleLayer.path = outerCircle.cgPath
        innerCircleLayer.path = innerCircle.cgPath
    }
}