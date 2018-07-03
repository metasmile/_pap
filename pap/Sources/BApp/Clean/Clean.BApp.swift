//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import DefaultsKit
import CocoaImageHashing
import MetalPerformanceShaders
import MetalKit
import Vision

private typealias CleanAppParam = PHAssetItem<ImageEditStateValue>
private struct CleanAppResult: TaskResultable{
    fileprivate let asset:PHAsset
    
    init(asset:PHAsset){
        self.asset = asset
    }
    
    fileprivate var lockscreen:Bool?
    fileprivate var hasSimilarAsset:Bool?
    fileprivate var isTooBlurry:Bool?
}

private protocol CleanAppDefaults: AppDefaults{
    
}

extension Defaults: CleanAppDefaults {
    
}

private typealias PHAssetID = String

public class Clean: NSObject, BApp, KeyPathWatchable, PHAssetFinalizableApp, AppDockApp, PhotoPickerViewControllerDelegatableApp, PreheatableApp {
    public static let taskType:Taskable.Type = _CleanTask.self

    public static let paramType:TaskParamable.Type = PHAssetItem<ImageEditStateValue>.self
    
    public private(set) lazy var dockContent: AppDockContent? = CleanAppDockContent()

    public static let info = AppInfo(
            identifier: "com.stells.pap.clean"
            , version: "0.1"
            , phase: .develop
            , appType: Clean.self
            , displayName: "Clean", description:nil, keywords:nil
            , iconBundleName: nil
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    public required override init() {}

    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.delete]
    }

    public var titleWillFinalize: String? {
        return "Deleting Photos...".localized
    }
    public var doneButtonTitle: String? {
        return "Delete".localized
    }
    
    @objc dynamic
    public fileprivate (set) lazy var autoSelect: Bool = false
    
    fileprivate var detector = CleanAppDetector()
    
    fileprivate var preheatedResults = [PHAssetID: CleanAppResult]()
    fileprivate var preheatedSimilarities = [PHAssetID: [PHAssetID]]()
    
    public func performPreheating(item: AppAsset, _ async: AsyncSignal) -> PreheatingFinishAction? {
        guard self.autoSelect else { return nil }
        
        var preheatedResult:CleanAppResult? = preheatedResults[item.asset.localIdentifierWithoutSplitter]
        if preheatedResult == nil {
            preheatedResult = self.detector.detectResult(asset: item.asset, async) ?? CleanAppResult(asset: item.asset)
            preheatedResults[item.asset.localIdentifierWithoutSplitter] = preheatedResult
        }
        
        if preheatedResult?.lockscreen == true || preheatedResult?.hasSimilarAsset == true || preheatedResult?.isTooBlurry == true {
            return UICollectionViewPreheatableAppFinishAction.selectItem
        }
        
        return nil
    }
}

private struct CleanAppDetector {
    fileprivate mutating func detectResult(asset:PHAsset, _ async: AsyncManualSignalable) -> CleanAppResult? {
        var result = CleanAppResult(asset: asset)
        
//            if asset.mediaSubtypes.contains(.photoScreenshot) {
//                result.lockscreen = true
//            }
        
        autoreleasepool {
            result.hasSimilarAsset = detectSimilarAsset(asset)
            guard result.hasSimilarAsset != true else { return }
            
            result.isTooBlurry = detectBlurryImage(asset)
            guard result.isTooBlurry != true else { return }
        }
        
        return result
    }
    
    private func croppedFaceGroup(_ image: CIImage) -> CIImage? {
        let dispatchGroup = DispatchGroup()
        
        var faceBounds: CGRect?
        
        let faceDetectRequest = VNDetectFaceRectanglesRequest { (request, error) in
            dispatchGroup.leave()
            
            if let faces = (request.results as? [VNFaceObservation])?.compactMap({ $0.boundingBox }), !faces.isEmpty, let bounds = faces[1...].reduce(faces.first, { $0?.union($1) }), bounds.width * bounds.height > 0.2 {
                let transform = CGAffineTransform(scaleX: image.extent.width, y: image.extent.height)
                faceBounds = bounds.applying(transform)
            }
        }
        
        dispatchGroup.enter()
        try? VNImageRequestHandler(ciImage: image, options: [:]).perform([faceDetectRequest])
        dispatchGroup.wait()
        
        guard let rect = faceBounds else { return nil }
        return image.cropped(to: rect)
    }
    
