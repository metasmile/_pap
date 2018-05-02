//
// Created by BLACKGENE on 02/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

//INFO: mainly focusing on GIF, at first.

import Foundation
import UIKit

public class Converter: BApp,
        AppDockControllableApp,
        PHAssetFinalizableApp,
        PhotoPickerCollectionViewDisplayableApp,
        PhotoPickerViewControllerDelegatableApp {

    private class ConverterTask: TaskPrototype, Taskable{
        func perform(_ param: TaskParamable, _ async: AsyncManualSignalable?) throws -> TaskResultable? {
            fatalError("perform(param:async:) has not been implemented")
        }

        func cancel(_ param: TaskParamable, _ async: AsyncManualSignalable?) {

        }
    }

    public static let taskType:Taskable.Type = ConverterTask.self
    public static let paramType:TaskParamable.Type = AppAsset.self

    public static var configure:(() -> GIFMakerAppConfig)?

    @objc dynamic
    public private(set) lazy var config: GIFMakerAppConfig? = GIFMaker.configure?()
    public private(set) lazy var controller: AppDockContent? = GIFMakerAppDockContent()

    public static let info = AppInfo(
            identifier: "com.stells.batch.converter"
            , version: "1.0"
            , phase: .develop
            , appType: Converter.self
            , displayName: "Converter" // 1 - 1
            , icon: R.image.photosFilterAppIcon.name
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    required public init() {}

    public var doneButtonTitle: String? {
        return "Convert".localized
    }

    public func shouldSelect(item: PHAssetItem<ImageEditStateValue>) -> Bool {
        return true
    }

    public var numberOfItemsShouldSelect: Int? {
        return nil
    }

    public var finalizingPresets: [PHAssetFinalizingPresets]? {
        return nil
    }

    public func setConfigValues<T: AppConfigValuable>(_ config:T){

    }

    public func shouldFinalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> Bool {
        return true
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {

        return result
    }
}