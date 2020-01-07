//
// Created by BLACKGENE on 11/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import PropertyKit

class _StabilizerAppAsset: AppAsset {
    fileprivate weak var exportSession: AVAssetExportSession?
    fileprivate weak var editingContext: PHLivePhotoEditingContext?

    func cancelProcessing() {
        exportSession?.cancelExport()
        exportSession = nil

        editingContext?.cancel()
        editingContext = nil
    }
}

public class StabilizerAppValue: ImageEditStateValue {
    override public var stabilizationMode: ImageAlignment.StabilizationMode? {
        return _stabilizationMode
    }

    private var _stabilizationMode: ImageAlignment.StabilizationMode?

    init(_ stabilizationMode: ImageAlignment.StabilizationMode? = nil) {
        super.init()

        _stabilizationMode = stabilizationMode
    }
}


public class StabilizerAppConfigValue: NSObject, PropertyWatchable, AppConfigUIAttributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?

    @objc dynamic
    public var stabilizationMode: ImageEditStateValue?

    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttributeValuable {
            self.tintColor = other.tintColor
        }

        if let other = fromOther as? StabilizerAppConfigValue, let stabilizationMode = other.stabilizationMode{
            self.stabilizationMode = stabilizationMode
        }
    }
}

public class StabilizerApp: NSObject, BApp, PHAssetFinalizableApp, AppDockApp, PhotoPickerViewControllerAppearanceDelegatableApp
        , PhotoPickerCollectionViewDelegatableApp, ConfigurableApp, _ConfigurableApp, EditableApp {
    public static let taskType: AppTaskable.Type = StabilizerTask.self

    public static let paramType: AppTaskParamable.Type = _StabilizerAppAsset.self

    public static var defaultConfigValue: AppConfigValuable {
        let config = StabilizerAppConfigValue()
        config.tintColor = .black
        return config
    }

    @objc dynamic
    public private(set) lazy var config: StabilizerAppConfigValue? = type(of:self).defaultConfigValue as? StabilizerAppConfigValue

    public private(set) lazy var content: AppDockContent? = StabilizerAppDockContent()

    public static let info = AppInfo(
            identifier: "com.stells.batch.stabilizer"
            , version: "0.1"
            , phase: .develop
            , appType: StabilizerApp.self
            , displayName: "Stabilizer".localized.localizedCapitalized, description:nil, keywords:nil
            , icon: nil
            , themeColor: UIColor(red: 0, green: 0, blue: 128 / 255.0, alpha: 1)
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    required public override init() {
        super.init()

        self.defaultEditStateValue = StabilizerAppValue(ImageAlignment.StabilizationMode(rawValue: (StabilizerApp.defaults as! StabilizerAppDefaults).stabilizationMode))
    }

    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.actions]
    }

    public var titleWillFinalize: String? {
        return "Stabilizing Selected Items...".localized
    }
    public var doneButtonTitle: String? {
        return "Stabilize".localized
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.mediaType == .video || item.asset.imageType == .livePhoto
    }

    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
    }

    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func selectEditState(value: ImageEditStateValue?, in content: AppDockContent?) {}
    public func setDefaultEditState(value: ImageEditStateValue?) {
        defaultEditStateValue = value
    }
}

