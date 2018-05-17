//
// Created by BLACKGENE on 02/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

//INFO: mainly focusing on GIF, at first.

import Foundation
import UIKit
import MobileCoreServices
import Photos

public class ConvertAppConfigValue: NSObject, KeyPathWatchable, AppConfigValuable {
    @objc dynamic
    public var convertingDirectionIdentifier:String = ConvertApp.defaultWorker.direction.identifier
}

public class ConvertApp: BApp,
        AppDockControllableApp,
        ConfigurableApp, _ConfigurableApp,
        PHAssetUIActivityFinalizableApp,
        PhotoPickerCollectionViewDisplayableApp,
        PhotoPickerViewControllerDelegatableApp {

    public static let taskType:Taskable.Type = ConvertAppTask.self
    public static let paramType:TaskParamable.Type = AppAsset.self

    public static var configure:(() -> ConvertAppConfigValue)?

    @objc dynamic
    public private(set) lazy var config: ConvertAppConfigValue? = ConvertAppConfigValue()

    public private(set) var dockContent: AppDockContent?

    public static let info = AppInfo(
            identifier: "com.stells.pap.convert"
            , version: "1.0"
            , phase: .release
            , appType: ConvertApp.self
            , displayName: "Convert" // 1 - 1
            , icon: R.image.convertBAppIcon.name
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    required public init() {
        dockContent = ConvertAppDockContent(app:self)
    }

    public var doneButtonTitle: String? {
        return "Convert".localized
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return currentWorker?.canPerformWith(source: item) ?? true
    }

    public var numberOfItemsShouldSelect: Int? {
        return nil
    }

    public func setConfigValues<T: AppConfigValuable>(_ config:T){

    }
    
    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.create, .share]
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        let resultItems:[ConvertAppResult]? = result
                .filter { respondable in respondable.info.state == .completed }
                .compactMap{ $0.result as? ConvertAppResult }
                .sorted { ($0?.orderedIndex ?? 0) < ($1?.orderedIndex ?? 0) }
        
//                .compactMap { ($0.result as? ConverterVoidReturnType) == ConverterVoidReturnValue ? nil : $0.result }
//                .compactMap { $0.result }

        self.presentFinalizingActivity(items: resultItems?.compactMap { $0.finalizingItem }, asyncSignal)

        return result
    }
}


extension ConvertApp{
    var defaults:ConvertAppDefaults{
        return ConvertApp.defaults as! ConvertAppDefaults
    }

    var currentWorker:Converter.Type?{
        return ConvertApp.availableWorkers.first { converterType in
            return converterType.direction==defaults.convertingDirection
        }
    }

    static let availableWorkers:[Converter.Type] = [
        MovConverter_Burst.self,
        MovConverter_LivePhoto.self,
        MovConverter_Gif.self,

        LivePhotoConverter_Burst.self,
        LivePhotoConverter_Gif.self,
        LivePhotoConverter_Video.self,

        GifConverter_Burst.self,
        GifConverter_LivePhoto.self,
        GifConverter_Timelapse.self,
        GifConverter_Mov.self,

        JpgConverter_ScreenshotPng.self,
        MP4Converter_Mov.self
    ]

    static var availableDirections:[ConvertingDirection] {
        return ConvertApp.availableWorkers.map { converterType -> ConvertingDirection in
            return converterType.direction
        }
    }

    static var availableWorkerNames:[String] {
        return Array(Set(availableDirections.map { $0.from.rawValue }))
    }

    static func getAvailableWorkers(fromRawValue:String) -> [Converter.Type]{
        return availableWorkers.filter { converterType in
            return converterType.direction.from.rawValue == fromRawValue
        }
    }

    static func getAvailableWorkers(toRawValue:String) -> [Converter.Type]{
        return availableWorkers.filter { converterType in
            return converterType.direction.to.rawValue == toRawValue
        }
    }

    static func getAvailableWorkersNamesTo(fromRawValue:String) -> [String]{
        return Array(Set(self.getAvailableWorkers(fromRawValue: fromRawValue).map { converter -> String in  converter.direction.to.rawValue }))
    }

    static func getAvailableWorkersNamesFrom(toRawValue:String) -> [String]{
        return Array(Set(self.getAvailableWorkers(toRawValue: toRawValue).map { converter -> String in  converter.direction.from.rawValue }))
    }

    static var defaultWorker:Converter.Type{
        return GifConverter_LivePhoto.self
    }
}


private struct ConvertAppResult: TaskResultable{
    var finalizingItem:PHAssetFinalizingActivityItem?
    var orderedIndex: Int?
}

private class ConvertAppTask: TaskPrototype, Taskable {
    public typealias ParamType = AppAsset
    public typealias ResultType = ConvertAppResult

    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){

        (param as? AppAsset)?.cancelAllRequestIDs()
    }

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {
        guard let appAsset = param as? AppAsset else { return nil }
        return try _perform(appAsset, async)
    }

    private func _perform(_ assetItem: AppAsset, _ async: AsyncManualSignalable) throws -> ConvertAppResult?  {
        let defaults = ConvertApp.defaults as! ConvertAppDefaults
        let direction = defaults.convertingDirection

        let needsConverter = ConverterSpec.acquireInstance(collection: ConvertApp.availableWorkers, direction: direction, asset: assetItem)

        guard let converter = needsConverter else {
            throw TaskError.rejectedParam
        }
        
        if let gifConverter = converter as? OptionableConverterBase<GifConverterDefaultOption> {
            gifConverter.options = GifConverterDefaultOption.preset(defaults.convertingQuality.qualityType, with: assetItem.asset)
        }
        else if let movConverter = converter as? OptionableConverterBase<MovConverterOption> {
            movConverter.options = MovConverterOption.preset(defaults.convertingQuality.qualityType, with: assetItem.asset)
        }
        else if let jpgConverter = converter as? OptionableConverterBase<JpgConverterOption> {
            jpgConverter.options = JpgConverterOption.preset(defaults.convertingQuality.qualityType, with: assetItem.asset)
        }

        let result = converter.convert(source: assetItem, async)
        
        var output: PHAssetFinalizingOutput? = nil
        if let url = result as? URL {
            if direction.to == .mov || direction.to == .mp4 {
                output = PHAssetFinalizingOutput(resources: [(.video, url)])
            }
            else {
                output = PHAssetFinalizingOutput(resources: [(.photo, url)])
            }
        }
        else if let urls = result as? (imageURL: URL, pairedVideoURL: URL) {
            if direction.to == .livephoto {
                output = PHAssetFinalizingOutput(resources: [
                    (.photo, urls.imageURL),
                    (.pairedVideo, urls.pairedVideoURL)
                ])
            }
        }
        let finalizingItem = PHAssetFinalizingActivityItem(input: assetItem, output: output)
        return result == nil ? nil : ConvertAppResult(finalizingItem: finalizingItem, orderedIndex: AppAssets.selected.index(of: assetItem))
    }
}
