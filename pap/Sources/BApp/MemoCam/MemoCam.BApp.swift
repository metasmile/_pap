//
//  MemoCam.BApp.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 7. 17..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import DefaultsKit
import Vision

private class _MemoCamAppTask: AppTaskPrototype, AppTaskable {
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){}
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        return nil
    }
}

class MemoCamApp: NSObject, KeyPathWatchable, BApp, LaunchableApp, AppDockApp, PhotoPickerCollectionViewDisplayableApp {
    class var isSupported: Bool {
        return ARConfiguration.isSupported
    }
    
    static var taskType: AppTaskable.Type = _MemoCamAppTask.self
    static var paramType: AppTaskParamable.Type = PHAssetItem<ImageEditStateValue>.self
    
    public private(set) lazy var dockContent: AppDockContent? = MemoCamAppDockContent()
    
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
    
    fileprivate var importedLaunchOption: AppLaunchOption? = nil
    
    func didLaunch(previous: App.Type?, withOption: AppLaunchOption?) {
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

fileprivate class MemoCamAppDockContent: NSObject, KeyPathWatchable, AppDockContent, AppDockDelegate {
    lazy var view: UIView = {
        let arView = AppUIARView(frame: .zero)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.arViewDidTap))
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }()
    
    private var arView: AppUIARView {
        return view as! AppUIARView
    }
    
    private var detector = MemoCamAppDetector()
    
    var preferences: AppDockContentPreferable? {
        let pref = AppDockContentPreferences()
        return pref
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        
    }
    
    func didSetContentView(_ view: UIView, dock: AppDock) {
        let targetSize = arView.previewSize
        
        let debugLayer = CAShapeLayer()
        debugLayer.frame = arView.previewView.bounds
        debugLayer.fillColor = UIColor.clear.cgColor
        debugLayer.strokeColor = UIColor.red.cgColor
        debugLayer.lineWidth = 1
        debugLayer.actions = ["path": NSNull()]
        arView.previewView.layer.addSublayer(debugLayer)
        
        arView.startSession()
        arView.updateRenderer = { renderer, frame in
            autoreleasepool {
                let image = renderer.snapshot(atTime: frame.timestamp, with: targetSize, antialiasingMode: .none)
                
                guard let result = self.detector.detectResult(image: image, AsyncSignal()) else { return }
                
                let path = UIBezierPath()
                
                result.sourceVisionTexts?.forEach {
                    let bounds = $0.frame
                    let normalizedBounds = bounds.normalized(by: image.size)
                    
                    guard normalizedBounds.width * normalizedBounds.height > 0.01 else { return }
                    
                    path.append(UIBezierPath(rect: bounds))
                    
//                    self.addPlane(normalizedBounds, at: CGPoint(x: bounds.midX, y: bounds.midY))
                }
                
                DispatchQueue.main.async {
                    debugLayer.path = path.cgPath
                }
                
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
        arView.scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }
    }
    
    func addLabel(_ rect: CGRect, text: String, at location: CGPoint) {
        guard let hitTestResult = arView.hitTest(at: location) else { return }
        
        let textGeometry = SCNText(string: text, extrusionDepth: 2.0)
        textGeometry.firstMaterial = SCNMaterial()
        textGeometry.firstMaterial?.diffuse.contents = UIColor.black
        textGeometry.firstMaterial?.specular.contents = UIColor.white
        textGeometry.font = UIFont.systemFont(ofSize: 0.5)
        
        let node = SCNNode(geometry: textGeometry)
        
        position(node: node, atHit: hitTestResult)
        
        arView.scene.rootNode.addChildNode(node)
    }
    
    func addPlane(_ rect: CGRect, at location: CGPoint) {
        guard let hitTestResult = arView.hitTest(at: location) else { return }
        
        let plane = SCNPlane(width: rect.width / 50, height: rect.height / 50)
        let node = SCNNode(geometry: plane)
        
        position(node: node, atHit: hitTestResult)
        
        arView.scene.rootNode.addChildNode(node)
    }
    
    private func position(node: SCNNode, atHit hit: ARHitTestResult) {
        guard let geometry = node.geometry else { return }
        
        if let anchor = hit.anchor {
            node.transform = SCNMatrix4(anchor.transform)
        }
        
        node.eulerAngles.x = (Float.pi / 2)
        
        let position = SCNVector3Make(hit.worldTransform.columns.3.x + geometry.boundingBox.min.z, hit.worldTransform.columns.3.y, hit.worldTransform.columns.3.z)
        
        node.position = position
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
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        previewView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 16 / 9).isActive = true
        previewView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        previewView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        previewView.automaticallyUpdatesLighting = true
        previewView.autoenablesDefaultLighting = true
        
        previewView.showsStatistics = true
        previewView.debugOptions = [ARSCNDebugOptions.showFeaturePoints/*, ARSCNDebugOptions.showWorldOrigin*/]
        
        renderer.autoenablesDefaultLighting = true
        renderer.scene = scene
    }
    
    var previewSize: CGSize {
        return previewView.bounds.size
    }
}

extension AppUIARView {
    func startSession() {
        previewView.session.delegateQueue = renderQueue
        previewView.session.delegate = self
        previewView.session.run(worldTrackingConfiguration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func stopSession() {
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
    func hitTest(at location: CGPoint) -> ARHitTestResult? {
        if #available(iOS 11.3, *) {
            return previewView.hitTest(location, types: [.existingPlaneUsingGeometry, .featurePoint]).first
        }
        else {
            return previewView.hitTest(location, types: [.existingPlaneUsingExtent, .featurePoint]).first
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
