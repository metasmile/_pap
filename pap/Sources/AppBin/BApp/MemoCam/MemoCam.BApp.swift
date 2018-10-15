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
import AVFoundation

private class _MemoCamAppTask: AppTaskPrototype, AppTaskable {
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){}
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        return nil
    }
}

class MemoCamApp: NSObject, PropertyWatchable, BApp, LaunchableApp, AppDockApp, PhotoPickerCollectionViewDelegatableApp, AVCaptureDeviceApp {
    static var taskType: AppTaskable.Type = _MemoCamAppTask.self
    static var paramType: AppTaskParamable.Type = AppAsset.self
    
    public private(set) lazy var content: AppDockContent? = MemoCamAppDockContent()
    public private(set) static var fixedContentLayout: Bool = true
    
    public static let info = AppInfo(
        identifier: "com.stells.pap.memocam"
        , version: "1.0"
        , phase: .release
        , appType: MemoCamApp.self
        , displayName: "Memo Cam".localized.localizedCapitalized, description:nil, keywords:nil
        , iconBundleName: R.image.memoCamBAppEmbossIcon.name
            , themeColor: UIColor(red:1, green:0.99, blue:0.22, alpha:1), embossIconBundleName: R.image.memoCamBAppEmbossIcon.name        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    public required override init() {}
    
    func shouldSelect(item: AppAsset) -> Bool {
        return false
    }
    
    fileprivate var importedLaunchOption: AppLaunchOptions? = nil
    
    func didLaunch(previous: App.Type?, withOption: AppLaunchOptions?) {
        importedLaunchOption = withOption
    }

    func didResign(current: App.Type?) {

    }
}

extension VisionTextResultGroup {
    static func createResultGroup(with visionTexts: [VisionText], _ async: AsyncWaitSignalable) -> VisionTextResultGroup {
        var resultGroup = VisionTextResultGroup()
        
        let emails = visionTexts.parse(type: VisionTextEmailAddressParser.self, async) ?? []
        let phoneNumbers = visionTexts.parse(type: VisionTextPhoneNumberParser.self, async) ?? []
        let urls = visionTexts.parse(type: VisionTextURLParser.self, async)?.compactMap { $0.compactMap { $0.scheme == "mailto" ? nil : $0 }.nilEmpty } ?? []
        let addresses = visionTexts.parse(type: VisionTextAddressParser.self, async) ?? []
        let flights = visionTexts.parse(type: VisionTextFlightNumberParser.self, async) ?? []
        let dates = visionTexts.parse(type: VisionTextDateParser.self, async) ?? []
        
        let barcodes = visionTexts.compactMap({ ($0 as? VisionBarcodeText)?.visionBarcode })
        resultGroup.barcodes = !barcodes.isEmpty ? barcodes : nil
        
        resultGroup.emails = !emails.isEmpty ? emails : nil
        resultGroup.phoneNumbers = !phoneNumbers.isEmpty ? phoneNumbers : nil
        resultGroup.urls = !urls.isEmpty ? urls : nil
        resultGroup.addresses = !addresses.isEmpty ? addresses : nil
        resultGroup.flights = !flights.isEmpty ? flights : nil
        resultGroup.dates = !dates.isEmpty ? dates : nil
        
        return resultGroup
    }
}

import FirebaseMLVision

private struct MemoCamAppDetector {
    private let vision = Vision.vision()
    private var textDetector: VisionTextDetector
    private var barcodeDetector: VisionBarcodeDetector

    init() {
        textDetector = vision.textDetector()
        barcodeDetector = vision.barcodeDetector()
    }

    fileprivate mutating func detectResult(image: UIImage, _ async: AsyncWaitSignalable) -> VisionTextImageDetectResult? {
        guard var visionTexts = self.textDetector.detect(with: image, async) else {
            return nil
        }

        var result = VisionTextImageDetectResult(image: image)
        
        if let barcodes = self.barcodeDetector.detect(with: image, async) {
            visionTexts.append(contentsOf: barcodes)
        }
        
        result.sourceVisionTexts = visionTexts
        result.resultGroup = VisionTextResultGroup.createResultGroup(with: visionTexts, async)

        return result
    }
}

private class BadgeIconLayer: ResultItemLayer {
    lazy var badgeLayer = CAShapeLayer()
    lazy var badgeIconLayer = CALayer()
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    override init() {
        super.init()
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func initialize() {
        super.initialize()
        
        addSublayer(badgeLayer)
        badgeLayer.frame.size = CGSize(width: badgeSize, height: badgeSize)
        badgeLayer.path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: badgeLayer.frame.size)).cgPath
        badgeLayer.fillColor = UIColor.white.cgColor
        badgeLayer.isHidden = true
        badgeLayer.opacity = 0.9
        badgeLayer.addSublayer(badgeIconLayer)
        
