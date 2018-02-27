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

class _TransformAppAsset: PHAssetItem<BatchAppPHAssetState> {}

public class TransformApp: AppPrototype, App, PHAssetEditableFinalizableApp, ConfigurableApp {
    public static let taskType:Taskable.Type = _TransfromAppTask.self

    public static let paramType:TaskParamable.Type = _TransformAppAsset.self

    public private(set) lazy var configView: UIView? = createPreferenceView()

    public private(set) lazy var configNotificator = NotificationCenter()

    public static let info = AppInfo(
            identifier: "com.stells.batch.transform"
            , version: "1.0"
            , state: .release
            , appType: TransformApp.self
            , displayName: "Transform"
            , icon: "Transform.App.Icon"
            , policy: AppPolicy.default
    )
}

private extension TransformApp{

//TODO: more simple way!
    @objc func horizontalFlipButtonDidTap() {
        self.configNotificator.post(name: ConfigurableAppNotification.didChange, object: nil,
                userInfo: [ConfigurableAppNotification.UserInfo.Key.configValue: HorizontalFlipTransformItem()])
    }

    @objc func verticalFlipButtonDidTap() {
        self.configNotificator.post(name: ConfigurableAppNotification.didChange, object: nil,
                userInfo: [ConfigurableAppNotification.UserInfo.Key.configValue: VerticalFlipTransformItem()])
    }

    @objc func rotationLeftButtonDidTap() {
        self.configNotificator.post(name: ConfigurableAppNotification.didChange, object: nil,
                userInfo: [ConfigurableAppNotification.UserInfo.Key.configValue: RotationTransformItem(degrees: -90)])
    }

    @objc func rotationRightButtonDidTap() {
        self.configNotificator.post(name: ConfigurableAppNotification.didChange, object: nil,
                userInfo: [ConfigurableAppNotification.UserInfo.Key.configValue: RotationTransformItem(degrees: 90)])
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
//            case .black:
//                config1.tintColor = .white
//                config2.tintColor = .white
//                config3.tintColor = .white
//                config4.tintColor = .white
//            default:
//                config1.tintColor = .black
//                config2.tintColor = .black
//                config3.tintColor = .black
//                config4.tintColor = .black
//        }

        config1.tintColor = .black
        config2.tintColor = .black
        config3.tintColor = .black
        config4.tintColor = .black

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
