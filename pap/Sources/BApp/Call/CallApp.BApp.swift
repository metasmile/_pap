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

    init(asset:PHAsset){
        self.asset = asset
    }

    //INFO: Array means "Blocks"
    fileprivate var phoneNumbers:[VisionTextPhoneNumberParser.OutputType]?
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
        , PreheatableApp
//        , PreviewableApp
        , AppManagerDelegatedApp {

    public static let taskType:Taskable.Type = _CallAppTask.self

    public static let paramType:TaskParamable.Type = PHAssetItem<ImageEditStateValue>.self

    public private(set) lazy var dockContent: AppDockContent? = CallAppDockContent()

    private let appDefaults = CallApp.defaults as! CallAppDefaults

    @objc dynamic
    public fileprivate (set) lazy var autoSelect: Bool = false

    public static let info = AppInfo(
            identifier: "com.stells.pap.call"
            , version: "1.0"
            , phase: .release
            , appType: CallApp.self
            , displayName: "Call", description:nil, keywords:nil
            , iconBundleName: R.image.callBAppIcon.name
            , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: TaskPolicy(cancellation: .shallow, priority: .normal, estimatedConcurrencyCount: 1))
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

    fileprivate var preheatedResults = [String:CallAppResult]()
    public func performPreheating(item: AppAsset, _ async: AsyncSignal) -> PreheatingFinishAction? {
        if self.autoSelect == false{
            return nil
        }

        var preheatedResult:CallAppResult? = preheatedResults[item.asset.localIdentifierWithoutSplitter]
        if preheatedResult == nil, let image = item.asset.asUIImage{
            preheatedResult = self.detector.detectResult(asset: item.asset, image: image, async) ?? CallAppResult(asset: item.asset)
            preheatedResults[item.asset.localIdentifierWithoutSplitter] = preheatedResult
        }

        if preheatedResult?.phoneNumbers?.count ?? 0 > 0{
            return UICollectionViewPreheatableAppFinishAction.selectItem
        }

        return nil
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {

        let items = result
                .filter { respondable in respondable.info.state == .completed }
                .compactMap {
                    $0.result as? CallAppResult
                }
                .filter { result in
                    result.phoneNumbers?.count ?? 0 > 0
                }


        //TODO: wrap with something VO
        //TODO: if numbers and emails are in same block, maybe it is data of a person.

        var phoneNumberPool = Set<String>()

        let alert = UIAlertController(title: "Choose A Phone Number To Call".localized, message: nil, preferredStyle: .actionSheet)

        for item in items {

            for phoneNumberSetInBlock in item.phoneNumbers ?? []{

                for phoneNumber in phoneNumberSetInBlock where false == phoneNumberPool.contains(phoneNumber) && phoneNumber.count>0 {
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

        }else{

            asyncSignal.begin()
            DispatchQueue.main.async {
                UIAlertController.alert("Sorry not found any contact information.".localized, completion:{ _ in
                    asyncSignal.end()
                })
            }
            asyncSignal.waitUntilEnd()

        }

        return result
    }

    public var titleWillBegin: String? {
        return "Starting To Find ...".localized
    }

    public var titleWillFinalize: String? {
        return "Waiting To Select ...".localized
    }

    public func titleDidUpdate(progress: Float) -> String? {
        return "Finding Contacts ... %@ ".localizedFormatted("\(Int(progress * 100))%")
    }

    public var doneButtonTitle: String? {
        return "Find".localized
    }

    fileprivate var detector = CallAppDetector()
}

private struct CallAppDetector{

    private let vision = Vision.vision()

    fileprivate func detectResult(asset:PHAsset, image: UIImage, _ async: AsyncManualSignalable) -> CallAppResult? {
        guard let visionTexts = vision.textDetector().detect(with: image, async) else {
            return nil
        }

        var result = CallAppResult(asset: asset)
        result.phoneNumbers = visionTexts.parse(type: VisionTextPhoneNumberParser.self, async)
//        result.emails = visionTexts.parse(type: VisionTextEmailAddressParser.self, async)
//        result.addresses = visionTexts.parse(type: VisionTextAddressParser.self, async)
        return result
    }
}

private class _CallAppTask: TaskPrototype, Taskable {

    private let emailParser = VisionTextEmailAddressParser()
    private let phoneNumberParser = VisionTextPhoneNumberParser()

    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){}

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {

        guard let asset = (param as? PHAssetItem<ImageEditStateValue>)?.asset else{
            return nil
        }

        if let preheatedResults = AppCenter.default.currentInstanceAs(CallApp.self)?.preheatedResults
        , let result = preheatedResults[asset.localIdentifierWithoutSplitter] {
            return result

        }else if let image = asset.asUIImage{

            let detector = AppCenter.default.currentInstanceAs(CallApp.self)?.detector
            return detector?.detectResult(asset: asset, image: image, async)
        }

        return nil
    }
}


fileprivate class CallAppDockContent: NSObject, KeyPathWatchable,
        AppDockContent, UITableViewDelegate, UITableViewDataSource{
    private lazy var defaults = CallApp.defaults as! CallAppDefaults

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

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "🖼️ ‣ 🔍 ‣ ☎️ " + "Select Photos You Want To Grab Phone Numbers!".localized : nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CallApp.info.identifier) as! Cell

        cell.imageView?.tintColor = primaryColor
        cell.imageView?.contentMode = .scaleAspectFit

        cell.textLabel?.text = "Enable Auto Selection".localized
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
