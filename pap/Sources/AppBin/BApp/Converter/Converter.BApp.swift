//
// Created by BLACKGENE on 02/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

//INFO: mainly focusing on GIF, at first.

import Foundation
import UIKit
import MobileCoreServices
import Photos
import PropertyKit

public class ConverterAppConfigValue: NSObject, PropertyWatchable, AppConfigValuable {
    @objc dynamic
    public var convertingDirectionIdentifier:String = ConverterApp.defaultConverter.direction.identifier
}

public class ConverterApp: BApp,
        AppDockApp,
        ConfigurableApp, _ConfigurableApp,
        ChargeableApp,
        FinalizableApp,
        PHAssetUIAlertControllerSynchronizablePresenter,
        PhotoPickerCollectionViewDisplayableApp,
        PhotoPickerViewControllerDelegatableApp {

    public static let taskType: AppTaskable.Type = ConverterAppTask.self
    public static let paramType: AppTaskParamable.Type = AppAsset.self

    public static var defaultConfigValue: AppConfigValuable {
        return ConverterAppConfigValue()
    }

    @objc dynamic
    public private(set) lazy var config: ConverterAppConfigValue? = type(of:self).defaultConfigValue as? ConverterAppConfigValue

    public private(set) var content: AppDockContent?

    public static let info = AppInfo(
            identifier: "com.stells.pap.converter"
            , version: "1.0"
            , phase: .release
            , appType: ConverterApp.self
            , displayName: "Converter".localized
            , description: "Converter enables you to convert every media formats such as Videos, Live Photos, GIFs into every each other.".localized
            , keywords: ["GIF Converter", "Live Photos", "GIF Editor", "GIF", "Video Converter", "Mp4", "MOV", "Movie File", "Video Quality","Burst Photos","Animated GIF", "Animation"]
            , iconBundleName: R.image.converterBAppIcon.name
            , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: AppTaskPolicy.default)
            , minOSVersion: nil
    )

    required public init() {
        content = ConverterAppDockContent(app:self)
    }

    static var localCharges: [Charge] {
        return self.defaultNonConsumablePaidBAppLocalCharges
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

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncWaitSignalable) -> [AppTaskRespondable] {
        let resultItems:[Any]? = result
                .filter { respondable in respondable.info.state == .completed }
                .compactMap{ $0.result as? ConverterAppResult }
                .sorted { (result1: ConverterAppResult?, result2: ConverterAppResult?) -> Bool in
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


extension ConverterApp{
    var defaults:ConverterAppDefaults{
        return ConverterApp.defaults as! ConverterAppDefaults
    }

    var currentConverter:Converter.Type?{
        return ConverterApp.availableConverters.first { converterType in
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
        return ConverterApp.availableConverters.map { converterType -> ConvertingDirection in
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


private struct ConverterAppResult: AppTaskResultable {
    var result:Any?
    var orderedIndex: Int?
}

private class ConverterAppTask: AppTaskPrototype, AppTaskable {
    public typealias ParamType = AppAsset
    public typealias ResultType = ConverterAppResult

    let defaults = ConverterApp.defaults as! ConverterAppDefaults

    override var info: AppTaskInfo {
        let info = super.info

        //default is undefined.
        info.policy.estimatedConcurrencyCount = nil

        if let currentConverterType = ConverterApp.availableConverters.first(where:{
            $0.direction == defaults.convertingDirection
        }) {

            if currentConverterType is LivePhotoConverter.Type{
                //override concurrencyCount if currentConverterType is LivePhotoConverter
                info.policy.estimatedConcurrencyCount = 1
            }
        }

        return info

    }

    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){

        (param as? AppAsset)?.cancelAllRequestIDs()
    }

    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        guard let appAsset = param as? AppAsset else { return nil }
        return try _perform(appAsset, async)
    }

    private func _perform(_ assetItem: AppAsset, _ async: AsyncWaitSignalable) throws -> ConverterAppResult?  {
        let direction = defaults.convertingDirection
        let needsConverter = ConverterSpec.acquireInstance(collection: ConverterApp.availableConverters, direction: direction, asset: assetItem)

        guard let converter = needsConverter else {
            throw AppTaskError.rejectedParam
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
            AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
        }, async)
        let index = AppAssets.selected.index(of: assetItem)

        return ConverterAppResult(result: result, orderedIndex: index)
    }
}

import Intents

extension ConverterApp: IntentableApp {
    static var intents: [INIntent] {
        if #available(iOS 12.0, *) {
            let openAppIntent = OpenConverterIntent()
            openAppIntent.appId = ConverterApp.info.identifier
            openAppIntent.appName = NSString.deferredLocalizedIntentsString(with: ConverterApp.info.displayName) as String
            openAppIntent.suggestedInvocationPhrase = "Open Converter."
            return [openAppIntent]
        } else {
            return []
        }
    }
}
