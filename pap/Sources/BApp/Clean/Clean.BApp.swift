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
        
        if preheatedResult?.lockscreen == true || preheatedResult?.hasSimilarAsset == true {
            return UICollectionViewPreheatableAppFinishAction.selectItem
        }
        
        return nil
    }
}

private struct CleanAppDetector {
    struct SimilarAsset {
        var id: PHAssetID
        var distance: OSHashDistanceType
    }
    fileprivate var similarAssets = [PHAssetID: [SimilarAsset]]()
    fileprivate let imageHashing = OSImageHashing<AnyObject>.sharedInstance()
    
    fileprivate mutating func detectResult(asset:PHAsset, _ async: AsyncManualSignalable) -> CleanAppResult? {
        var result = CleanAppResult(asset: asset)
        
//            if asset.mediaSubtypes.contains(.photoScreenshot) {
//                result.lockscreen = true
//            }
        
        result.hasSimilarAsset = detectSimilarAsset(asset.localIdentifierWithoutSplitter)
        result.isTooBlurry = detectBlurryAsset(asset)
        
        return result
    }
    
    struct MTKTextureBuilder {
        static func texture(cgImage: CGImage) -> MTLTexture? {
            guard let device = MTLCreateSystemDefaultDevice() else { return nil }
            let loader = MTKTextureLoader(device: device)
            
            let textureUsage: MTLTextureUsage = MTLTextureUsage.shaderRead
            
            let options = [
                MTKTextureLoader.Option.textureUsage: textureUsage.rawValue,
                //            MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.flippedVertically.rawValue,
                ] as [MTKTextureLoader.Option : Any]
            
            return try? loader.newTexture(cgImage: cgImage, options: options)
        }
    }
    
    private func detectBlurryAsset(_ asset: PHAsset) -> Bool {
        // https://www.pyimagesearch.com/2015/09/07/blur-detection-with-opencv/
        // https://stackoverflow.com/questions/46893198/detecting-if-image-is-blurred-using-opencv
        //
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue(),
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let ciImage = asset.asCIImage
        else { return false }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: Int(ciImage.extent.width), height: Int(ciImage.extent.height), mipmapped: true)
        textureDescriptor.usage = [MTLTextureUsage.shaderRead, MTLTextureUsage.shaderWrite]
        
        guard
            let sourceTexture = device.makeTexture(descriptor: textureDescriptor),
            let binaryTexture = device.makeTexture(descriptor: textureDescriptor),
            let laplacianTexture = device.makeTexture(descriptor: textureDescriptor)
        else { return false }
        
        ImageAlignment.sharedCIContext.render(ciImage, to: sourceTexture, commandBuffer: commandBuffer, bounds: ciImage.extent, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        //TODO: binary
        MPSImageThresholdBinary(device: device, thresholdValue: 0, maximumValue: 1, linearGrayColorTransform: nil).encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: binaryTexture)
        
        //TODO: laplacian
        MPSImageLaplacian(device: device).encode(commandBuffer: commandBuffer, sourceTexture: binaryTexture, destinationTexture: laplacianTexture)
        
        //TODO: threshold
        // blurry or not
        
//        var histogramInfo = MPSImageHistogramInfo(
//            numberOfHistogramEntries: 256,
//            histogramForAlpha: false,
//            minPixelValue: vector_float4(0,0,0,0),
//            maxPixelValue: vector_float4(1,1,1,1))
//        
//        let histogram = MPSImageHistogram(device: device, histogramInfo: &histogramInfo)
//        let bufferLength = histogram.histogramSize(forSourceFormat: sourceTexture.pixelFormat)
//        guard let histogramInfoBuffer = device.makeBuffer(length: bufferLength, options: [.cpuCacheModeWriteCombined]) else { return false }
//        
//        histogram.encode(to: commandBuffer, sourceTexture: laplacianTexture, histogram: histogramInfoBuffer, histogramOffset: 0)
        
        commandBuffer.commit()
        
//        var histogramData = [Float](repeating: 0, count: 256)
//        histogramInfoBuffer.contents().copyMemory(from: &histogramData, byteCount: 256 * MemoryLayout<Float>.stride)
//
//        print(histogramData)
        
        return false
    }
    
    private mutating func detectSimilarAsset(_ assetID: PHAssetID) -> Bool {
        // https://github.com/ameingast/cocoaimagehashing/
        
        let timeClustering: TimeInterval = 3600 / 2 // half hour
        
        var hasSimilar = false
        for fromAssetID in similarAssets.keys {
            guard let fromAsset = PHAsset.fetchAsset(withLocalIdentifier: fromAssetID), let toAsset = PHAsset.fetchAsset(withLocalIdentifier: assetID) else { continue }
            
            guard let fromDate = fromAsset.creationDate, let toDate = toAsset.creationDate, fromDate.timeIntervalSince(toDate).magnitude < timeClustering else {
                continue
            }
            
            var hashDistance: OSHashDistanceType = 0
            if let similarAsset = similarAssets[fromAssetID]?.filter({ $0.id == assetID }).first {
                hashDistance = similarAsset.distance
            }
            else if let fromData = fromAsset.asData, let toData = toAsset.asData {
                let fromHash = imageHashing.hashImageData(fromData)
                let toHash = imageHashing.hashImageData(toData)
                let distance = imageHashing.hashDistance(fromHash, to: toHash)
                
                let similarAsset = SimilarAsset(id: assetID, distance: distance)
                similarAssets[fromAssetID]?.append(similarAsset)
                
                hashDistance = distance
            }
            
            if hashDistance < imageHashing.hashDistanceSimilarityThreshold(withProvider: .dHash) {
                hasSimilar = true
                break
            }
        }
        
        if similarAssets[assetID] == nil {
            similarAssets[assetID] = []
        }
        
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

