//
//  MemoCam.BApp.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 7. 17..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import PropertyKit
import Vision

private class _MemoCamAppTask: AppTaskPrototype, AppTaskable {
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){}
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        return nil
    }
}

class MemoCamApp: NSObject, PropertyWatchable, BApp, LaunchableApp, AppDockApp, PhotoPickerCollectionViewDisplayableApp, AVCaptureDeviceApp {
    static var taskType: AppTaskable.Type = _MemoCamAppTask.self
    static var paramType: AppTaskParamable.Type = AppAsset.self
    
    public private(set) lazy var content: AppDockContent? = MemoCamAppDockContent()
    public private(set) static var fixedContentLayout: Bool = true
    
    public static let info = AppInfo(
        identifier: "com.stells.pap.memocam"
        , version: "1.0"
        , phase: .develop
        , appType: MemoCamApp.self
        , displayName: "Memo Cam".localized, description:nil, keywords:nil
        , iconBundleName: nil
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
    }
}


import FirebaseMLVision

private struct MemoCamAppDetector {
    private let vision = Vision.vision()
    private var textDetector: VisionTextDetector

    init() {
        textDetector = vision.textDetector()
    }


    fileprivate mutating func detectResult(image: UIImage, _ async: AsyncWaitSignalable) -> VisionTextImageDetectResult? {
        guard let visionTexts = self.textDetector.detect(with: image, async) else {
            return nil
        }

        var result = VisionTextImageDetectResult(image: image)
        result.sourceVisionTexts = visionTexts

        var resultGroup = VisionTextResultGroup()

        resultGroup.emails = visionTexts.parse(type: VisionTextEmailAddressParser.self, async)
        resultGroup.phoneNumbers = visionTexts.parse(type: VisionTextPhoneNumberParser.self, async)
        if let urls = visionTexts.parse(type: VisionTextURLParser.self, async){
            //excluding mail addresses
            resultGroup.urls = urls.compactMap { $0.compactMap { $0.scheme == "mailto" ? nil : $0 }.nilEmpty }
        }
        resultGroup.addresses = visionTexts.parse(type: VisionTextAddressParser.self, async)
        resultGroup.flights = visionTexts.parse(type: VisionTextFlightNumberParser.self, async)
        resultGroup.dates = visionTexts.parse(type: VisionTextDateParser.self, async)

        result.resultGroup = resultGroup


        return result
    }
}

