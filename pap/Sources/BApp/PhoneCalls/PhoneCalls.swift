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
        , LaunchableApp {

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
            , policy: AppPolicy.default
//            , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: AppTaskPolicy.default)
            , minOSVersion: nil
    )

    public required override init() {

    }

//    static var callProviderDelegate:CallProviderDelegate?
    class func didConfigurate(with manager: AppManager) {
//        callProviderDelegate = CallProviderDelegate(callManager: CallManager.shared)
    }


    func didResign(current: App.Type?) {
        self.detector.reassignDetector()
    }

    func didLaunch(previous: App.Type?, withOption: AppLaunchOption?) {

    }

    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.showActions]
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.mediaType == .image
    }

    public func performPreheating(item: AppAsset, _ async: AsyncWaitSignalable) -> PreheatingFinishAction? {
        if self.autoSelect == false{
            return nil
        }

        if self.detector.detectResult(asset: item.asset, async)?.phoneNumbers?.count ?? 0 == 0{
            return nil
        }

        return UICollectionViewPreheatableAppFinishAction.selectItem
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

    fileprivate lazy var detector = PhoneCallsAppDetector()
}

private class PhoneCallsAppDetector{

    private var cachedResults = [String:PhoneCallsAppResult]()

    private let vision = Vision.vision()

    private lazy var visionDetector:VisionTextDetector = vision.textDetector()

    private var imageRequestIds = [PHImageRequestID]()

    private lazy var imageRequestOptions:PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        return options
    }()

    fileprivate func reassignDetector(){
        visionDetector = vision.textDetector()
    }

    fileprivate func cancelDetecting(_ async: AsyncWaitSignalable){
        DispatchQueue.mainAsyncIfNot {
            self.imageRequestIds.forEach { id in
                PHImageManager.default().cancelImageRequest(id)
            }
            self.imageRequestIds = [PHImageRequestID]()
        }
    }

    fileprivate func detectResult(asset:PHAsset, _ async: AsyncWaitSignalable) -> PhoneCallsAppResult? {
        if let cachedResults = cachedResults[asset.localIdentifier]{
            return cachedResults
        }

        //TODO: compare with max image .. hmm not too different
        var image: UIImage? = nil
        let id = PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width:1000,height:1000), contentMode: .aspectFit, options: self.imageRequestOptions) { _image, dictionary in
            image = _image
        }
        imageRequestIds.append(id)

        guard let targetImage = image else {
            return nil
        }

        let visionTexts = visionDetector.detect(with: targetImage, async)

        var result = PhoneCallsAppResult(asset: asset)
        result.phoneNumbers = visionTexts?.parse(type: VisionTextPhoneNumberParser.self, async)
        cachedResults[asset.localIdentifier] = result

        return result
    }
}

private class _PhoneCallsAppTask: AppTaskPrototypeDefaultConcurrencyCountPolicy, AppTaskable {

    private let emailParser = VisionTextEmailAddressParser()
    private let phoneNumberParser = VisionTextPhoneNumberParser()

    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){
        AppCenter.default.currentInstanceAs(PhoneCallsApp.self)?.detector.cancelDetecting(async)
    }

    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        guard let asset = (param as? PHAssetItem<ImageEditStateValue>)?.asset else{
            return nil
        }

        let detector = AppCenter.default.currentInstanceAs(PhoneCallsApp.self)?.detector
        return detector?.detectResult(asset: asset, async)
    }
}


fileprivate class PhoneCallsAppDockContent: NSObject, KeyPathWatchable,
        AppDockContent, UITableViewDelegate, UITableViewDataSource{
    private lazy var defaults = PhoneCallsApp.defaults as! PhoneCallsAppDefaults

    private let primaryColor = UIColor(red:0.27, green:0.82, blue:0.35, alpha:1)

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
        return section == 0 ? "Select Photos You Want To Grab Phone Numbers!".localized : nil
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
