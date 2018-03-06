//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import QuartzCore
import Photos
import UIKit
import MobileCoreServices
import Crashlytics


public class TransformAppConfig: NSObject, KeyPathWatchable, AppConfigViewAttrributes {
    @objc dynamic
    public var tintColor: UIColor?

    @objc dynamic
    public var transform: BatchAppPHAssetState?
}


class _TransformAppAsset: PHAssetItem<BatchAppPHAssetState> {}

public class TransformApp: NSObject, KeyPathWatchable, ConfigurableApp, _ConfigurableApp, PHAssetEditableFinalizableApp {
    public static let taskType:Taskable.Type = _TransfromAppTask.self

    public static let paramType:TaskParamable.Type = _TransformAppAsset.self

    @objc dynamic
    public static var configure:(() -> TransformAppConfig)?

    public lazy var config: TransformAppConfig? = TransformApp.configure?() ?? TransformAppConfig()

    public private(set) lazy var configView: UIView? = createPreferenceView()

    public private(set) lazy var configNotificator = NotificationCenter()

    public static let info = AppInfo(
            identifier: "com.stells.batch.transform"
            , version: "1.0"
            , phase: .release
            , appType: TransformApp.self
            , displayName: "Transform"
            , icon: "Transform.App.Icon"
            , policy: AppPolicy.default
    )

    required public override init(){
        super.init()
    }
}

private extension TransformApp{

    @objc func horizontalFlipButtonDidTap() {
        self.config?.transform = HorizontalFlipTransformItem()
    }

    @objc func verticalFlipButtonDidTap() {
        self.config?.transform = VerticalFlipTransformItem()
    }

    @objc func rotationLeftButtonDidTap() {
        self.config?.transform = RotationTransformItem(degrees: -90)
    }

    @objc func rotationRightButtonDidTap() {
        self.config?.transform = RotationTransformItem(degrees: 90)
    }

    private func createPreferenceView() -> UIView {
        let view = UIStackView(frame: .zero)
        view.alignment = .fill
        view.distribution = .fillEqually
        view.axis = .horizontal

        let config1 = UIButton(type: .system)
        config1.setImage(UIImage(named: "Flip Vertical")?.withRenderingMode(.alwaysTemplate), for: .normal)
        config1.addTarget(self, action: #selector(self.verticalFlipButtonDidTap), for: .touchUpInside)

        let config2 = UIButton(type: .system)
        config2.setImage(UIImage(named: "Flip Horizontal")?.withRenderingMode(.alwaysTemplate), for: .normal)
        config2.addTarget(self, action: #selector(self.horizontalFlipButtonDidTap), for: .touchUpInside)

        let config3 = UIButton(type: .system)
        config3.setImage(UIImage(named: "Rotate Left")?.withRenderingMode(.alwaysTemplate), for: .normal)
        config3.addTarget(self, action: #selector(self.rotationLeftButtonDidTap), for: .touchUpInside)

        let config4 = UIButton(type: .system)
        config4.setImage(UIImage(named: "Rotate Right")?.withRenderingMode(.alwaysTemplate), for: .normal)
        config4.addTarget(self, action: #selector(self.rotationRightButtonDidTap), for: .touchUpInside)

//        switch appDockView.barStyle {
//        case .black:
//            config1.tintColor = .white
//            config2.tintColor = .white
//            config3.tintColor = .white
//            config4.tintColor = .white
//        default:
//            config1.tintColor = .black
//            config2.tintColor = .black
//            config3.tintColor = .black
//            config4.tintColor = .black
//        }

        if let tintColor = self.config?.tintColor {
            config1.tintColor = tintColor
            config2.tintColor = tintColor
            config3.tintColor = tintColor
            config4.tintColor = tintColor
        }

        view.addArrangedSubview(config1)
        view.addArrangedSubview(config2)
        view.addArrangedSubview(config3)
        view.addArrangedSubview(config4)

        return view
    }
}

//TODO: retrictful conforms param type
private class _TransfromAppTask: TaskPrototype, Taskable {

    public typealias ParamType = _TransformAppAsset
    public typealias ResultType = PHAssetResultItem

    public func cancel(_ param:TaskParamable, _ async: TaskAsyncSignalable?){

        (param as? _TransformAppAsset)?.cancelEditing()
    }

    public func perform(_ param: TaskParamable, _ async: TaskAsyncSignalable?) throws -> TaskResultable? {
        assert(param is _TransformAppAsset, "TaskParamable type of this app is \(_TransformAppAsset.self)")
        guard let _param = param as? _TransformAppAsset else{
            throw TaskError.invalidParam
        }
        return try self._perform(_param, async)
    }

    private func _perform(_ assetItem: _TransformAppAsset, _ async: TaskAsyncSignalable?) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?

        async?.begin()

        assetItem.runEditing(nil) { (asset, contentEditingOutput) in
            if let asset = asset, let contentEditingOutput = contentEditingOutput {
                result = PHAssetResultItem(
                        asset: asset,
                        contentEditingOutput: contentEditingOutput)
            }
            async?.end()
        }

        async?.stopUntilEnd()
        return result


    }
}