fileprivate class PolygonLayer: CAShapeLayer {
    init(points: [CGPoint]) {
        super.init()
        
        guard let firstPoint = points.first else { return }
        let polygon = UIBezierPath()
        polygon.move(to: firstPoint)
        points[1...].forEach {
            polygon.addLine(to: $0)
        }
        polygon.close()
        
        self.path = polygon.cgPath
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class ResultItemLayer: CAShapeLayer {
    var result: VisionText?
    
    lazy var badgeLayer = CALayer()
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    override init() {
        super.init()
        
        initialize()
    }
    
    var highlighted: Bool = false {
        didSet {
            fillColor = highlighted ? UIColor(white: 1, alpha: 0.6).cgColor : UIColor.clear.cgColor
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func initialize() {
        strokeColor = UIColor.red.cgColor
        fillColor = UIColor.clear.cgColor
        lineWidth = 1
        
        let badgeSize: CGFloat = 32
        
        addSublayer(badgeLayer)
        badgeLayer.contentsGravity = kCAGravityResizeAspectFill
        badgeLayer.cornerRadius = badgeSize / 2
        badgeLayer.masksToBounds = true
        badgeLayer.backgroundColor = UIColor.white.cgColor
        badgeLayer.frame.size = CGSize(width: badgeSize, height: badgeSize)
        badgeLayer.isHidden = true
    }
    
    func showBadgeIcon(at point: CGPoint) {
        badgeLayer.contents = R.image.finderBAppIcon()?.cgImage
        badgeLayer.isHidden = false
        badgeLayer.position = point
    }
}

fileprivate protocol ResultPreviewViewDelegate {
    func resultPreviewView(_ view: ResultPreviewView, didSelectItemWith visionText: VisionText)
}

fileprivate class ResultPreviewView: DesignableView {
    lazy var imageView: UIImageView = UIImageView(frame: .zero)
    var delegate: ResultPreviewViewDelegate?
    
    override func initialize() {
        super.initialize()
        
        addSubview(imageView)
        imageView.fitConstraints(to: self)
        
        imageView.contentMode = .scaleAspectFill
        
        layer.addSublayer(resultsLayer)
    }
    
    lazy var resultsLayer: CALayer = {
        let layer = CALayer()
        return layer
    }()
    
    var image: UIImage? {
        set {
            imageView.image = newValue
            
            if let _ = newValue {
                
            }
            else {
               resultsLayer.sublayers = nil
            }
        }
        
        get {
            return imageView.image
        }
    }
    
    func reloadResults(_ results: VisionTextImageDetectResult) {
        let visionTexts = results.sourceVisionTexts ?? []
        
        let async = AsyncSignal()
        if let emails = visionTexts.parse(type: VisionTextEmailAddressParser.self, async) {
            
        }
        
        DispatchQueue.main.async {
            let disableActions = CATransaction.disableActions()
            CATransaction.setDisableActions(true)
            self.resultsLayer.sublayers = nil
            
            let previewSize = results.image.size.aspectFill(in: self.bounds.size)
            self.resultsLayer.frame = CGRect(origin: CGPoint(x: (self.bounds.width - previewSize.width) / 2, y: (self.bounds.height - previewSize.height) / 2), size: previewSize)
            
            for visionText in visionTexts {
                self.drawResult(visionText, in: results.image.size)
            }
            CATransaction.setDisableActions(disableActions)
        }
    }
    
    private func drawResult(_ visionText: VisionText, in size: CGSize) {
        let path = UIBezierPath()
        for point in visionText.cornerPoints.map({ $0.cgPointValue }) {
            if path.isEmpty {
                path.move(to: point)
            }
            else {
                path.addLine(to: point)
            }
        }
        path.apply(CGAffineTransform(scaleX: resultsLayer.frame.width / size.width, y: resultsLayer.frame.height / size.height))
        path.close()
        
        let layer = ResultItemLayer()
        layer.result = visionText
        layer.path = path.cgPath
        layer.showBadgeIcon(at: CGPoint(x: max(20, min(path.currentPoint.x, bounds.width - 30)), y: max(30, min(path.currentPoint.y, bounds.height - 30))))
        
        resultsLayer.addSublayer(layer)
    }
    
    private var currentHitLayer: ResultItemLayer?
    private func resultItemLayer(at point: CGPoint) -> ResultItemLayer? {
        let layerLocation = layer.convert(point, to: resultsLayer)
        for layer in resultsLayer.sublayers?.compactMap({ $0 as? ResultItemLayer }) ?? [] {
            if layer.path?.contains(layerLocation) == true {
//            if layer.path?.boundingBoxOfPath.contains(layerLocation) == true {
                return layer
            }
        }
        return nil
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let _ = resultItemLayer(at: point) {
            return self
        }
        else {
            return nil
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let point = touches.first?.location(in: self) else { return }
        
        currentHitLayer = resultItemLayer(at: point)
        currentHitLayer?.highlighted = true
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        guard let point = touches.first?.location(in: self), let boundingBoxOfPath = resultItemLayer(at: point)?.path?.boundingBoxOfPath else {
            currentHitLayer?.highlighted = false
            return
        }
        currentHitLayer?.highlighted = (currentHitLayer?.path?.boundingBoxOfPath.intersects(boundingBoxOfPath) == true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard let point = touches.first?.location(in: self) else { return }
        
        guard currentHitLayer == resultItemLayer(at: point) else {
            self.touchesCancelled(touches, with: event)
            return
        }
        
        DispatchQueue.main.async {
            UIFeedback.select()
        }
        
        if let visionText = currentHitLayer?.result {
            delegate?.resultPreviewView(self, didSelectItemWith: visionText)
        }
        
        currentHitLayer?.highlighted = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        currentHitLayer?.highlighted = false
        currentHitLayer = nil
    }
}

fileprivate class MemoCamAppDockContent: NSObject, PropertyWatchable, AppDockContent, AppDockDelegate {
    lazy var cameraView: CameraView = {
        let cameraView = CameraView(frame: .zero)
        cameraView.clipsToBounds = true
        cameraView.contentMode = .scaleAspectFill
        cameraView.setUp()
        return cameraView
    }()
    
    lazy var view: UIView = {
        let view = UIView(frame: .zero)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.cameraViewDidTap))
        cameraView.addGestureRecognizer(tapGesture)
        
        view.addSubview(cameraView)
        cameraView.fitConstraints(to: view)
        
        cameraView.capturePreset = .high
        
        return view
    }()
    
    lazy var resultPreviewView: ResultPreviewView = {
        let view = ResultPreviewView(frame: .zero)
        return view
    }()
    
    internal class DisableImplicitAnimatableShapeLayer: CAShapeLayer {
        override func action(forKey event: String) -> CAAction? {
            switch event {
            case "position", "onOrderIn", "onOrderOut", "path": return NSNull()
            default: return super.action(forKey: event)
            }
        }
    }
    
    private lazy var debugLayer: DisableImplicitAnimatableShapeLayer = {
        let layer = DisableImplicitAnimatableShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.red.cgColor
        layer.lineWidth = 1
        return layer
    }()
    
    private lazy var detector = MemoCamAppDetector()
    
    var preferences: AppDockContentPreferable? {
        var pref = AppDockContentPreferences()
        pref.preferredHeight = AppDockContentPreferences.GreatestHeight
        return pref
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        
    }
    
    struct DetectedLabel {
        var boundingRect: CGRect
        var visionTexts: [VisionText]
    }
    
    func didSetContentView(_ view: UIView, dock: AppDock) {
        debugLayer.removeFromSuperlayer()
        
        cameraView.layer.addSublayer(debugLayer)
        
        let detectTextRequest = VNDetectTextRectanglesRequest { (request, error) in
            guard let observations = request.results as? [VNTextObservation] else { return }
            
            DispatchQueue.main.async {
                let previewSize = self.cameraView.captureVideoSize.aspectFill(in: self.cameraView.bounds.size)
                
                let path = UIBezierPath()
                for observation in observations {
                    let polygon = UIBezierPath()
                    polygon.move(to: observation.topLeft)
                    polygon.addLine(to: observation.topRight)
                    polygon.addLine(to: observation.bottomRight)
                    polygon.addLine(to: observation.bottomLeft)
                    polygon.close()
                    
                    path.append(polygon)
                }
                
                let transform = CGAffineTransform.identity
                    .scaledBy(x: 1, y: -1)
                    .translatedBy(x: 0, y: -previewSize.height)
                    .scaledBy(x: previewSize.width, y: previewSize.height)
                
                path.apply(transform)
                
                self.debugLayer.path = path.cgPath
                self.debugLayer.frame = CGRect(origin: CGPoint(x: (self.cameraView.bounds.width - previewSize.width) / 2, y: (self.cameraView.bounds.height - previewSize.height) / 2), size: previewSize)
            }
        }
        
        cameraView.startSession()
        cameraView.captureVideoDataDidUpdate = { sampleBuffer in
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let deviceOrientation = self.cameraView.deviceMotion.orientation
            
            if self.needsCaptureImage {
                self.needsCaptureImage = false
                
                self.cameraView.performShutterAnimation()
                
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(forExifOrientation: Int32(deviceOrientation.exifOrientation(frontFacing: false).rawValue))
                
                var image: UIImage?
                if let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) {
                    image = UIImage(cgImage: cgImage)
                }
                
                self.detect(with: image)
            }
            
            var options: [VNImageOption: Any] = [:]
            if let cameraIntrinsicMatrix = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
                options[VNImageOption.cameraIntrinsics] = cameraIntrinsicMatrix
            }
            
            try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: UInt32(deviceOrientation.exifOrientation(frontFacing: false).rawValue)) ?? .rightMirrored, options: options).perform([detectTextRequest])
        }
    }
    
    func willRemoveContentView() {
        cameraView.captureVideoDataDidUpdate = nil
        cameraView.stopSession()
    }
    
    var delegate: AppDockDelegate? {
        return self
    }
    
    func dockWillExpand(_ dock: AppDock) {
        
    }
    
    func dockWillContract(_ dock: AppDock) {
        
    }
    
    private var currentTargetImage: UIImage? {
        didSet {
            DispatchQueue.main.async {
                self.resultPreviewView.image = self.currentTargetImage
                
                UIView.transition(with: self.view, duration: 0.3, options: [.transitionCrossDissolve], animations: {
                    if let _ = self.currentTargetImage {
                        self.cameraView.stopSession()
                        
                        self.view.addSubview(self.resultPreviewView)
                        self.resultPreviewView.fitConstraints(to: self.view)
                        self.resultPreviewView.delegate = self
                    }
                    else {
                        self.cameraView.startSession()
                        self.resultPreviewView.removeFromSuperview()
                        self.resultPreviewView.delegate = nil
                    }
                }) { (completed) in
                    
                }
            }
        }
    }
    
    private var needsCaptureImage = false
    private func setNeedsCaptureImage() {
        needsCaptureImage = true
    }
    
    @objc private func cameraViewDidTap(sender: UITapGestureRecognizer) {
        UIFeedback.impact(.medium)
        
        if let _ = currentTargetImage {
            currentTargetImage = nil
        }
        else {
            setNeedsCaptureImage()
        }
    }
    
    private func detect(with image: UIImage?) {
        currentTargetImage = image
        
        if let image = image {
            let async = AsyncSignal()
            if let results = detector.detectResult(image: image, async) {
                resultPreviewView.reloadResults(results)
            }
        }
    }
}

