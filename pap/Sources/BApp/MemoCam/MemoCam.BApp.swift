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
    
    fileprivate func detectResult(image: UIImage, _ async: AsyncWaitSignalable) -> MemoCamAppResult? {
        guard let visionTexts = vision.textDetector().detect(with: image, async) else {
            return nil
        }
        
        var result = MemoCamAppResult(image: image)
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
    
    private var arView: AppUIARView? {
        return view as? AppUIARView
    }
    
    private var detector = MemoCamAppDetector()
    
    var preferences: AppDockContentPreferable? {
        let pref = AppDockContentPreferences()
        return pref
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        
    }
    
    func didSetContentView(_ view: UIView, dock: AppDock) {
        let targetSize = view.bounds.size
        
        let request = VNDetectTextRectanglesRequest(completionHandler: { (request, error) in
            guard let observations = request.results as? [VNTextObservation], let rect = observations.first?.boundingBox else { return }

            let bounds = observations.map { $0.boundingBox }.reduce(rect, { $0.union($1) })

            self.addPlane(bounds, at: CGPoint(x: bounds.midX * targetSize.width, y: bounds.midY * targetSize.height))
        })
        
        arView?.startSession()
        arView?.updateRenderer = { renderer, frame in
//            let image = renderer.snapshot(atTime: frame.timestamp, with: targetSize, antialiasingMode: .none)
//            if let detectedResult = self.detector.detectResult(image: image, AsyncSignal()) {
//                guard let firstFrame = detectedResult.sourceVisionTexts?.first?.frame else { return }
//
//                guard let bounds = detectedResult.sourceVisionTexts?.map({ $0.frame }).reduce(firstFrame, { $0.union($1) }) else { return }
//
//                print(bounds)
//
////                self.addPlane(bounds, at: CGPoint(x: bounds.midX * targetSize.width, y: bounds.midY * targetSize.height))
//            }
            
            
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, options: [:])
            try? imageRequestHandler.perform([request])
        }
    }
    
    func willRemoveContentView() {
        arView?.updateRenderer = nil
        arView?.stopSession()
    }
    
    var delegate: AppDockDelegate? {
        return self
    }
    
    func dockWillExpand(_ dock: AppDock) {
        
    }
    
    func dockWillContract(_ dock: AppDock) {
        
    }
    
    @objc private func arViewDidTap(sender: UITapGestureRecognizer) {
        let location = sender.location(in: arView)
        if let node = arView?.node(at: location) {
            node.removeFromParentNode()
        }
        else if let worldTranslation = arView?.worldTranslation(at: location) {
            addBox(x: worldTranslation.x, y: worldTranslation.y, z: worldTranslation.z)
        }
    }
    
    func addPlane(_ rect: CGRect, at location: CGPoint) {
        guard let translation = arView?.worldTranslation(at: location), arView?.node(at: location) == nil else { return }
        
        print(rect.size)
        
        let plane = SCNPlane(width: rect.width / 50, height: rect.height / 50)
        
        let node = SCNNode(geometry: plane)
        node.position = SCNVector3(translation.x, translation.y, translation.z)
        node.eulerAngles.x = -.pi / 2
        
        arView?.scene.rootNode.addChildNode(node)
    }
    
    func addBox(x: Float = 0, y: Float = 0, z: Float = -0.2) {
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.position = SCNVector3(x, y, z)
        
        arView?.scene.rootNode.addChildNode(boxNode)
    }
}

import ARKit

class AppUIARView: UIView {
    private lazy var previewView: ARSCNView = {
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
        previewView.fitConstraints(to: self)
        
        previewView.automaticallyUpdatesLighting = true
        previewView.autoenablesDefaultLighting = true
        
        renderer.autoenablesDefaultLighting = true
        renderer.scene = scene
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
    func node(at location: CGPoint) -> SCNNode? {
        let hitTestResults = previewView.hitTest(location)
        return hitTestResults.first?.node
    }
    
    func worldTranslation(at location: CGPoint) -> float3? {
        guard let hitTestResultWithFeaturePoints = previewView.hitTest(location, types: .featurePoint).first else { return nil }
        return hitTestResultWithFeaturePoints.worldTransform.translation
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}
