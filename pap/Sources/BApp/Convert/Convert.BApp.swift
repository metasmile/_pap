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
    public var convertingDirectionIdentifier:String = ConvertApp.defaultConverter.direction.identifier
}

public class ConvertApp: BApp,
        AppDockApp,
        ConfigurableApp, _ConfigurableApp,
        FinalizableApp,
        PHAssetUIAlertControllerSynchronizablePresenter,
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
            , displayName: "Convert", description:nil, keywords:nil
            , iconBundleName: R.image.convertBAppIcon.name
            , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: TaskPolicy.default)
            , minOSVersion: nil
    )

    required public init() {
        dockContent = ConvertAppDockContent(app:self)
    }

    public var doneButtonTitle: String? {
        return "Convert".localized
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return currentConverter?.canPerformWith(source: item) ?? true
    }

    public var numberOfItemsShouldSelect: Int? {
        return nil
    }

    public func setConfigValues<T: AppConfigValuable>(_ config:T){

    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        let resultItems:[Any]? = result
                .filter { respondable in respondable.info.state == .completed }
                .compactMap{ $0.result as? ConvertAppResult }
                .sorted { (result1: ConvertAppResult?, result2: ConvertAppResult?) -> Bool in
                    (result1?.orderedIndex ?? 0) < (result2?.orderedIndex ?? 0)
                }
                .compactMap { ($0.result as? ConverterVoidReturnType) == ConverterVoidReturnValue ? nil : $0.result }

        guard let items = resultItems, items.count > 0 else {
            return result
        }

        self.presentUIAlertControllerAndWait(items: items, asyncSignal)

        return result
    }
}


extension ConvertApp{
    var defaults:ConvertAppDefaults{
        return ConvertApp.defaults as! ConvertAppDefaults
    }

    var currentConverter:Converter.Type?{
        return ConvertApp.availableConverters.first { converterType in
            return converterType.direction==defaults.convertingDirection
        }
    }

    static let availableConverters:[Converter.Type] = [
        MovConverter_Burst.self,
        MovConverter_LivePhoto.self,
        MovConverter_Gif.self,
        MP4Converter_Timelapse.self,

        LivePhotoConverter_Burst.self,
        LivePhotoConverter_Gif.self,
        LivePhotoConverter_Mov.self,
        LivePhotoConverter_Timelapse.self,

        GifConverter_Burst.self,
        GifConverter_LivePhoto.self,
        GifConverter_Timelapse.self,
        GifConverter_Mov.self,

        JpgConverter_ScreenshotPng.self,
        MP4Converter_Mov.self
    ]

    static var availableDirections:[ConvertingDirection] {
        return ConvertApp.availableConverters.map { converterType -> ConvertingDirection in
            return converterType.direction
        }
    }

    static var availableConverterNames:[String] {
        return Array(Set(availableDirections.map { $0.from.rawValue }))
    }

    static func getAvailableConverters(fromRawValue:String) -> [Converter.Type]{
        return availableConverters.filter { converterType in
            return converterType.direction.from.rawValue == fromRawValue
        }
    }

    static func getAvailableConverters(toRawValue:String) -> [Converter.Type]{
        return availableConverters.filter { converterType in
            return converterType.direction.to.rawValue == toRawValue
        }
    }

    static func getAvailableConverters(by direction:ConvertingDirection) -> [Converter.Type]{
        return availableConverters.filter { converterType in
            return converterType.direction == direction
        }
    }

    static func getAvailableConvertersNamesTo(fromRawValue:String) -> [String]{
        return Array(Set(self.getAvailableConverters(fromRawValue: fromRawValue).map { converter -> String in  converter.direction.to.rawValue }))
    }

    static func getAvailableConvertersNamesFrom(toRawValue:String) -> [String]{
        return Array(Set(self.getAvailableConverters(toRawValue: toRawValue).map { converter -> String in  converter.direction.from.rawValue }))
    }

    static var defaultConverter:Converter.Type{
        return GifConverter_LivePhoto.self
    }
}


private struct ConvertAppResult: TaskResultable{
    var result:Any?
    var orderedIndex: Int?
}

private class ConvertAppTask: TaskPrototype, Taskable {
    public typealias ParamType = AppAsset
    public typealias ResultType = ConvertAppResult

    let defaults = ConvertApp.defaults as! ConvertAppDefaults

    override var info: TaskInfo {
        let info = super.info

        //default is undefined.
        info.policy.estimatedConcurrencyCount = nil

        if let currentConverterType = ConvertApp.availableConverters.first(where:{
            $0.direction == defaults.convertingDirection
        }) {

            if currentConverterType is LivePhotoConverter.Type{
                //override concurrencyCount if currentConverterType is LivePhotoConverter
                info.policy.estimatedConcurrencyCount = 1
            }
        }

        return info

    }

    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){

        (param as? AppAsset)?.cancelAllRequestIDs()
    }

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {
        guard let appAsset = param as? AppAsset else { return nil }
        return try _perform(appAsset, async)
    }

    private func _perform(_ assetItem: AppAsset, _ async: AsyncManualSignalable) throws -> ConvertAppResult?  {
        let direction = defaults.convertingDirection
        let needsConverter = ConverterSpec.acquireInstance(collection: ConvertApp.availableConverters, direction: direction, asset: assetItem)

        guard let converter = needsConverter else {
            throw TaskError.rejectedParam
        }

        //TODO: integrate someday remove IFs
        if let converter = converter as? OptionableConverterBase<GifConverterDefaultOption> {
            converter.options = GifConverterDefaultOption.preset(defaults.convertingQuality.qualityType, with: assetItem.asset)
        }
        else if let converter = converter as? OptionableConverterBase<MovConverterOption> {
            converter.options = MovConverterOption.preset(defaults.convertingQuality.qualityType, with: assetItem.asset)
        }
        else if let converter = converter as? OptionableConverterBase<JpgConverterOption> {
            converter.options = JpgConverterOption.preset(defaults.convertingQuality.qualityType, with: assetItem.asset)
        }
        else if let converter = converter as? OptionableConverterBase<MP4ConverterOption> {
            converter.options = MP4ConverterOption.optionBy(defaults.convertingQuality.qualityType, with: assetItem.asset)
        }
        
        let result = converter.convert(source: assetItem, cancellation: { self.info.state == .cancelled }, progressHandler: { progress in
            PHAssetItemProgressNotification.update(item: assetItem, progress: progress)
        }, async)
        let index = AppAssets.selected.index(of: assetItem)

        return ConvertAppResult(result: result, orderedIndex: index)
    }
}
