//
// Created by BLACKGENE on 11/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import DefaultsKit

class _StabilizerAppAsset: PHAssetItem<ImageEditStateValue> {
    fileprivate var exportSession: AVAssetExportSession?
    
    func cancelProcessing() {
        exportSession?.cancelExport()
        exportSession = nil
    }
}

public class StabilizerAppValue: ImageEditStateValue {
    override var stabilizationMode: ImageAlignment.StabilizationMode? {
        return _stabilizationMode
    }
    
    private var _stabilizationMode: ImageAlignment.StabilizationMode?
    
    init(_ stabilizationMode: ImageAlignment.StabilizationMode? = nil) {
        super.init()
        
        _stabilizationMode = stabilizationMode
    }
}

public extension StateValueSet where T: ImageEditStateValue {
    var stabilizationMode: ImageAlignment.StabilizationMode? {
        return imageEditStateValue?.stabilizationMode
    }
}

public class StabilizerAppConfigValue: NSObject, KeyPathWatchable, AppConfigUIAttrributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?
    
    @objc dynamic
    public var stabilizationMode: ImageEditStateValue?
    
    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttrributeValuable {
            self.tintColor = other.tintColor
        }
        
        if let other = fromOther as? StabilizerAppConfigValue, let stabilizationMode = other.stabilizationMode{
            self.stabilizationMode = stabilizationMode
        }
    }
}

public class Stabilizer: NSObject, BApp, PHAssetFinalizableApp, AppDockApp, PhotoPickerViewControllerDelegatableApp
        , PhotoPickerCollectionViewDisplayableApp, ConfigurableApp, _ConfigurableApp, PreviewableApp{
    public static let taskType: AppTaskable.Type = StabilizerTask.self

    public static let paramType: AppTaskParamable.Type = _StabilizerAppAsset.self
    
    public static var configure:(() -> StabilizerAppConfigValue)?
    
    @objc dynamic
    public private(set) lazy var config: StabilizerAppConfigValue? = Stabilizer.configure?()
    public private(set) lazy var dockContent: AppDockContent? = StabilizerAppDockContent()

    public static let info = AppInfo(
            identifier: "com.stells.pap.stabilizer"
            , version: "0.1"
            , phase: .develop
            , appType: Stabilizer.self
            , displayName: "Stabilizer".localized, description:nil, keywords:nil
            , iconBundleName: nil
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    required public override init() {
        super.init()
        
        self.defaultEditStateValue = StabilizerAppValue(.translation)
    }
    
    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.modify]
    }

    public var titleWillFinalize: String? {
        return "Stabilizing Selected Items...".localized
    }
    public var doneButtonTitle: String? {
        return "Stabilize".localized
    }
    
    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.mediaType == .video// || (item.asset.mediaType == .image && !item.asset.mediaSubtypes.contains(.photoLive))
    }
    
    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
    }
    
    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?) {}
}

private class StabilizerTask: AppTaskPrototype, AppTaskable {
    private var isCancelled: Bool = false
    
    public func cancel(_ param: AppTaskParamable, _ async: AsyncManualSignalable) {
        
        (param as? _StabilizerAppAsset)?.cancelAllRequestIDs()
        (param as? _StabilizerAppAsset)?.cancelProcessing()
    }

    public func perform(_ param: AppTaskParamable, _ async: AsyncManualSignalable) throws -> AppTaskResultable? {
        assert(param is _StabilizerAppAsset, "TaskParamable type of this app is \(_StabilizerAppAsset.self)")
        guard let _param = param as? _StabilizerAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _StabilizerAppAsset, _ async: AsyncManualSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
        async.begin()
        
        DispatchQueue(label: "com.stells.internal."+#file, qos: .utility).async {
            assetItem.runEditing({ (progress) in
                PHAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
                    result = PHAssetResultItem(
                        asset: asset,
                        contentEditingOutput: contentEditingOutput)
                }
                async.end()
            }
        }
        
        async.waitUntilEnd()
        return result
    }
}

