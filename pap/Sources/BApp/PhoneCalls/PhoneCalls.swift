//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import FirebaseMLVision
import DefaultsKit

private typealias PhoneCallsAppParam = PHAssetItem<ImageEditStateValue>
private struct PhoneCallsAppResult: AppTaskResultable {
    fileprivate let asset:PHAsset

    init(asset:PHAsset){
        self.asset = asset
    }

    //INFO: Array means "Blocks"
    fileprivate var phoneNumbers:[VisionTextPhoneNumberParser.OutputType]?
    fileprivate var emails:[VisionTextEmailAddressParser.OutputType]?
    fileprivate var addresses:[VisionTextAddressParser.OutputType]?
}

private protocol PhoneCallsAppDefaults: AppDefaults{

}

extension Defaults: PhoneCallsAppDefaults {

}

public class PhoneCallsApp: NSObject, KeyPathWatchable, BApp
        , FinalizableApp
        , AppDockApp
        , PhotoPickerViewControllerDelegatableApp
        , PreheatableApp
//        , PreviewableApp
        , InterplayableApp {

    public static let taskType: AppTaskable.Type = _PhoneCallsAppTask.self

    public static let paramType: AppTaskParamable.Type = PHAssetItem<ImageEditStateValue>.self

    public private(set) lazy var dockContent: AppDockContent? = PhoneCallsAppDockContent()

    private let appDefaults = PhoneCallsApp.defaults as! PhoneCallsAppDefaults

    @objc dynamic
    public fileprivate (set) lazy var autoSelect: Bool = false

    public static let info = AppInfo(
            identifier: "com.stells.pap.phonecalls"
            , version: "1.0"
            , phase: .release
            , appType: PhoneCallsApp.self
            , displayName: "Phone Calls".localized, description:nil, keywords:nil
            , iconBundleName: R.image.phoneCallsBAppIcon.name
            , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: AppTaskPolicy.default)
            , minOSVersion: nil
    )

    public required override init() {

    }

//    static var callProviderDelegate:CallProviderDelegate?
    class func didConfigurate(with manager: AppManager) {
//        callProviderDelegate = CallProviderDelegate(callManager: CallManager.shared)
    }

    func willSelect(current: App.Type?) {
    }

    func didSelect(previous: App.Type?) {
    }

    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.showActions]
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.mediaType == .image
    }

    fileprivate var preheatedResults = [String:PhoneCallsAppResult]()
    public func performPreheating(item: AppAsset, _ async: AsyncWaitSignalable) -> PreheatingFinishAction? {
        if self.autoSelect == false{
            return nil
        }

        var preheatedResult:PhoneCallsAppResult? = preheatedResults[item.asset.localIdentifierWithoutSplitter]
        if preheatedResult == nil, let image = item.asset.asUIImage{
            preheatedResult = self.detector.detectResult(asset: item.asset, image: image, async) ?? PhoneCallsAppResult(asset: item.asset)
            preheatedResults[item.asset.localIdentifierWithoutSplitter] = preheatedResult
        }

        if preheatedResult?.phoneNumbers?.count ?? 0 > 0{
            return UICollectionViewPreheatableAppFinishAction.selectItem
        }

        return nil
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncWaitSignalable) -> [AppTaskRespondable] {

        let items = result
                .filter { respondable in respondable.info.state == .completed }
                .compactMap {
                    $0.result as? PhoneCallsAppResult
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

                            if ContactsUtil.shared.isCapableToCall, let url = URL(string: "tel://\(phoneNumber)") {
                                asyncSignal.end()

                                if #available(iOS 10, *) {
                                    UIApplication.shared.open(url)
                                } else {
                                    UIApplication.shared.openURL(url)
                                }
                            }else{
                                UIActivityViewController.share(activityItems: [phoneNumber]) { type, b, anies, error in
                                    asyncSignal.end()
                                }
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
                UIViewController.root?.present(alert, animated: true)
            }

            asyncSignal.waitUntilEnd()

        }else{

            asyncSignal.begin()
            DispatchQueue.main.async {
                UIAlertController.alert(AppMsg.cannot.detect.information, completion:{ _ in
                    asyncSignal.end()
                })
            }
            asyncSignal.waitUntilEnd()

        }

        return result
    }

    public var titleWillBegin: String? {
        return "🔍 Starting To Find ...".localized
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

    fileprivate var detector = PhoneCallsAppDetector()
}

private struct PhoneCallsAppDetector{

    private let vision = Vision.vision()

    fileprivate func detectResult(asset:PHAsset, image: UIImage, _ async: AsyncWaitSignalable) -> PhoneCallsAppResult? {
        guard let visionTexts = vision.textDetector().detect(with: image, async) else {
            return nil
        }

        var result = PhoneCallsAppResult(asset: asset)
        result.phoneNumbers = visionTexts.parse(type: VisionTextPhoneNumberParser.self, async)
//        result.emails = visionTexts.parse(type: VisionTextEmailAddressParser.self, async)
//        result.addresses = visionTexts.parse(type: VisionTextAddressParser.self, async)
        return result
    }
}

private class _PhoneCallsAppTask: AppTaskPrototypeDefaultConcurrencyCountPolicy, AppTaskable {

    private let emailParser = VisionTextEmailAddressParser()
    private let phoneNumberParser = VisionTextPhoneNumberParser()

    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){}

    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {

        guard let asset = (param as? PHAssetItem<ImageEditStateValue>)?.asset else{
            return nil
        }

        if let preheatedResults = AppCenter.default.currentInstanceAs(PhoneCallsApp.self)?.preheatedResults
        , let result = preheatedResults[asset.localIdentifierWithoutSplitter] {
            return result

        }else if let image = asset.asUIImage{

            let detector = AppCenter.default.currentInstanceAs(PhoneCallsApp.self)?.detector
            return detector?.detectResult(asset: asset, image: image, async)
        }

        return nil
    }
}


fileprivate class PhoneCallsAppDockContent: NSObject, KeyPathWatchable,
        AppDockContent, UITableViewDelegate, UITableViewDataSource{
    private lazy var defaults = PhoneCallsApp.defaults as! PhoneCallsAppDefaults

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
            view.register(Cell.self, forCellReuseIdentifier: PhoneCallsApp.info.identifier)
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
        return section == 0 ? "🖼️ ‣ 🤖 ‣ 📞" + "Select Photos You Want To Grab Phone Numbers!".localized : nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PhoneCallsApp.info.identifier) as! Cell

        cell.imageView?.tintColor = primaryColor
        cell.imageView?.contentMode = .scaleAspectFit

        cell.textLabel?.text = "Enable Auto Selection".localized
        cell.optionSwitch.setOn(self.autoSelect, animated: false)
        cell.switchDidChange = { on in
            self.autoSelect = on
            AppCenter.default.currentInstanceAs(PhoneCallsApp.self)?.autoSelect = on
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
