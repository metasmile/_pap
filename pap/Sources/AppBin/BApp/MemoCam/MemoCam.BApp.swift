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

class MemoCamApp: NSObject, PropertyWatchable, BApp, LaunchableApp, AppDockApp, PhotoPickerCollectionViewDelegatableApp, AVCaptureDeviceApp {
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
            , themeColor: nil
        , policy: AppPolicy.default
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
        
        var emails = visionTexts.parse(type: VisionTextEmailAddressParser.self, async) ?? []
        var phoneNumbers = visionTexts.parse(type: VisionTextPhoneNumberParser.self, async) ?? []
        var urls = visionTexts.parse(type: VisionTextURLParser.self, async)?.compactMap { $0.compactMap { $0.scheme == "mailto" ? nil : $0 }.nilEmpty } ?? []
        let addresses = visionTexts.parse(type: VisionTextAddressParser.self, async) ?? []
        let flights = visionTexts.parse(type: VisionTextFlightNumberParser.self, async) ?? []
        var dates = visionTexts.parse(type: VisionTextDateParser.self, async) ?? []
        
        let barcodes = visionTexts.compactMap({ ($0 as? VisionBarcodeText)?.visionBarcode })
        for barcode in barcodes {
            switch barcode.valueType {
            case .email:
                guard let email = barcode.email?.address else { break }
                emails.append([email])
            case .phone:
                guard let phone = barcode.phone?.number else { break }
                phoneNumbers.append([phone])
            case .URL:
                guard let urlString = barcode.url?.url ?? barcode.rawValue, let url = URL(string: urlString) else { break }
                urls.append([url])
            case .calendarEvent:
                guard let event = barcode.calendarEvent?.start else { break }
                dates.append([event])
//            case .product:
//                print("product", barcode.rawValue)
            case .ISBN:
                guard let isbn = barcode.rawValue, let url = URL(string: "https://isbnsearch.org/isbn/\(isbn)") else { break }
                urls.append([url])
//            case .contactInfo:
//                break
            default: break
            }
        }
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
        
        badgeIconLayer.contents = (result?.preferredParserIcon() ?? {
            return UIGraphicsImageRenderer(bounds: badgeLayer.bounds).imageWithCurrentContext { (cgContext) in
                cgContext.setFillColor(UIColor.clear.cgColor)
                cgContext.fill(self.badgeLayer.bounds)
                
                let attrString = NSAttributedString(string: "T", attributes: [
                    NSAttributedString.Key.foregroundColor: self.tintColor ?? UIColor.black
                ])
                let stringSize = attrString.size()
                
                attrString.draw(at: CGPoint(x: max(0, (self.badgeLayer.bounds.width - stringSize.width) / 2), y: max(0, (self.badgeLayer.bounds.height - stringSize.height) / 2)))
            }
            }())?.cgImage
        badgeIconLayer.position = CGPoint(x: badgeLayer.bounds.midX, y: badgeLayer.bounds.midY)
    }
}

private class ResultItemLayer: CAShapeLayer {
    var result: ResultPreviewItem?
    
    var previewTransform: CGAffineTransform = .identity
    var tintColor: UIColor?
    
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
        rasterizationScale = UIScreen.main.scale
        shouldRasterize = true
        drawsAsynchronously = true
        
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
        guard resultGroup.isFilled else { return nil }
        
        if resultGroup.phoneNumbers?.count ?? 0 > 0 { return R.image.ico_action_phonenumber() }
        else if resultGroup.emails?.count ?? 0 > 0 { return R.image.ico_action_email() }
        else if resultGroup.addresses?.count ?? 0 > 0 { return R.image.ico_action_address() }
        else if resultGroup.dates?.count ?? 0 > 0 { return R.image.ico_action_date() }
        else if resultGroup.urls?.count ?? 0 > 0 { return R.image.ico_action_url() }
        else if resultGroup.flights?.count ?? 0 > 0 { return R.image.ico_action_flightnumber() }
        
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
        
        dimmedPath.usesEvenOddFillRule = true
        
        dimmedLayer.fillRule = .evenOdd
        dimmedLayer.fillColor = UIColor(white: 0, alpha: 0.6).cgColor
    }
    
    private lazy var dimmedLayer = CAShapeLayer()
    private lazy var dimmedPath = UIBezierPath()
    
    lazy var resultsUILayer: CALayer = {
        let layer = CALayer()
        return layer
    }()
    
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
        
        let padding: CGFloat = 8
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
        layer.path = path.cgPath
        
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
        
        layer.rasterizationScale = UIScreen.main.scale
        layer.shouldRasterize = true
        layer.drawsAsynchronously = true
        
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.cgColor
        layer.lineWidth = 1
        
        return layer
    }
    
    private func drawPolygons(with observations: [VNRectangleObservation], to layer: CAShapeLayer) {
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
        
        layer.path = path.cgPath
        layer.frame = CGRect(origin: CGPoint(x: (self.cameraView.bounds.width - previewSize.width) / 2, y: (self.cameraView.bounds.height - previewSize.height) / 2), size: previewSize)
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
        
        let detectTextLayer = createDebugLayer()
        let detectBarcodesLayer = createDebugLayer()
        
        cameraView.layer.addSublayer(detectTextLayer)
        cameraView.layer.addSublayer(detectBarcodesLayer)
        
        let detectBarcodesRequest = VNDetectBarcodesRequest { (request, error) in
            guard let observations = request.results as? [VNBarcodeObservation] else { return }
            
            DispatchQueue.main.async {
                self.drawPolygons(with: observations, to: detectBarcodesLayer)
            }
        }
        
        let detectTextRequest = VNDetectTextRectanglesRequest { (request, error) in
            guard let observations = request.results as? [VNTextObservation] else { return }
            
            DispatchQueue.main.async {
                self.drawPolygons(with: observations, to: detectTextLayer)
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
            if let cameraIntrinsicMatrix = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
                options[VNImageOption.cameraIntrinsics] = cameraIntrinsicMatrix
            }
            
            try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: UInt32(deviceOrientation.exifOrientation(frontFacing: false).rawValue)) ?? .rightMirrored, options: options).perform([
                detectTextRequest,
                detectBarcodesRequest
            ])
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
    
    private func updateToolBar() {
        if let _ = self.currentTargetImage {
            toolBar.setItems([
                UIBarButtonItem(title: "Retake".localized, style: .plain, target: self, action: #selector(self.cancelButtonDidTap)),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(title: "Show All Texts".localized, style: .plain, target: self, action: #selector(self.toggleResultPreviewMode)),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.actionButtonDidTap)),
//                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
//                UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.savePhoto))
                ], animated: true)
        }
        else {
            toolBar.setItems([
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(title: "Tap To Detect".localized, style: .plain, target: self, action: #selector(self.cameraViewDidTap)),
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
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
    
    @objc private func toggleResultPreviewMode(sender: Any) {
        resultPreviewView.showsPlainText = !resultPreviewView.showsPlainText
        if let results = self.resultPreviewView.detectResult {
            resultPreviewView.reloadResults(results)
        }
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
                }
            }
        }
    }
}

extension MemoCamAppDockContent: ResultPreviewViewDelegate {
    fileprivate func showActions(with results: [VisionTextImageDetectResult]) {
        DispatchQueue.global(qos: .userInteractive).async{
            let asyncSignal = AsyncSignal()
            if let resultMessage = results.handleAsAction(true, asyncSignal){
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