        badgeIconLayer.contentsGravity = CALayerContentsGravity.resizeAspectFill
        badgeIconLayer.cornerRadius = (badgeSize * 0.8) / 2
        badgeIconLayer.masksToBounds = true
        badgeIconLayer.frame.size = CGSize(width: badgeSize * 0.8, height: badgeSize * 0.8)
    }
    
    let badgeSize: CGFloat = 24
    
    func showBadgeIcon(with quad: CGQuad, in bounds: CGRect) {
        let point = quad.topLeft.applying(previewTransform)
        
        badgeLayer.isHidden = false
        badgeLayer.position = CGPoint(x: (point.x - badgeSize * 0.35).clamped(to: bounds.origin.x + badgeSize / 2 ... bounds.width - badgeSize / 2), y: (point.y - badgeSize * 0.35).clamped(to: bounds.origin.y + badgeSize / 2 ... bounds.height - badgeSize / 2))
        
        badgeIconLayer.contents = (result?.preferredParserIcon() ?? R.image.appActionIconEmbossText())?.cgImage
        badgeIconLayer.position = CGPoint(x: badgeLayer.bounds.midX, y: badgeLayer.bounds.midY)
    }
}

private class ResultItemLayer: CAShapeLayer {
    var result: ResultPreviewItem?
    
    var previewTransform: CGAffineTransform = .identity
    var tintColor: UIColor?
    
    var hitTestPath: UIBezierPath?
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    override init() {
        super.init()
        
        initialize()
    }
    
