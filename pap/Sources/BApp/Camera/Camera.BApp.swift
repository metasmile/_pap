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
import DefaultsKit

protocol CameraAppDefaults: AppDefaults {
    var isLivePhotoEnabled: Bool { get set }
    var cameraPosition: AVCaptureDevice.Position { get set }
}

extension Defaults: CameraAppDefaults {
    var isLivePhotoEnabled: Bool {
        set { set(newValue) }
        get { return get(or: false) }
    }
    
    var cameraPosition: AVCaptureDevice.Position {
        set { set(newValue.rawValue) }
        get { return AVCaptureDevice.Position(rawValue: get(or: AVCaptureDevice.Position.back.rawValue)) ?? .back }
    }
}

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
    
    var session: AVCaptureSession? {
        set {
            captureVideoPreviewLayer?.session = newValue
        }
        
        get {
            return captureVideoPreviewLayer?.session
        }
    }
}

fileprivate class CameraView: UIView {
    private lazy var captureSession = AVCaptureSession()
    private lazy var capturePhotoOutput = AVCapturePhotoOutput()
    private lazy var defaultCapturePhotoSettings: AVCapturePhotoSettings = {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        return settings
    }()
    
    var configurationDidUpdate: (() -> Void)?
    
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
        
        cameraPreviewView.session = captureSession
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
    
    func beginConfiguration() {
        captureSession.beginConfiguration()
    }
    
    func commitConfiguration() {
        captureSession.commitConfiguration()
        configurationDidUpdate?()
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
    
    func switchCaptureDevicePosition(animated: Bool = true) {
        guard let currentDevice = self.currentCaptureDeviceInput(for: .video) else { return }
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
            guard let currentDevice = self.currentCaptureDeviceInput(for: .video) else { completion?(); return }
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

fileprivate class CaptureButton: UIControl {
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

fileprivate class CameraAppView: UIView {
    lazy var cameraView: CameraView = {
        let cameraView = CameraView(frame: .zero)
        cameraView.backgroundColor = .black
        cameraView.contentMode = .scaleAspectFill
        cameraView.setUp()
        
        cameraView.addGestureRecognizer(tapGesture)
        
        return cameraView
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapToCapture))
    
    private var optionViewHeightLayout: NSLayoutConstraint?
    private var cameraAspectRatioLayout: NSLayoutConstraint?
    
    fileprivate var primaryColor = UIColor(red: 0.97, green: 0.8, blue: 0.27, alpha: 1) // 248    204    70
    
    private lazy var userSettings = CameraApp.defaults as! CameraAppDefaults
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        intialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        intialize()
    }
    
    private lazy var captureButton = CaptureButton(frame: .zero)
    private lazy var cameraPositionButton = UIButton(type: .system)

    private func intialize() {
        tintColor = UIColor.white
        
        let buttonImageInsets = UIEdgeInsetsMake(4, 4, 4, 4)
        
        let optionView = UIView(frame: .zero)
        optionView.backgroundColor = .black
        addSubview(optionView)
        optionView.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        cameraAspectRatioLayout = cameraView.heightAnchor.constraint(equalTo: cameraView.widthAnchor, multiplier: 1.3)
        cameraAspectRatioLayout?.isActive = true
        
        optionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        optionView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor).isActive = true
        optionView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor).isActive = true
        optionViewHeightLayout = optionView.heightAnchor.constraint(equalToConstant: 0)
        optionViewHeightLayout?.isActive = true
        
        let livePhotoButton = UIButton(type: .system)
        livePhotoButton.imageEdgeInsets = buttonImageInsets
        livePhotoButton.imageView?.contentMode = .scaleAspectFit
        livePhotoButton.contentHorizontalAlignment = .fill
        livePhotoButton.contentVerticalAlignment = .fill
        livePhotoButton.setImage(livePhotoBadgeIcon, for: .normal)
        livePhotoButton.addTarget(self, action: #selector(self.toggleLivePhotoEnabled), for: .touchUpInside)
        optionView.addSubview(livePhotoButton)
        
        livePhotoButton.translatesAutoresizingMaskIntoConstraints = false
        livePhotoButton.centerXAnchor.constraint(equalTo: optionView.centerXAnchor).isActive = true
        livePhotoButton.topAnchor.constraint(equalTo: optionView.topAnchor).isActive = true
        livePhotoButton.bottomAnchor.constraint(equalTo: optionView.bottomAnchor).isActive = true
        livePhotoButton.widthAnchor.constraint(equalTo: optionView.heightAnchor, multiplier: 1).isActive = true
        
        let controlView = UIView(frame: .zero)
        controlView.backgroundColor = .black
        addSubview(controlView)
        
        controlView.translatesAutoresizingMaskIntoConstraints = false
        controlView.topAnchor.constraint(equalTo: cameraView.bottomAnchor).isActive = true
        controlView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor).isActive = true
        controlView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor).isActive = true
        controlView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        captureButton.addTarget(self, action: #selector(self.tapToCapture), for: .touchUpInside)
        addSubview(captureButton)
        
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
        captureButton.centerXAnchor.constraint(equalTo: controlView.centerXAnchor).isActive = true
        captureButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        captureButton.heightAnchor.constraint(lessThanOrEqualToConstant: 72).isActive = true
        captureButton.widthAnchor.constraint(equalTo: captureButton.heightAnchor, multiplier: 1).isActive = true
        
        let captureButtonTopLayout = captureButton.topAnchor.constraint(equalTo: controlView.topAnchor)
        captureButtonTopLayout.priority = .defaultLow - 1
        captureButtonTopLayout.isActive = true
        
        let captureButtonCenterYLayout = captureButton.centerYAnchor.constraint(equalTo: controlView.centerYAnchor)
        captureButtonCenterYLayout.priority = .defaultLow
        captureButtonCenterYLayout.isActive = true
        
        cameraPositionButton.imageEdgeInsets = buttonImageInsets
        cameraPositionButton.setImage(devicePositionIcon, for: .normal)
        cameraPositionButton.addTarget(self, action: #selector(self.switchDevicePosition), for: .touchUpInside)
        addSubview(cameraPositionButton)
        
        cameraPositionButton.translatesAutoresizingMaskIntoConstraints = false
        cameraPositionButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
        cameraPositionButton.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -2).isActive = true
        cameraPositionButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        cameraPositionButton.widthAnchor.constraint(equalTo: cameraPositionButton.heightAnchor, multiplier: 1).isActive = true
        
        let cameraPositionButtonCenterYLayout = cameraPositionButton.centerYAnchor.constraint(equalTo: optionView.centerYAnchor)
        cameraPositionButtonCenterYLayout.priority = .defaultLow
        cameraPositionButtonCenterYLayout.isActive = true
        
        cameraView.configurationDidUpdate = {
            self.userSettings.isLivePhotoEnabled = self.cameraView.isLivePhotoEnabled
            self.userSettings.cameraPosition = self.cameraView.cameraPosition
            
            DispatchQueue.main.async {
                livePhotoButton.setImage(self.livePhotoBadgeIcon, for: .normal)
                livePhotoButton.tintColor = self.cameraView.isLivePhotoEnabled ? self.primaryColor : nil
            }
        }
        
        self.cameraView.isLivePhotoEnabled = self.userSettings.isLivePhotoEnabled
        self.cameraView.cameraPosition = self.userSettings.cameraPosition
    }
    
    private var devicePositionIcon: UIImage {
        return { () -> UIImage in
            return (self.isCompactMode ? R.image.cameraBAppPositionIntaglio() : R.image.cameraBAppPositionEmboss()) ?? UIImage()
        }().withRenderingMode(.alwaysTemplate)
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
    
    @objc func switchDevicePosition(sender: Any) {
        cameraView.switchCaptureDevicePosition()
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
            captureButton.isEnabled = !isCompactMode

            cameraPositionButton.setImage(self.devicePositionIcon, for: .normal)
            
            //TODO: ignore layer implicit animation
            layoutIfNeeded()
        }
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
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
        
        if let pref = preferences, view.bounds.height > pref.preferredHeight {
            (view as? CameraAppView)?.isCompactMode = false
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