extension MemoCamAppDockContent: ResultPreviewViewDelegate {
    func resultPreviewView(_ view: ResultPreviewView, didSelectItemWith visionText: VisionText) {

        guard let image = currentTargetImage else{
            return
        }

        DispatchQueue.global(qos: .userInteractive).async{
            let asyncSignal = AsyncSignal()

            if let results = self.detector.detectResult(image: image, asyncSignal) {

                if let resultMessage = [results].handleAsAction(true, asyncSignal){

                    asyncSignal.begin()
                    DispatchQueue.main.async {
                        UIAlertController.alert(resultMessage, completion:{ _ in
                            asyncSignal.end()
                        })
                    }
                    asyncSignal.waitUntilEnd()
                }

            }
        }

    }
}

import ARKit

class AppUIARView: UIView {
    fileprivate lazy var previewView: ARSCNView = {
        let view = ARSCNView(frame: .zero, options: nil)
        return view
    }()
    
    private lazy var renderer: SCNRenderer = SCNRenderer(device: nil, options: nil)
    private lazy var renderQueue = DispatchQueue(label: "com.stells.internal."+#file, qos: .utility)
    
    private(set) lazy var deviceMotion = UIDeviceMotion()
    
    var updateRenderer: ((_ renderer: SCNRenderer, _ frame: ARFrame) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private lazy var orientationTrackingConfiguration: AROrientationTrackingConfiguration = {
        let configuration = AROrientationTrackingConfiguration()
        if #available(iOS 11.3, *) {
            configuration.isAutoFocusEnabled = true
        }
        return configuration
    }()
    
    private lazy var worldTrackingConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        
        if #available(iOS 11.3, *) {
            configuration.isAutoFocusEnabled = true
            configuration.planeDetection = [.horizontal, .vertical]
        }
        else {
            configuration.planeDetection = .horizontal
        }
        