extension _StabilizerAppAsset: PHAssetVideoEditable {
    func edit<T>(processor: T.Type, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? where T : VideoProcessable {
        let asset = self.asset
        
        guard
            let video = asset.asAVAsset
//            let videoTrack = video.tracks(withMediaType: .video).first,
            else {
                completionHandler(nil, nil)
                return nil
        }
        
        let maximumClamp = CGPoint(x: asset.pixelSize.width / 20, y: asset.pixelSize.height / 20)
        
        //TODO: Auto clamp ?
//
//        var assetReader: AVAssetReader?
//        var assetReaderOutput: AVAssetReaderOutput?
//
//        do {
//            let (reader, output) = try self.reader(asset: video, track: videoTrack, settings: [kCVPixelBufferPixelFormatTypeKey as String:
//            NSNumber(value: kCVPixelFormatType_32BGRA)])
//
//            assetReader = reader
//            assetReaderOutput = output
//        }
//        catch {}
//
//        let analyzing = AsyncSignal()
//        analyzing.begin()
//
//        assetReaderOutput?.alwaysCopiesSampleData = false
//
//        DispatchQueue(label: Stabilizer.info.identifier + ".queue.analyzing").async {
//            assetReader?.startReading()
//
//            var referenceBuffer: CVPixelBuffer?
//
//            while assetReader?.status == .reading {
//                guard let sampleBuffer = assetReaderOutput?.copyNextSampleBuffer(), let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }
//
//                guard let reference = referenceBuffer else {
//                    referenceBuffer = pixelBuffer
//                    continue
//                }
//
//                if stabilizationMode == .translation {
//                    guard let translation = ImageAlignment.translationTransform(reference, onto: pixelBuffer) else { continue }
//
//                    maximumClamp.x = max(maximumClamp.x, translation.tx.magnitude)
//                    maximumClamp.y = max(maximumClamp.y, translation.ty.magnitude)
//                }
//                else if stabilizationMode == .homographic {
//                    guard let homographic = ImageAlignment.homographicTransform(reference, onto: pixelBuffer) else { continue }
//
//                    let destCoord = float3(1, 1, 1)
//                    let homogeneousSrcCoord = homographic * destCoord
//                    let offsets = CGPoint(x: CGFloat(homogeneousSrcCoord.x / max(homogeneousSrcCoord.z, 0.000001)), y: CGFloat(homogeneousSrcCoord.y / max(homogeneousSrcCoord.z, 0.000001)))
//
//                    maximumClamp.x = max(maximumClamp.x, offsets.x.magnitude)
//                    maximumClamp.y = max(maximumClamp.y, offsets.y.magnitude)
//                }
//
//                referenceBuffer = pixelBuffer
//            }
//
//            analyzing.end()
//        }
//
//        analyzing.waitUntilEnd()
//
//        maximumClamp.x = min(maximumClamp.x, asset.pixelSize.width / 20)
//        maximumClamp.y = min(maximumClamp.y, asset.pixelSize.height / 20)
        
        var reqIDs = [PHAssetRequestID]()
        
        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil,nil)
                return
            }
            
            self.exportSession = AVAssetExportSession.export(asset: video, videoComposition: video.stabilize(with: self.editState.stabilizationMode ?? .translation, clamp: maximumClamp), presetName: AVAssetExportPresetHighestQuality, outputURL: item.output.renderedContentURL, progressHandler: progressHandler, completionHandler: { (success) in
                if success {
                    completionHandler(asset, item.output)
                }
                else {
                    completionHandler(nil, nil)
                }
            })
        }

        reqIDs.append(PHAssetRequestID(forEditingInput: r))
        return reqIDs
    }
    
    private func reader(asset: AVAsset, track: AVAssetTrack, settings: [String: AnyObject]?) throws -> (AVAssetReader, AVAssetReaderOutput) {
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        let reader = try AVAssetReader(asset: asset)
        reader.add(output)
        return (reader, output)
    }
}

protocol StabilizerAppDefaults: AppDefaults{
    var stabilizationMode: Int {get set}
    var crop: Bool {get set}
}

extension Defaults: StabilizerAppDefaults {
    var stabilizationMode: Int {
        set { set(newValue) }
        get { return get(or: 0) }
    }
    