    var highlighted: Bool = false {
        didSet {
            fillColor = highlighted ? UIColor(white: 1, alpha: 0.7).cgColor : UIColor.clear.cgColor
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initialize() {
        strokeColor = UIColor.white.cgColor
        fillColor = UIColor.clear.cgColor
        lineWidth = 1
        shadowOpacity = 0.5
        shadowColor = UIColor.black.cgColor
        shadowOffset = .zero
        shadowRadius = 2
    }
}

fileprivate protocol ResultPreviewViewDelegate {
    func resultPreviewView(_ view: ResultPreviewView, didSelectItemWith resultPreviewItem: ResultPreviewItem)
}

fileprivate struct ResultPreviewItem {
    var visionText: VisionText
    var resultGroup: VisionTextResultGroup
    
    init(visionText: VisionText, resultGroup: VisionTextResultGroup) {
        self.visionText = visionText
        self.resultGroup = resultGroup
    }
    
    var quad: CGQuad {
        return CGQuad(visionText.cornerPoints.map { $0.cgPointValue })
    }

    func preferredParserIcon() -> UIImage? {
        guard resultGroup.isFilled else {
            return nil
        }

        if resultGroup.phoneNumbers?.count ?? 0 > 0 || resultGroup.barcodes?.contains(where: { $0.valueType == .phone }) == true {
            return R.image.appActionIconEmbossPhoneCall()
        } else if resultGroup.emails?.count ?? 0 > 0 || resultGroup.barcodes?.contains(where: { $0.valueType == .email }) == true {
            return R.image.appActionIconEmail()
        } else if resultGroup.addresses?.count ?? 0 > 0 || resultGroup.barcodes?.contains(where: { $0.valueType == .geographicCoordinates }) == true {
            return R.image.appActionIconLocation()
        } else if resultGroup.barcodes?.contains(where: { $0.valueType == .contactInfo }) == true {
            return R.image.appActionIconContact()
        } else if resultGroup.dates?.count ?? 0 > 0 || resultGroup.barcodes?.contains(where: { $0.valueType == .calendarEvent }) == true {
            return R.image.appActionIconEmbossDate()
        } else if resultGroup.urls?.count ?? 0 > 0 || resultGroup.barcodes?.contains(where: { $0.valueType == .URL || $0.valueType == .ISBN || $0.valueType == .product || $0.format != .qrCode }) == true {
            return R.image.appActionIconEmbossURL()
        } else if resultGroup.flights?.count ?? 0 > 0 {
            return R.image.appActionIconEmbossFlight()
        }

        return nil
    }
}

fileprivate class ResultPreviewView: DesignableView {
    lazy var imageView: UIImageView = UIImageView(frame: .zero)
    var delegate: ResultPreviewViewDelegate?
    
    var showsPlainText: Bool = false
    
    override func initialize() {
        super.initialize()
        
        addSubview(imageView)
        imageView.fitConstraints(to: self)
        imageView.contentMode = .scaleAspectFill
        
        layer.addSublayer(dimmedLayer)
        layer.addSublayer(resultsLayer)
        layer.addSublayer(resultsUILayer)
        
        dimmedLayer.fillRule = .evenOdd
        dimmedLayer.fillColor = UIColor(white: 0, alpha: 0.6).cgColor
    }
    
    private lazy var dimmedLayer = CAShapeLayer()
    private lazy var dimmedPath = UIBezierPath()
    
    lazy var resultsUILayer: CALayer = {
        let layer = CALayer()
        layer.rasterizationScale = UIScreen.main.scale
        layer.shouldRasterize = true
        layer.drawsAsynchronously = true
        return layer
    }()
    
    lazy var resultsLayer: CALayer = {
        let layer = CALayer()
        layer.rasterizationScale = UIScreen.main.scale
        layer.shouldRasterize = true
        layer.drawsAsynchronously = true
        return layer
    }()
    
    var image: UIImage? {
        set {
            imageView.image = newValue
            
            if let _ = newValue {
                
            }
            else {
                resultsLayer.sublayers = nil
                resultsUILayer.sublayers = nil
                
                dimmedPath.removeAllPoints()
                dimmedLayer.path = nil
            }
        }
        
        get {
            return imageView.image
        }
    }
    
    private var resultPreviewItems = [ResultPreviewItem]()
    
    private(set) var detectResult: VisionTextImageDetectResult?
    
    func reloadResults(_ result: VisionTextImageDetectResult) {
        self.detectResult = result
        
        let async = AsyncSignal()
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.resultPreviewItems.removeAll()
            
            for visionText in result.sourceVisionTexts ?? [] {
                let resultGroup = VisionTextResultGroup.createResultGroup(with: [visionText], async)
                
                guard self.showsPlainText || resultGroup.isFilled else { continue }
                self.resultPreviewItems.append(ResultPreviewItem(visionText: visionText, resultGroup: resultGroup))
            }
            
            DispatchQueue.main.async {
                let disableActions = CATransaction.disableActions()
                CATransaction.setDisableActions(true)
                self.resultsLayer.sublayers = nil
                self.resultsUILayer.sublayers = nil
                
                let previewSize = result.image.size.aspectFill(in: self.bounds.size)
                self.resultsLayer.frame = CGRect(origin: CGPoint(x: (self.bounds.width - previewSize.width) / 2, y: (self.bounds.height - previewSize.height) / 2), size: previewSize)
                
                self.dimmedLayer.frame = self.resultsLayer.frame
                self.resultsUILayer.frame = self.resultsLayer.frame
                
                self.dimmedPath.removeAllPoints()
                self.dimmedLayer.path = nil
                
                self.dimmedPath.append(UIBezierPath(rect: self.dimmedLayer.bounds))
                
                for item in self.resultPreviewItems {
                    self.drawResult(item, in: result.image.size)
                }
                
                self.dimmedLayer.path = self.dimmedPath.cgPath
                self.dimmedLayer.opacity = 0
                
                CATransaction.setDisableActions(disableActions)
                
                self.dimmedLayer.opacity = 1
            }
        }
    }
    
    private func drawResult(_ resultPreviewItem: ResultPreviewItem, in size: CGSize) {
        let path = UIBezierPath()
        
        let renderScaleTransform = CGAffineTransform(scaleX: resultsLayer.frame.width / size.width, y: resultsLayer.frame.height / size.height)
        
        let padding: CGFloat = 12
        let quad = resultPreviewItem.quad.inset(by: UIEdgeInsets(top: -padding, left: -padding, bottom: -padding, right: -padding))
        
        path.move(to: quad.topLeft)
        path.addLine(to: quad.topRight)
        path.addLine(to: quad.bottomRight)
        path.addLine(to: quad.bottomLeft)
        path.apply(renderScaleTransform)
        path.close()
        
        self.dimmedPath.append(path)
        
        let layer = ResultItemLayer()
        layer.tintColor = tintColor
        layer.result = resultPreviewItem
        layer.previewTransform = renderScaleTransform
        layer.lineWidth = 1 / max(renderScaleTransform.scaleX, renderScaleTransform.scaleY)
        layer.hitTestPath = path
        layer.path = UIBezierPath(roundedRect: quad.boundingRect, cornerRadius: padding).cgPath
        layer.transform = CATransform3DConcat(CATransform3D(from: quad.boundingRect, to: quad), CATransform3DMakeAffineTransform(renderScaleTransform))
        
        let iconLayer = BadgeIconLayer()
        iconLayer.tintColor = tintColor
        iconLayer.result = resultPreviewItem
        iconLayer.previewTransform = renderScaleTransform
        iconLayer.showBadgeIcon(with: resultPreviewItem.quad, in: CGRect(origin: CGPoint(x: (resultsLayer.bounds.width - bounds.width) / 2, y: (resultsLayer.bounds.height - bounds.height) / 2), size: size))
        
        resultsLayer.addSublayer(layer)
        resultsUILayer.addSublayer(iconLayer)
    }
    
    private var currentHitLayer: ResultItemLayer?
    private func resultItemLayer(at point: CGPoint) -> ResultItemLayer? {
        let layerLocation = layer.convert(point, to: resultsLayer)
        for layer in resultsLayer.sublayers?.compactMap({ $0 as? ResultItemLayer }) ?? [] {
            if layer.hitTestPath?.contains(layerLocation) == true {
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
        
        if let item = currentHitLayer?.result {
            delegate?.resultPreviewView(self, didSelectItemWith: item)
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
    fileprivate lazy var cameraView: CameraView = {
        let cameraView = CameraView(frame: .zero)
        cameraView.clipsToBounds = false
        cameraView.contentMode = .scaleAspectFill
        cameraView.setUp()
        return cameraView
    }()
    
    fileprivate lazy var contentView: UIView = {
        let view = UIView(frame: .zero)
        view.clipsToBounds = false
        return view
    }()
    
    lazy var view: UIView = {
        let view = UIView(frame: .zero)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.cameraViewDidTap))
        cameraView.addGestureRecognizer(tapGesture)
        
        view.addSubview(contentView)
        view.addSubview(toolBar)
        
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        toolBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        toolBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        toolBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: toolBar.topAnchor).isActive = true
        
        contentView.addSubview(cameraView)
        cameraView.fitConstraints(to: contentView)
        
        cameraView.capturePreset = .high
        
        return view
    }()
    
    fileprivate lazy var resultPreviewView: ResultPreviewView = {
        let view = ResultPreviewView(frame: .zero)
        return view
    }()
    
    fileprivate lazy var toolBar: UIToolbar = {
        let toolBar = UIToolbar(frame: .zero)
        return toolBar
    }()
    
    internal class DisableImplicitAnimatableShapeLayer: CAShapeLayer {
        override func action(forKey event: String) -> CAAction? {
            switch event {
            case "position", "onOrderIn", "onOrderOut", "path": return NSNull()
            default: return super.action(forKey: event)
            }
        }
    }
    
    private func createDebugLayer() -> DisableImplicitAnimatableShapeLayer {
        let layer = DisableImplicitAnimatableShapeLayer()
        layer.drawsAsynchronously = true
        
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.cgColor
        layer.lineWidth = 1
        
        return layer
    }
    
    fileprivate func drawPolygons(with quads: [CGQuad], to layer: CAShapeLayer, in previewSize: CGSize? = nil) {
        let disabledActions = CATransaction.disableActions()
        CATransaction.setDisableActions(true)
        
        let path = UIBezierPath()
        
        for quad in quads {
            let polygon = UIBezierPath()
            polygon.move(to: quad.topLeft)
            polygon.addLine(to: quad.topRight)
            polygon.addLine(to: quad.bottomRight)
            polygon.addLine(to: quad.bottomLeft)
            polygon.close()
            
            path.append(polygon)
        }
        
        if let previewSize = previewSize {
            let transform = CGAffineTransform.identity
                .scaledBy(x: 1, y: -1)
                .translatedBy(x: 0, y: -previewSize.height)
                .scaledBy(x: previewSize.width, y: previewSize.height)
            
            path.apply(transform)
            
            layer.path = path.cgPath
            layer.frame = CGRect(origin: CGPoint(x: (self.cameraView.bounds.width - previewSize.width) / 2, y: (self.cameraView.bounds.height - previewSize.height) / 2), size: previewSize)
        }
        else {
            layer.path = path.cgPath
            layer.frame = self.cameraView.bounds
        }
        
        CATransaction.setDisableActions(disabledActions)
        CATransaction.commit()
    }
    
    fileprivate func drawPolygons(with observations: [VNRectangleObservation], to layer: CAShapeLayer) {
        drawPolygons(with: observations.map { CGQuad($0.topLeft, $0.topRight, $0.bottomRight, $0.bottomLeft) }, to: layer, in: self.cameraView.captureVideoSize.aspectFill(in: self.cameraView.bounds.size))
    }
    
    fileprivate func drawPolygons(with codeObjects: [AVMetadataMachineReadableCodeObject], to layer: CAShapeLayer) {
        let padding: CGFloat = 4
        drawPolygons(with: codeObjects.map { CGQuad($0.corners, clockwised: false).inset(by: UIEdgeInsets(top: -padding, left: -padding, bottom: -padding, right: -padding)) }, to: layer)
    }
    
    private lazy var detector = MemoCamAppDetector()
    
    var preferences: AppDockContentPreferable? {
        var pref = AppDockContentPreferences()
        pref.preferredHeight = AppDockContentPreferences.GreatestHeight
        return pref
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        
    }
    
    func didSetContentView(_ view: UIView, dock: AppDock) {
        cameraView.layer.sublayers?.forEach {
            if $0 is DisableImplicitAnimatableShapeLayer {
                $0.removeFromSuperlayer()
            }
        }
        
        self.currentTargetImage = nil
        updateToolBar()
        
        toolBar.tintColor = view.colorTheme.tintColor
        
        let detectTextLayer = createDebugLayer()
        let detectBarcodesLayer = createDebugLayer()
        
        cameraView.layer.addSublayer(detectTextLayer)
        cameraView.layer.addSublayer(detectBarcodesLayer)
        
        let detectTextRequest = VNDetectTextRectanglesRequest { (request, error) in
            guard let observations = request.results as? [VNTextObservation] else { return }
            
            DispatchQueue.main.async {
                self.drawPolygons(with: observations, to: detectTextLayer)
            }
        }
        
        cameraView.captureVideoDataDidOutput = { sampleBuffer in
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
            if let cameraIntrinsicMatrix = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
                options[VNImageOption.cameraIntrinsics] = cameraIntrinsicMatrix
            }
            
            try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: UInt32(deviceOrientation.exifOrientation(frontFacing: false).rawValue)) ?? .rightMirrored, options: options).perform([detectTextRequest])
        }
        cameraView.setMetadataOutput { (metadataObjects) in
            DispatchQueue.main.async {
                self.drawPolygons(with: metadataObjects as? [AVMetadataMachineReadableCodeObject] ?? [], to: detectBarcodesLayer)
            }
        }
        cameraView.startSession()
    }
    
    func willRemoveContentView() {
        cameraView.captureVideoDataDidOutput = nil
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
                
                UIView.transition(with: self.contentView, duration: 0.3, options: [.transitionCrossDissolve], animations: {
                    if let _ = self.currentTargetImage {
                        self.cameraView.stopSession()
                        
                        self.contentView.addSubview(self.resultPreviewView)
                        self.resultPreviewView.fitConstraints(to: self.contentView)
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
    
    private lazy var switchShowAllTexts: UISwitch = {
        let view = UISwitch(frame: .zero)
        view.sizeToFit()
        view.addTarget(self, action: #selector(self.toggleResultPreviewMode), for: .valueChanged)
        return view
    }()
    
    private func updateToolBar() {
        if let _ = self.currentTargetImage {
            toolBar.setItems([
                UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.cancelButtonDidTap)),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(title: "Show All Texts".localized, style: .plain, target: self, action: #selector(self.toggleResultPreviewModeSwitch)),
                UIBarButtonItem(customView: switchShowAllTexts),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.actionButtonDidTap)),
//                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
//                UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.savePhoto))
                ], animated: true)
        }
        else {
            toolBar.setItems([
                UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(title: "Tap To Detect".localized, style: .plain, target: self, action: #selector(self.cameraViewDidTap)),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(image: R.image.commonCellIconInfo(), style: .plain, target: self, action: #selector(self.selectLanguageOption))
            ], animated: true)
        }
    }
    
    private var needsCaptureImage = false
    private func setNeedsCaptureImage() {
        needsCaptureImage = true
    }
    
    @objc private func cameraViewDidTap(sender: Any) {
        if let _ = currentTargetImage {
            UIFeedback.select()
            actionButtonDidTap()
        }
        else {
            let loadingView = UIActivityIndicatorView(style: .gray)
            loadingView.startAnimating()
            
            toolBar.setItems([
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(customView: loadingView),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            ], animated: true)
            
            UIFeedback.impact(.light)
            setNeedsCaptureImage()
        }
    }
    
    @objc private func cancelButtonDidTap(sender: Any) {
        UIFeedback.impact(.medium)
        
        if let _ = currentTargetImage {
            currentTargetImage = nil
        }
        
        updateToolBar()
    }
    
    @objc private func toggleResultPreviewMode(sender: UISwitch) {
        resultPreviewView.showsPlainText = sender.isOn
        if let results = self.resultPreviewView.detectResult {
            resultPreviewView.reloadResults(results)
        }
    }
    
    @objc private func toggleResultPreviewModeSwitch(sender: UIBarButtonItem) {
        switchShowAllTexts.setOn(!switchShowAllTexts.isOn, animated: true)
        toggleResultPreviewMode(sender: switchShowAllTexts)
    }
    
    @objc private func selectLanguageOption(sender: Any) {
        let alert = UIAlertController.alert(title: MemoCamApp.info.displayName, message: "Currently, our AI text recognition model is only available for Alphanumeric and some special characters, and it could be affected by the current system language.".localized)
        alert.addAction(UIAlertAction(title: "OK".localized, style: .cancel, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        }))
        UIViewController.present(alert, animated: true)
    }
    
    private func detect(with image: UIImage?) {
        currentTargetImage = image
        
        if let image = image {
            DispatchQueue.global(qos: .userInteractive).async{
                let async = AsyncSignal()
                if let results = self.detector.detectResult(image: image, async) {
                    self.resultPreviewView.reloadResults(results)
                }
                
                DispatchQueue.main.async {
                    self.updateToolBar()
                    
                    self.cameraView.layer.sublayers?.forEach { ($0 as? DisableImplicitAnimatableShapeLayer)?.path = nil }
                }
            }
        }
    }
}

extension MemoCamAppDockContent: ResultPreviewViewDelegate {
    fileprivate func showActions(with results: [VisionTextImageDetectResult]) {
        let quickMode = self.switchShowAllTexts.isOn == false
        
        DispatchQueue.global(qos: .userInteractive).async{
            let asyncSignal = AsyncSignal()
            
            var previewTexts:String?
            if !quickMode{
                previewTexts = results.compactMap{ $0.plainText }.joined().trimmed.nilEmpty
            }

            if let resultMessage = results.handleAsAction(quickMode, message: previewTexts, asyncSignal){
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
    
    @objc fileprivate func actionButtonDidTap() {
        if var results = self.resultPreviewView.detectResult {
            if resultPreviewView.showsPlainText {
                results.plainText = results.sourceVisionTexts?.parse(type: VisionTextStringParser.self, AsyncSignal())?.joined()
            }
            self.showActions(with: [results])
        }
    }
    
    func resultPreviewView(_ view: ResultPreviewView, didSelectItemWith resultPreviewItem: ResultPreviewItem) {
        guard let image = currentTargetImage else { return }
        
        var result = VisionTextImageDetectResult(image: image)
        result.sourceVisionTexts = [resultPreviewItem.visionText]
        if view.showsPlainText {
            result.plainText = result.sourceVisionTexts?.parse(type: VisionTextStringParser.self, AsyncSignal())?.joined()
        }
        result.resultGroup = resultPreviewItem.resultGroup
        
        showActions(with: [result])
    }
}

/*
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
*/