        return configuration
    }()
    
    var scene: SCNScene {
        return previewView.scene
    }
    
    private func initialize() {
        addSubview(previewView)
        previewView.fitConstraints(to: self)
        
        previewView.automaticallyUpdatesLighting = true
        previewView.autoenablesDefaultLighting = true
        
        #if DEBUG
        previewView.showsStatistics = true
//        previewView.debugOptions = [ARSCNDebugOptions.showFeaturePoints/*, ARSCNDebugOptions.showWorldOrigin*/]
        #endif
        
        renderer.autoenablesDefaultLighting = true
        renderer.scene = scene
    }
    
    var previewSize: CGSize {
        return previewView.bounds.size
    }
}

extension AppUIARView {
    func startSession() {
        deviceMotion.startUpdates(interval: 0.6)
        
        previewView.session.delegateQueue = renderQueue
        previewView.session.delegate = self
        previewView.session.run(orientationTrackingConfiguration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func stopSession() {
        deviceMotion.stopUpdates()
        
        previewView.session.delegate = nil
        previewView.session.pause()
    }
}

extension AppUIARView: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        updateRenderer?(renderer, frame)
    }
}

extension AppUIARView {
    func hitTest(at location: CGPoint, types: ARHitTestResult.ResultType? = nil) -> ARHitTestResult? {
        if #available(iOS 11.3, *) {
            return previewView.hitTest(location, types: types ?? [.existingPlaneUsingGeometry, .featurePoint]).first
        }
        else {
            return previewView.hitTest(location, types: types ?? [.existingPlaneUsingExtent, .featurePoint]).first
        }
    }
    
    func node(at location: CGPoint) -> SCNNode? {
        let hitTestResults = previewView.hitTest(location)
        return hitTestResults.first?.node
    }
    
    func convertPointToWorld(_ location: CGPoint) -> float3? {
        return worldTransform(location)?.translation
    }
    
    func anchorTransform(_ location: CGPoint) -> matrix_float4x4? {
        guard let hitTestResult = previewView.hitTest(location, types: .existingPlane).first else { return nil }
        return hitTestResult.anchor?.transform
    }
    
    func worldTransform(_ location: CGPoint) -> matrix_float4x4? {
        guard let hitTestResult = previewView.hitTest(location, types: .featurePoint).first else { return nil }
        return hitTestResult.worldTransform
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}
