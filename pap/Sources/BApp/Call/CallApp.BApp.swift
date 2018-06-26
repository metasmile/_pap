//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import FirebaseMLVision
import DefaultsKit

private typealias CallAppParam = PHAssetItem<ImageEditStateValue>
private struct CallAppResult: TaskResultable{
    fileprivate let asset:PHAsset

    //INFO: Array means "Blocks"
    fileprivate let phoneNumbers:[VisionTextPhoneNumberParser.OutputType]
    fileprivate var emails:[VisionTextEmailAddressParser.OutputType]?
    fileprivate var addresses:[VisionTextAddressParser.OutputType]?
}

private protocol CallAppDefaults: AppDefaults{

}

extension Defaults: CallAppDefaults {

}

public class CallApp: NSObject, KeyPathWatchable, BApp
        , FinalizableApp
        , AppDockApp
        , PhotoPickerViewControllerDelegatableApp
        , PhotoPickerCollectionViewAsyncAutoDisplayableApp
        , AppManagerDelegate {

    public static let taskType:Taskable.Type = _CallAppTask.self

    public static let paramType:TaskParamable.Type = PHAssetItem<ImageEditStateValue>.self

    public private(set) lazy var dockContent: AppDockContent? = CallAppDockContent()

    private let appDefaults = CallApp.defaults as! CallAppDefaults

    @objc dynamic
    public fileprivate (set) lazy var autoSelect: Bool = false

    public static let info = AppInfo(
            identifier: "com.stells.pap.call"
            , version: "0.1"
            , phase: .develop
            , appType: CallApp.self
            , displayName: "Call", description:nil, keywords:nil
            , iconBundleName: R.image.callBAppIcon.name
            , policy: AppPolicy(lifeCycle: AppLifecyclePolicy.default, task: TaskPolicy(cancellation: .shallow, priority: .normal, estimatedConcurrencyCount: 1))
            , minOSVersion: nil
    )

    public required override init() {
    }

//    static var callProviderDelegate:CallProviderDelegate?
    class func didConfigurate(with manager: AppManager) {
//        callProviderDelegate = CallProviderDelegate(callManager: CallManager.shared)
    }

    func willSetCurrent(oldCurrent: App.Type?) {
    }

    func didSetCurrent(previous: App.Type?) {
    }

    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.showActions]
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.mediaType == .image
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {

        let items = result
                .filter { respondable in respondable.info.state == .completed }
                .compactMap { $0.result as? CallAppResult }
                .filter { result in
                    result.phoneNumbers.count>0
                }

        if items.count==0{

            asyncSignal.begin()
            DispatchQueue.main.async {
                UIAlertController.alert("Sorry not found any contact data.".localized, completion:{ _ in
                    asyncSignal.end()
                })
            }
            asyncSignal.waitUntilEnd()

        }else{

            //TODO: wrap with something VO
            //TODO: if numbers and emails are in same block, maybe it is data of a person.

            var phoneNumberPool = Set<String>()

            let alert = UIAlertController(title: "Choose A Phone Number To Call".localized, message: nil, preferredStyle: .actionSheet)

            for item in items {

                for phoneNumberSetInBlock in item.phoneNumbers{

                    for phoneNumber in phoneNumberSetInBlock where false == phoneNumberPool.contains(phoneNumber){
                        phoneNumberPool.insert(phoneNumber)

                        alert.addAction(UIAlertAction(title: phoneNumber, style: . default, handler: { action in

                            DispatchQueue.main.async {

                                if let url = URL(string: "tel://\(phoneNumber)"), UIApplication.shared.canOpenURL(url) {
                                    asyncSignal.end()
                                    
                                    if #available(iOS 10, *) {
                                        UIApplication.shared.open(url)
                                    } else {
                                        UIApplication.shared.openURL(url)
                                    }
                                }else{
                                    UIAlertController.alert("Sorry can't call to selected contact.".localized, completion:{ _ in
                                        asyncSignal.end()
                                    })
                                }
                            }
                        }))

                    }
                }
            }

            if alert.actions.count > 0{
                alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { action in
                    asyncSignal.end()
                }))

                asyncSignal.begin()

                DispatchQueue.main.async{
                    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
                }

                asyncSignal.waitUntilEnd()
            }

        }

        return result
    }

    public func shouldAutoSelectAsynchronously(item: AppAsset, _ async: AsyncSignal) -> PhotoPickerCollectionViewAsyncSelection {
        if self.autoSelect == false{
            return .none
        }

        if let image = item.asset.asUIImage {

            if let result = AppCenter.default.currentInstanceAs(CallApp.self)?.detectResult(asset: item.asset, image: image, async) {
                return result.phoneNumbers.count > 0 ? .visible : .none
            }
        }

        return .none
    }

    public var titleWillFinalize: String? {
        return "Pending To Connect ...".localized
    }

    public func titleDidUpdate(progress: Float) -> String? {
        return "Finding Contact Points ... %@ ".localizedFormatted("\(Int(progress * 100))%")
    }

    public var doneButtonTitle: String? {
        return "Find".localized
    }


    private var textDetector = Vision().textDetector() //TODO: decide 1-1 or 1-N ?

    fileprivate func detectResult(asset:PHAsset, image: UIImage, _ async: AsyncManualSignalable) -> CallAppResult? {
        let detector = textDetector

        guard let visionTexts = detector.detect(with: image, async) else {
            return nil
        }

        guard let phoneNumbers = visionTexts.parse(type: VisionTextPhoneNumberParser.self, async) else{
            return nil
        }

        let emailAddresses = visionTexts.parse(type: VisionTextEmailAddressParser.self, async)

        let addresses = visionTexts.parse(type: VisionTextAddressParser.self, async)

        return CallAppResult(asset: asset, phoneNumbers: phoneNumbers, emails: emailAddresses, addresses: addresses)
    }
}