    var crop: Bool {
        set { set(newValue) }
        get { return get(or: true) }
    }
}

struct StabilizerSettings {
    static var stabilizationTitles: [String] {
        return [
            "Translation".localized,
            "Warp".localized
        ]
    }
    
    static var cropTitles: [String] {
        return [
            "Crop".localized,
            "No Crop".localized
        ]
    }
}

private enum Cells {
    case stabilizationMode
    case crop
}

class StabilizerAppDockContent: NSObject, KeyPathWatchable, AppDockContent, AppDockDelegate, UITableViewDelegate, UITableViewDataSource {
    private var defaults = Stabilizer.defaults as! StabilizerAppDefaults
    
    lazy var view: UIView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tintColor = UIColor(red: 0, green: 0, blue: 128 / 255.0, alpha: 1)
        return tableView
    }()
    
    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = 200
        return preferences
    }
    
    var appDock:AppDock?
    
    private var cellDescribers = [UITableViewCellDefaultDescribable]()
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        appDock = dock
        
        if cellDescribers.count==0{
            let cellDescribers = createCellDescribers()
            
            if let view = view as? UITableView{
                view.dataSource = self
                view.delegate = self
                view.rowHeight = 44
                
                for item in cellDescribers {
                    view.register(describer: item)
                }
            }
        }
    }
    
    private func createCellDescribers() -> [UITableViewCellDefaultDescribable] {
        let modeCell = UITableViewSegmentControlCellDescriber()
        modeCell.itemIdentifier = Cells.stabilizationMode.hashValue
        modeCell.label = "Stabilization Mode".localized
        modeCell.valueGetter = { StabilizerSettings.stabilizationTitles[self.defaults.stabilizationMode] }
        modeCell.valueCollection = StabilizerSettings.stabilizationTitles
        modeCell.valueHandler = {
            if let index = $0 as? Int {
                self.defaults.stabilizationMode = index
                AppCenter.default.currentInstanceAs(Stabilizer.self)?.config?.stabilizationMode = StabilizerAppValue(ImageAlignment.StabilizationMode(rawValue: index))
            }
        }
        cellDescribers.append(modeCell)
        
        let cropCell = UITableViewSegmentControlCellDescriber()
        cropCell.itemIdentifier = Cells.stabilizationMode.hashValue
        cropCell.label = "Crop To Fit".localized
        cropCell.valueGetter = { StabilizerSettings.cropTitles[self.defaults.crop ? 0 : 1] }
        cropCell.valueCollection = StabilizerSettings.cropTitles
        cropCell.valueHandler = {
            if let index = $0 as? Int {
                self.defaults.crop = index == 0
            }
        }
        cellDescribers.append(cropCell)
        
        return cellDescribers
    }
    
    var delegate: AppDockDelegate? {
        return self
    }
    
    func dockWillContract(_ dock: AppDock) {
        
    }
    
    func didSetContentView(_ view:UIView, dock:AppDock) {
        (view as! UITableView).reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellDescribers.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Stabilizer".localized
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = cellDescribers[indexPath.row]
        
        if let cellDescriber = item as? UITableViewSegmentControlCellDescriber
            , let valueCollection = cellDescriber.valueCollection as? [String]
            , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSegmentedControlCell {
            
            cell.textLabel?.text = item.label
            cell.imageView?.image = item.iconImage?.asUIImage
            cell.detailTextLabel?.textColor = UIColor.gray
            
            cell.segmentedControl.apportionsSegmentWidthsByContent = true
            cell.segmentedControl.removeAllSegments()
            for k in valueCollection{
                cell.segmentedControl.insertSegment(withTitle: k, at: cell.segmentedControl.numberOfSegments, animated: false)
            }
            cell.segmentedControl.sizeToFit()
            
            if let label = item.valueGetter() as? String {
                cell.segmentedControl.selectedSegmentIndex = valueCollection.index(of: label) ?? 0
            }
            cell.didChangeValue = item.valueHandler
            return cell
        }
        else {
            return UITableViewCell()
        }
    }
}