    private func detectBlurryImage(_ asset: PHAsset) -> Bool {
        // https://www.pyimagesearch.com/2015/09/07/blur-detection-with-opencv/
        // https://stackoverflow.com/questions/46893198/detecting-if-image-is-blurred-using-opencv
        //
        guard
            asset.imageType == .stillImage,
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue(),
            let commandBuffer = commandQueue.makeCommandBuffer(),
            var ciImage = asset.asCIImage
            else { return false }
        
        if let face = croppedFaceGroup(ciImage) {
            ciImage = face
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: Int(ciImage.extent.width), height: Int(ciImage.extent.height), mipmapped: false)
        textureDescriptor.usage = [MTLTextureUsage.shaderRead, MTLTextureUsage.shaderWrite]
        
        guard
            let sourceTexture = device.makeTexture(descriptor: textureDescriptor),
            let binaryTexture = device.makeTexture(descriptor: textureDescriptor),
            let laplacianTexture = device.makeTexture(descriptor: textureDescriptor)
            else { return false }
        
        ImageAlignment.sharedCIContext.render(ciImage, to: sourceTexture, commandBuffer: commandBuffer, bounds: ciImage.extent, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        MPSImageLaplacian(device: device).encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: laplacianTexture)
        MPSImageThresholdBinary(device: device, thresholdValue: 0.4, maximumValue: 1, linearGrayColorTransform: nil).encode(commandBuffer: commandBuffer, sourceTexture: laplacianTexture, destinationTexture: binaryTexture)
        
        let numberOfHistogramEntries = 256
        
        var histogramInfo = MPSImageHistogramInfo(
            numberOfHistogramEntries: numberOfHistogramEntries,
            histogramForAlpha: false,
            minPixelValue: vector_float4(0, 0, 0, 0),
            maxPixelValue: vector_float4(1, 1, 1, 1))
        
        let histogram = MPSImageHistogram(device: device, histogramInfo: &histogramInfo)
        let bufferLength = histogram.histogramSize(forSourceFormat: binaryTexture.pixelFormat)
        guard let histogramInfoBuffer = device.makeBuffer(length: bufferLength, options: []) else { return false }
        
        histogram.encode(to: commandBuffer, sourceTexture: binaryTexture, histogram: histogramInfoBuffer, histogramOffset: 0)
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let histogramContents = histogramInfoBuffer.contents().bindMemory(to: Float.self, capacity: numberOfHistogramEntries)
        
        let threshold: Float = 0.00000000000000000000000000000000000000000031 //TODO: this is a manual threshold
        let numberOfWhitePixels = histogramContents[numberOfHistogramEntries - 1]
        
        return numberOfWhitePixels < threshold
    }
    
    fileprivate var targetAssets = [PHAsset]()
    fileprivate let imageHashing = OSImageHashing.sharedInstance()
    
    private mutating func detectSimilarAsset(_ asset: PHAsset) -> Bool {
        // https://github.com/ameingast/cocoaimagehashing/
        
        let timeClustering: TimeInterval = 60 // 1 minute
        
        var hasSimilar = false
        for targetAsset in targetAssets[..<min(targetAssets.count, 20)] {
            guard let fromDate = targetAsset.creationDate, let toDate = asset.creationDate, fromDate.timeIntervalSince(toDate).magnitude < timeClustering else {
                continue
            }
            
            guard let fromData = targetAsset.requestThumbnailImage(targetSize: CGSize(width: 100, height: 100))?.asData, let toData = asset.requestThumbnailImage(targetSize: CGSize(width: 100, height: 100))?.asData else { continue }
            
            let fromHash = imageHashing.hashImageData(fromData)
            let toHash = imageHashing.hashImageData(toData)
            let distance = imageHashing.hashDistance(fromHash, to: toHash)
            
            if distance < imageHashing.hashDistanceSimilarityThreshold(withProvider: .dHash) {
                hasSimilar = true
                break
            }
        }
        
        targetAssets.insert(asset, at: 0)
        
        return hasSimilar
    }
}

private class _CleanTask: TaskPrototype, Taskable {
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){}

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {
        if let asset = (param as? PHAssetItem<ImageEditStateValue>)?.asset{
            return PHAssetResultItem(asset: asset, contentEditingOutput: nil)
        }
        return nil
    }
}

fileprivate class CleanAppDockContent: NSObject, KeyPathWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    private lazy var defaults = Clean.defaults as! CleanAppDefaults
    
    private let primaryColor = UIColor(red:0.6, green:0.6, blue:0.6, alpha:1)
    
    lazy var view: UIView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        return tableView
    }()
    
    private var autoSelect:Bool = false
    
    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = (view as! UITableView).rowHeight + 48
        return preferences
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        if let view = view as? UITableView{
            view.dataSource = self
            view.delegate = self
            view.rowHeight = 52
            view.allowsSelection = false
            view.register(Cell.self, forCellReuseIdentifier: Clean.info.identifier)
            //            view.backgroundColor = UIColor(red: 31 / 255.0, green: 31 / 255.0, blue: 31 / 255.0, alpha: 1)
            view.tintColor = self.primaryColor
            //            view.separatorInset.left = view.rowHeight
        }
    }
    
    func didSetContentView(_ view:UIView, dock:AppDock) {
        if options != nil{
            (view as! UITableView).reloadData()
        }
    }
    
    @objc dynamic
    var options:[String: Any]? // Bool may be other custom Codable type instead of Any
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "🖼️ ‣ 🤖 ‣ ❌ " + "Select Photos You Want To Clean!".localized : nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Clean.info.identifier) as! Cell
        
        cell.imageView?.tintColor = primaryColor
        cell.imageView?.contentMode = .scaleAspectFit
        
        cell.textLabel?.text = "Enable Auto Selection".localized
        cell.optionSwitch.setOn(self.autoSelect, animated: false)
        cell.switchDidChange = { on in
            self.autoSelect = on
            AppCenter.default.currentInstanceAs(Clean.self)?.autoSelect = on
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private class Cell: UITableViewCell {
        lazy var optionSwitch: UISwitch = {
            let view = UISwitch()
            view.addTarget(self, action: #selector(self.cellSwitchDidChange), for: .valueChanged)
            return view
        }()
        
        var switchDidChange: ((Bool) -> Void)?
        
        override func prepareForReuse() {
            super.prepareForReuse()
            
            switchDidChange = nil
        }
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            accessoryView = optionSwitch
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc func cellSwitchDidChange(sender: UISwitch) {
            switchDidChange?(sender.isOn)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
        }
        
        override func tintColorDidChange() {
            super.tintColorDidChange()
            
            optionSwitch.onTintColor = tintColor
        }
    }
}