private class _CallAppTask: TaskPrototype, Taskable {

    private let emailParser = VisionTextEmailAddressParser()
    private let phoneNumberParser = VisionTextPhoneNumberParser()

    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){}

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {

        guard let asset = (param as? PHAssetItem<ImageEditStateValue>)?.asset
        , let image = asset.asUIImage else {
            return nil
        }

        return AppCenter.default.currentInstanceAs(CallApp.self)?.detectResult(asset: asset, image: image, async)
    }
}


fileprivate class CallAppDockContent: NSObject, KeyPathWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    private lazy var defaults = CallApp.defaults as! CallAppDefaults

    private let primaryColor = UIColor(red:0.6, green:0.6, blue:0.6, alpha:1)

    lazy var view: UIView = UITableView()

    private var autoSelect:Bool = false

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = (view as! UITableView).rowHeight * CGFloat(1)
        return preferences
    }

    func willSetContentView(_ view: UIView, dock: AppDock) {
        if let view = view as? UITableView{
            view.dataSource = self
            view.delegate = self
            view.rowHeight = 52
            view.allowsSelection = false
            view.register(Cell.self, forCellReuseIdentifier: CallApp.info.identifier)
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CallApp.info.identifier) as! Cell

//        cell.imageView?.image = nil
        cell.imageView?.tintColor = primaryColor
        cell.imageView?.contentMode = .scaleAspectFit

        cell.textLabel?.text = "Enable Auto Selection".localized
        cell.textLabel?.textColor = primaryColor
        cell.optionSwitch.setOn(self.autoSelect, animated: false)
        cell.switchDidChange = { on in
            self.autoSelect = on
            AppCenter.default.currentInstanceAs(CallApp.self)?.autoSelect = on
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
//            backgroundColor = .clear
            textLabel?.font = UIFont.systemFont(ofSize: 14)
//            textLabel?.textColor = UIColor.white
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc func cellSwitchDidChange(sender: UISwitch) {
            switchDidChange?(sender.isOn)
        }

        override func layoutSubviews() {
            super.layoutSubviews()

//            imageView?.frame.size = CGSize(width: 30, height: 30)
//            imageView?.frame.origin = CGPoint(x: 10, y: (contentView.bounds.height - 30) / 2)

//            textLabel?.frame.origin.x = (imageView?.frame.maxX ?? 0) + 10
        }

        override func tintColorDidChange() {
            super.tintColorDidChange()

            optionSwitch.onTintColor = tintColor
        }
    }
}