private class StabilizerTask: AppTaskPrototype, AppTaskable {
    private var isCancelled: Bool = false

    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) {

        (param as? _StabilizerAppAsset)?.cancelAllRequestIDs()
        (param as? _StabilizerAppAsset)?.cancelProcessing()
    }

    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _StabilizerAppAsset, "TaskParamable type of this app is \(_StabilizerAppAsset.self)")
        guard let _param = param as? _StabilizerAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }

    private func _perform(_ assetItem: _StabilizerAppAsset, _ async: AsyncWaitSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?

        async.begin()

        DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
            assetItem.runEditing({ (progress) in
                AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, editingResultItems, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: StabilizerApp.self, editInfo: assetItem.editState.stabilizationMode != nil ? ["stabilizationMode": assetItem.editState.stabilizationMode!.rawValue] : [:], from: asset)

                    result = PHAssetResultItem(
                        asset: assetItem,
                        editingResultItems: editingResultItems,
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
                completionHandler(nil, nil, nil)
                return nil
        }

        var reqIDs = [PHAssetRequestID]()

        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil, nil, nil)
                return
            }

            self.exportSession = AVAssetExportSession.export(asset: video, videoComposition: video.stabilize(with: self.editState.stabilizationMode ?? .translation), presetName: AVAssetExportPresetHighestQuality, outputURL: item.output.renderedContentURL, progressHandler: progressHandler, completionHandler: { (success) in
                if success {
                    completionHandler(asset, [PHAssetEditingResultItem(url: item.output.renderedContentURL, resourceType: .video)], item.output)
                }
                else {
                    completionHandler(nil, nil, nil)
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

extension _StabilizerAppAsset: PHAssetLivePhotoEditable {
    func edit<T:LivePhotoProcessable>(processor:T.Type, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? {
        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil, nil, nil)
                return
            }

            let mode = self.editState.stabilizationMode ?? .translation

            let editingContext = PHLivePhotoEditingContext(livePhotoEditingInput: item.input)
            guard let duration = editingContext?.duration.seconds else { return }
            let progress = Progress(totalUnitCount: Int64(duration * 1000))

            var referenceImage: CIImage?
            editingContext?.frameProcessor = { frame, error in
                progressHandler?({
                    progress.completedUnitCount = Int64(frame.time.seconds * 1000)
                    return progress
                }())

                let result: CIImage
                if let image = referenceImage {
                    result = frame.image.stabilize(with: image, mode: mode)
                }
                else {
                    result = frame.image
                }
                referenceImage = frame.image
                return result
            }

            editingContext?.saveLivePhoto(to: item.output, options: nil, completionHandler: { (success, error) in
                guard success else {
                    completionHandler(nil, nil, nil)
                    return
                }

                var resultItems = [PHAssetEditingResultItem(url: item.output.renderedContentURL, resourceType: .photo)]
                if let pairedVideoURL = item.output.pairedVideoRenderedContentURL {
                    resultItems.append(PHAssetEditingResultItem(url: pairedVideoURL, resourceType: .pairedVideo))
                }

                completionHandler(self.asset, resultItems, item.output)
            })

            self.editingContext = editingContext
        }

        return [PHAssetRequestID(forEditingInput: r)]
    }
}

protocol StabilizerAppDefaults: AppDefaults{
    var stabilizationMode: Int {get set}
    var crop: Bool {get set}
}

extension Defaults: StabilizerAppDefaults {
    var stabilizationMode: Int {
        set { set(newValue); papLog.app.defaults.log(value:newValue) }
        get { return get(or: 0) }
    }

    var crop: Bool {
        set { set(newValue); papLog.app.defaults.log(value:newValue) }
        get { return get(or: true) }
    }
}

struct StabilizerSettings {
    static var stabilizationTitles: [String] {
        return [
            "Transform Mode".localized,
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

class StabilizerAppDockContent: NSObject, PropertyWatchable, AppDockContent, AppDockDelegate, UITableViewDelegate, UITableViewDataSource {
    private var defaults = StabilizerApp.defaults as! StabilizerAppDefaults

    lazy var view: UIView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tintColor = StabilizerApp.info.themeColor
        return tableView
    }()

    var contentScrollable: AppDockContentScrollable? {
        guard let scrollView = view as? UITableView else { return nil }
        return AppDockScrollableContent(scrollView)
    }

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
        modeCell.valueGetter = {
            let mode = ImageAlignment.StabilizationMode(rawValue: self.defaults.stabilizationMode)
            if mode.contains(.translation) {
                return StabilizerSettings.stabilizationTitles[0]
            }
            else {
                return StabilizerSettings.stabilizationTitles[1]
            }
        }
        modeCell.valueCollection = StabilizerSettings.stabilizationTitles
        modeCell.valueHandler = {
            if let index = $0 as? Int {
                var options = ImageAlignment.StabilizationMode(rawValue: self.defaults.stabilizationMode)
                if index == 0 {
                    options.remove(.homographic)
                    options.insert(.translation)
                }
                else {
                    options.remove(.translation)
                    options.insert(.homographic)
                }

                self.defaults.stabilizationMode = options.rawValue
                AppCenter.default.currentInstanceAs(StabilizerApp.self)?.config?.stabilizationMode = StabilizerAppValue(options)
            }
        }
        cellDescribers.append(modeCell)

        let cropCell = UITableViewSegmentControlCellDescriber()
        cropCell.itemIdentifier = Cells.stabilizationMode.hashValue
        cropCell.label = "Scale To Fit".localized
        cropCell.valueGetter = { StabilizerSettings.cropTitles[self.defaults.crop ? 0 : 1] }
        cropCell.valueCollection = StabilizerSettings.cropTitles
        cropCell.valueHandler = {
            if let index = $0 as? Int {
                self.defaults.crop = index == 0

                var options = ImageAlignment.StabilizationMode(rawValue: self.defaults.stabilizationMode)
                if index == 0 {
                    options.insert(.crop)
                }
                else {
                    options.remove(.crop)
                }

                self.defaults.stabilizationMode = options.rawValue
                AppCenter.default.currentInstanceAs(StabilizerApp.self)?.config?.stabilizationMode = StabilizerAppValue(options)
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
        (view as? UITableView)?.reloadData()
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
                cell.segmentedControl.selectedSegmentIndex = valueCollection.firstIndex(of: label) ?? 0
            }
            cell.didChangeValue = item.valueHandler
            return cell
        }
        else {
            return UITableViewCell()
        }
    }
}
