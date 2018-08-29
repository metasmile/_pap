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
    class var isSupported: Bool {
        return ARConfiguration.isSupported
    }
    
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

private struct MemoCamAppResult: AppTaskResultable {
    fileprivate let image: UIImage
    
    init(image: UIImage){
        self.image = image
    }
    
    fileprivate var sourceVisionTexts:[VisionText]?
    
    fileprivate var plainText:String?
    
    fileprivate var contacts:[VisionTextContactParser.OutputType]?
    
    fileprivate var resultGroup: VisionTextResultGroup?
}


import FirebaseMLVision

private struct MemoCamAppDetector {
    private let vision = Vision.vision()
    private var textDetector: VisionTextDetector
    
    init() {
        textDetector = vision.textDetector()
    }
    
    fileprivate mutating func detectResult(image: UIImage, _ async: AsyncWaitSignalable) -> MemoCamAppResult? {
        guard let visionTexts = self.textDetector.detect(with: image, async) else {
            return nil
        }
        
        var result = MemoCamAppResult(image: image)
        result.sourceVisionTexts = visionTexts
        result.plainText = visionTexts.parse(type: VisionTextStringParser.self, async)?.joined()
        
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

fileprivate class MemoCamAppDockContent: NSObject, PropertyWatchable, AppDockContent, AppDockDelegate {
    lazy var view: UIView = {
        let arView = AppUIARView(frame: .zero)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.arViewDidTap))
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }()
    
    private var arView: AppUIARView {
        return view as! AppUIARView
    }
    
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
        
        arView.previewView.layer.addSublayer(debugLayer)
        
        var previewSize = self.arView.previewSize
        var aspectRatio = CGSize.zero
        
        let detectTextRequest = VNDetectTextRectanglesRequest { (request, error) in
            guard let observations = request.results as? [VNTextObservation] else { return }
            
            DispatchQueue.main.async {
                previewSize = aspectRatio.aspectFill(in: self.arView.previewSize)
                
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
                self.debugLayer.frame = CGRect(origin: CGPoint(x: (self.arView.previewSize.width - previewSize.width) / 2, y: (self.arView.previewSize.height - previewSize.height) / 2), size: previewSize)
            }
        }
        
        arView.startSession()
        arView.updateRenderer = { renderer, frame in
            autoreleasepool {
                switch frame.camera.trackingState {
                case .limited(let reason):
                    switch reason {
                    case .excessiveMotion:
                        print("TRACKING LIMITED - EXCESSIVE MOTION")
                    default: break
                    }
                    return
                case .normal: break
                default: return
                }
                
                let deviceOrientation = self.arView.deviceMotion.orientation
                if deviceOrientation.isPortrait {
                    aspectRatio = CGSize(width: frame.camera.imageResolution.height, height: frame.camera.imageResolution.width)
                }
                else {
                    aspectRatio = frame.camera.imageResolution
                }
                
                //STEP 1 - find text rectangle when stable movement
                
                let options = [VNImageOption.cameraIntrinsics: frame.camera.intrinsics]
                try? VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: CGImagePropertyOrientation(rawValue: UInt32(deviceOrientation.exifOrientation(frontFacing: false).rawValue)) ?? .rightMirrored, options: options).perform([detectTextRequest])
                
                //STEP 2 - find text 
                
                let image = renderer.snapshot(atTime: frame.timestamp, with: previewSize, antialiasingMode: .none)
                guard let result = self.detector.detectResult(image: image, AsyncSignal()) else { return }
                
                //STEP 3 - merge text with rect
                
//                result.sourceVisionTexts?.forEach {
//                    let bounds = $0.frame
//                    let normalizedBounds = bounds.normalized(by: image.size)
//
//                    let polygon = UIBezierPath()
//
//                    guard
//                        let firstPoint = $0.cornerPoints.first?.cgPointValue,
//                        normalizedBounds.width * normalizedBounds.height > 0.01
//                    else { return }
//
//                    polygon.move(to: firstPoint)
//                    $0.cornerPoints[1...].forEach {
//                        polygon.addLine(to: $0.cgPointValue)
//                    }
//                    polygon.close()
//                }
            }
        }
    }
    
    func willRemoveContentView() {
        arView.updateRenderer = nil
        arView.stopSession()
    }
    
    var delegate: AppDockDelegate? {
        return self
    }
    
    func dockWillExpand(_ dock: AppDock) {
        
    }
    
    func dockWillContract(_ dock: AppDock) {
        
    }
    
    @objc private func arViewDidTap(sender: UITapGestureRecognizer) {
        DispatchQueue(label: "nodeQueue", qos: .utility).async {
            self.arView.scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }
        }
    }
    
    func addPlane(_ rect: CGRect) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
//        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        
        guard
            let hitTestTopLeft = arView.hitTest(at: topLeft, types: .featurePoint),
            let hitTestTopRight = arView.hitTest(at: topRight, types: .featurePoint),
            let hitTestBottomLeft = arView.hitTest(at: bottomLeft, types: .featurePoint),
//            let hitTestBottomRight = arView.hitTest(at: bottomRight, types: .featurePoint),
            let hitTestCenter = arView.hitTest(at: center, types: .featurePoint)
        else { return }
        
        let plane = SCNPlane(width: CGFloat(hitTestTopLeft.worldTransform.translation.x.distance(to: hitTestTopRight.worldTransform.translation.x).magnitude), height: CGFloat(hitTestBottomLeft.worldTransform.translation.y.distance(to: hitTestTopLeft.worldTransform.translation.y)).magnitude)
        plane.firstMaterial?.diffuse.contents = UIColor.green
        
        let node = SCNNode(geometry: plane)
        
        if let anchor = arView.hitTest(at: center)?.anchor {
            node.transform = SCNMatrix4(anchor.transform)
            plane.firstMaterial?.diffuse.contents = UIColor.red
        }
        
        node.eulerAngles.x = -.pi / 2
        
        let position = SCNVector3Make(hitTestCenter.worldTransform.columns.3.x, hitTestCenter.worldTransform.columns.3.y, hitTestCenter.worldTransform.columns.3.z)
        node.position = position
        
        arView.scene.rootNode.addChildNode(node)
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
        previewView.session.run(worldTrackingConfiguration, options: [.resetTracking, .removeExistingAnchors])
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
