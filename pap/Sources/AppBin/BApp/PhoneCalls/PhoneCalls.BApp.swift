//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import FirebaseMLVision
import PropertyKit
import Contacts
import ContactsUI

private typealias PhoneCallsAppParam = AppAsset
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

public class PhoneCallsApp: NSObject, PropertyWatchable, BApp
        , FinalizableApp
        , AppDockApp
        , PhotoPickerViewControllerDelegatableApp
        , PhotoPickerCollectionViewDisplayableApp
        , PreheatableApp
        , EditableApp
        , LaunchableApp {

    public static let taskType: AppTaskable.Type = _PhoneCallsAppTask.self

    public static let paramType: AppTaskParamable.Type = AppAsset.self

    public private(set) lazy var content: AppDockContent? = PhoneCallsAppDockContent()

    private let appDefaults = PhoneCallsApp.defaults as! PhoneCallsAppDefaults

    @objc dynamic
    public fileprivate (set) lazy var autoSelect: Bool = false

    public static let info = AppInfo(
            identifier: "com.stells.pap.phonecalls"
            , version: "1.0"
            , phase: .release
            , appType: PhoneCallsApp.self
            , displayName: "Phone Calls".localized
            , description:"Phone Calls lets you grab phone numbers accurately in your numerous photos. Then you merely start calling!"
            , keywords: ["Phone", "Call", "Numbers", "Address", "Contact"]
            , iconBundleName: R.image.phoneCallsBAppIcon.name
            , policy: AppPolicy.default
//            , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: AppTaskPolicy.default)
            , minOSVersion: nil
    )

    public required override init() {

    }

//    static var callProviderDelegate:CallProviderDelegate?
    class func didConfigure(with manager: AppManager) {
//        callProviderDelegate = CallProviderDelegate(callManager: CallManager.shared)
    }


    func didResign(current: App.Type?) {
        self.detector.reassignDetector()
        self.didCancelPreheating()
    }

    private var importedLaunchOption: AppLaunchOptions?
    func didLaunch(previous: App.Type?, withOption: AppLaunchOptions?) {
        importedLaunchOption = withOption
    }

    public func shouldSelectWhenInserted(indexPaths: [IndexPath]?) -> [IndexPath]? {
        if let _ = importedLaunchOption{
            return indexPaths
        }
        return nil
    }

    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.showActions]
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.mediaType == .image
    }

    public func performPreheating(item: PHAssetParamable,  _ async: AsyncWaitSignalable)  -> PreheatingFinishAction? {
        if self.autoSelect == false{
            return nil
        }

        (content as? PreheatableAppSubscribable)?.didStartPreheating()

        if self.detector.detectResult(asset: item.asset, async)?.phoneNumbers?.count ?? 0 == 0{
            return nil
        }

        return UICollectionViewPreheatableAppFinishAction.selectItem
    }

    public func didCancelPreheating() {
        (content as? PreheatableAppSubscribable)?.didStopPreheating()
    }

    public func didFinishCurrentPreheatingCycle() {
        (content as? PreheatableAppSubscribable)?.didStopPreheating()
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


        let alert = UIAlertController.actionSheet(title: "Choose A Phone Number To Call".localized, message: nil)

        let numbers = Array(Set(items.compactMap { (result: PhoneCallsAppResult) -> [String]? in
            return result.phoneNumbers?.reduce([],+)
        }.reduce([],+)))

        if numbers.count > 0{
            alert.addAction(UIAlertAction(title: "Save All Phone Numbers".localized, style: . default, handler: { action in
                DispatchQueue.global(qos: .userInteractive).async {
                    if ContactsUtil.shared.requestAuthorizationAndWait(AsyncSignal()) {

                        let contact = CNMutableContact()
                        contact.contactType = .person
                        contact.givenName = "New Phone Number".localized

                        for number in numbers{
                            let value = CNLabeledValue(label: "New Phone Number".localized, value: CNPhoneNumber(stringValue: number))
                            contact.phoneNumbers.append(value)
                        }

                        DispatchQueue.main.async {
                            CNContactViewController.presentDialog(newContact: contact)
                        }

                        asyncSignal.end()
                    }
                }
            }))
        }

        for phoneNumber in numbers {

            alert.addAction(UIAlertAction(title: phoneNumber, style: . default, handler: { action in

                DispatchQueue.main.async {

                    if let url = URL(string: "tel://\(phoneNumber)")
                        , ContactsUtil.shared.isCapableToCall
                        , UIApplication.shared.canOpenURL(url) {

                        asyncSignal.end()

                        if #available(iOS 10, *) {
                            UIApplication.shared.open(url)
                        } else {
                            UIApplication.shared.openURL(url)
                        }

                    }else if ContactsUtil.shared.requestAuthorizationAndWait(asyncSignal) {
                        asyncSignal.end()

                        let contact = CNMutableContact()
                        contact.contactType = .person
                        contact.givenName = "New Phone Number".localized
                        for number in [phoneNumber]{
                            let value = CNLabeledValue(label: "New Phone Number".localized, value: CNPhoneNumber(stringValue: number))
                            contact.phoneNumbers.append(value)
                        }

                        CNContactViewController.presentDialog(newContact: contact)

                    } else{
                        UIActivityViewController.share(activityItems: [phoneNumber]) { type, b, anies, error in
                            asyncSignal.end()
                        }
                    }
                }
            }))

        }

        if alert.actions.count > 0{
            alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { action in
                asyncSignal.end()
            }))

            asyncSignal.begin()

            DispatchQueue.main.async{
                UIViewController.present(alert, animated: true)
            }

            asyncSignal.waitUntilEnd()

        }else{

            asyncSignal.begin()
            DispatchQueue.main.async {
                UIAlertController.alert(AppStrings.cannot.detect.information, completion:{ _ in
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

private class _PhoneCallsAppTask: AppTaskPrototypeDefaultRestrictedConcurrency, AppTaskable {

    private let emailParser = VisionTextEmailAddressParser()
    private let phoneNumberParser = VisionTextPhoneNumberParser()

    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){
        AppCenter.default.currentInstanceAs(PhoneCallsApp.self)?.detector.cancelDetecting(async)
    }

    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        guard let asset = (param as? AppAsset)?.asset else{
            return nil
        }

        let detector = AppCenter.default.currentInstanceAs(PhoneCallsApp.self)?.detector
        return detector?.detectResult(asset: asset, async)
    }
}

enum PhoneCallsAppCells{
    case autoSelect
    case takePhoto
}

fileprivate class PhoneCallsAppDockContent: NSObject, PropertyWatchable,
        AppDockContent, UITableViewDelegate, UITableViewDataSource{

    fileprivate var settingCellDescribers = [UITableViewCellDefaultDescribable]()

    private lazy var defaults = PhoneCallsApp.defaults as! PhoneCallsAppDefaults

    private let primaryColor = UIColor(red:0.27, green:0.82, blue:0.35, alpha:1)

    lazy var view: UIView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tintColor = primaryColor
        return tableView
    }()

    private var autoSelect:Bool = false

    var preferences: AppDockContentPreferable? {
        guard let tableView = self.view as? UITableView else{
            return nil
        }

        var preferences = AppDockContentPreferences()
        let view = tableView
        preferences.preferredHeight = CGFloat(view.numberOfRows(inSection: 0))*view.rowHeight + 50
        return preferences
    }

    func willSetContentView(_ view: UIView, dock: AppDock) {

        if settingCellDescribers.count>0{
            return
        }

        let cell1 = UITableViewSwitchSubtitleCellDescriber()
        cell1.itemIdentifier = PhoneCallsAppCells.autoSelect.hashValue
        cell1.label = "Auto Selection Bot".localized
        cell1.valueGetter = { self.autoSelect }
        cell1.iconImage = R.image.commonCellIconRobot.name
        cell1.valueHandler = { on in
            let enable = (on as? Bool) ?? false
            self.autoSelect = enable
            AppCenter.default.currentInstanceAs(PhoneCallsApp.self)?.autoSelect = enable
        }
        settingCellDescribers.append(cell1)


        let cell_b = UITableViewButtonCellDescriber()
        cell_b.itemIdentifier = PhoneCallsAppCells.takePhoto.hashValue
        cell_b.label = "Take A Photo".localized
        cell_b.buttonImage = R.image.systemIconCamera.name
        cell_b.valueHandler = { _ in
            var option = AppLaunchOptions()
            option.identifierToReturn = PhoneCallsApp.info.identifier
            AppCenter.default.openApp(identifier:CameraApp.info.identifier, options:option)

        }
        settingCellDescribers.append(cell_b)


        if let tableView = view as? UITableView{
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = 44
            tableView.allowsSelection = false
            tableView.allowsMultipleSelection = false
            tableView.register(Cell.self, forCellReuseIdentifier: FinderApp.info.identifier)

            for desc in settingCellDescribers {
                tableView.register(describer: desc)
            }
        }
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {
        if options != nil{
            (view as? UITableView)?.reloadData()
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
        return settingCellDescribers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return settings_tableView(tableView, cellForRowAt: indexPath)
    }

    func settings_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.settingCellDescribers[indexPath.item]

        if let cellDescriber = item as? UITableViewSwitchCellDescriber
        , let value = item.valueGetter() as? Bool
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSwitchCell {

            cell.textLabel?.text = item.label
            cell.detailTextLabel?.text = item.detailedLabel
            cell.switcher.setOn(value, animated: false)
            cell.switcher.onTintColor = self.view.tintColor
            if let image = item.iconImage?.asUIImage{
                cell.imageView?.image = image.withRenderingMode(.alwaysTemplate)
                cell.imageView?.tintColor = self.view.tintColor
            }
            cell.switchDidChange = item.valueHandler
            return cell
        }

        else if let cellDescriber = item as? UITableViewButtonCellDescriber
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewButtonCell {

            cell.textLabel?.text = item.label

            if let buttonAsImage = cellDescriber.buttonImage?.asUIImage{
                cell.buttonFrameInset = UIEdgeInsetsMake(5, 5, 5, 5)
                cell.button.setImage(buttonAsImage.withRenderingMode(.alwaysTemplate), for: .normal)

            }else if let buttonAsText = cellDescriber.buttonTitle {
                cell.button.setTitle(buttonAsText, for: .normal)
                cell.button.setTitleColor(self.view.tintColor, for: .selected)
                cell.button.setTitleColor(self.view.tintColor, for: .highlighted)
            }
            cell.button.tintColor = self.view.tintColor
            cell.imageView?.image = item.iconImage?.asUIImage?.withRenderingMode(.alwaysTemplate)
            cell.imageView?.tintColor = self.view.tintColor
            cell.didTap = {
                cellDescriber.valueHandler?(true)
            }
            cell.button.layoutIfNeeded()
            return cell
        }

        else if let cellDescriber = item as? UITableViewStepperCellDescriber
        , let value = item.valueGetter() as? Int
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewStepperCell {

            cell.textLabel?.text = item.label
            cell.detailTextLabel?.text = cellDescriber.valuePresenter?(value) ?? String(value)
            cell.imageView?.image = item.iconImage?.asUIImage

            cell.stepper.stepValue = cellDescriber.stepValue
            cell.stepper.minimumValue = cellDescriber.minimumValue
            cell.stepper.maximumValue = cellDescriber.maximumValue
            cell.stepper.value = Double(value)

            cell.didChangeValue = { value in
                cell.detailTextLabel?.text = cellDescriber.valuePresenter?(value) ?? String(Int(value))
                item.valueHandler?(value)
            }
            return cell
        }

        else if let cellDescriber = item as? UITableViewSegmentControlCellDescriber
        , let valueCollection = cellDescriber.valueCollection as? [(String, Int)]
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSegmentedControlCell{

            cell.textLabel?.text = item.label
            cell.imageView?.image = item.iconImage?.asUIImage

            cell.segmentedControl.removeAllSegments()

            for (label, _) in valueCollection{
                cell.segmentedControl.insertSegment(withTitle: label, at: cell.segmentedControl.numberOfSegments, animated: false)
            }

            cell.segmentedControl.selectedSegmentIndex = valueCollection.index { t in
                t.1 == (item.valueGetter() as! Int)
            } ?? 0

            cell.didChangeValue = item.valueHandler
            return cell
        }

        let cell = tableView.cellForRow(at: indexPath) ?? UITableViewCell()
        cell.textLabel?.text = item.label
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


extension PhoneCallsAppDockContent: PreheatableAppSubscribable{
    func prepareStatusDisplaying(label:String?){
        var desc = self.settingCellDescribers.first { describable in
            describable.itemIdentifier == PhoneCallsAppCells.autoSelect.hashValue
        }
        desc?.detailedLabel = label
    }

    func didStartPreheating() {
        prepareStatusDisplaying(label: "Activating Current Visible Items ...".localized)
        self.startSelectionBotIconAnimation(self.settingCellDescribers, PhoneCallsAppCells.autoSelect.hashValue)
    }

    func didStopPreheating() {

        prepareStatusDisplaying(label: self.autoSelect ? "On Standby".localized : nil)
        self.stopSelectionBotIconAnimation(self.settingCellDescribers, PhoneCallsAppCells.autoSelect.hashValue)
    }

}