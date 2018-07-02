//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import FirebaseMLVision
import DefaultsKit
import Contacts


private typealias PixNoteParam = PHAssetItem<ImageEditStateValue>
private struct PixNoteResult: TaskResultable{
    fileprivate let asset:PHAsset

    init(asset:PHAsset){
        self.asset = asset
    }

    fileprivate var plainText:String?

    fileprivate var contacts:[VisionTextContactParser.OutputType]?

    fileprivate var resultGroup: VisionTextResultGroup?

//    //INFO: Array means "Blocks"
//    fileprivate var phoneNumbers:[VisionTextPhoneNumberParser.OutputType]?
//    fileprivate var emails:[VisionTextEmailAddressParser.OutputType]?
//    fileprivate var addresses:[VisionTextAddressParser.OutputType]?
//
//    fileprivate var dates:[VisionTextDateParser.OutputType]?
//    fileprivate var urls:[VisionTextURLParser.OutputType]?
//    fileprivate var flights:[VisionTextFlightInformationParser.OutputType]?
}

public class PixNote: NSObject, KeyPathWatchable, BApp
        , FinalizableApp
        , AppDockApp
        , PhotoPickerViewControllerDelegatableApp
        , PreheatableApp
        , AppManagerDelegatedApp {

    public static let taskType:Taskable.Type = _PixNoteTask.self

    public static let paramType:TaskParamable.Type = PHAssetItem<ImageEditStateValue>.self

    public private(set) lazy var dockContent: AppDockContent? = PixNoteAppDockContent()

    fileprivate static let privateDefaults = PixNote.defaults as! PixNoteAppDefaults

    @objc dynamic
    public lazy var autoSelect: Bool = false

    public static let info = AppInfo(
            identifier: "com.stells.pap.pixnote"
            , version: "0.1"
            , phase: .develop
            , appType: PixNote.self
            , displayName: "Pix Note", description:nil, keywords:nil
            , iconBundleName: nil//R.image.pixNoteBAppIcon.name
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

    fileprivate var preheatedResults = [String:PixNoteResult]()
    public func performPreheating(item: AppAsset, _ async: AsyncSignal) -> PreheatingFinishAction? {
        if self.autoSelect == false{
            return nil
        }

        var preheatedResult:PixNoteResult?

        if let result = preheatedResults[item.asset.localIdentifierWithoutSplitter]{
            preheatedResult = result
        }else{
            if let image = item.asset.asUIImage{
                preheatedResult = self.detector.detectResult(asset: item.asset, image: image, async) ?? PixNoteResult(asset: item.asset)
                preheatedResults[item.asset.localIdentifierWithoutSplitter] = preheatedResult
            }
        }

        return PixNoteDetector.isResultFilled(result: preheatedResult)
                ? UICollectionViewPreheatableAppFinishAction.selectItem
                : nil
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        let items = result
                .filter { $0.info.state == .completed }
                .compactMap { $0.result as? PixNoteResult }

        switch (PixNote.privateDefaults.selectionPreset){
            case SelectionPreset.plaintext.rawValue:
                self.finalize_plaintext(items: items, asyncSignal)
            case SelectionPreset.contact.rawValue:
                self.finalize_contact(items: items, asyncSignal)
            case SelectionPreset.action.rawValue:
                self.finalize_action(items: items, asyncSignal)
            default:
                assert(false, "not supported preset \(String(describing: PixNote.privateDefaults.selectionPreset))")
        }

        return result

    }

    public var titleWillBegin: String? {
        return "Starting To Grab ...".localized
    }

    public var titleWillFinalize: String? {
        return "Waiting To Select ...".localized
    }

    public func titleDidUpdate(progress: Float) -> String? {
        return "Grabbing Text Contents ... %@ ".localizedFormatted("\(Int(progress * 100))%")
    }

    public var doneButtonTitle: String? {
        return "Grab".localized
    }

    fileprivate var detector = PixNoteDetector()
}

extension PixNote{

    fileprivate func finalize_plaintext(items: [PixNoteResult], _ asyncSignal: AsyncManualSignalable) {
        let strings = items.compactMap{ $0.plainText }

        if strings.count > 0 {
            asyncSignal.begin()
            DispatchQueue.main.async{
                UIActivityViewController.presentAsDefault(activityItems: strings, excludedActivityTypes: nil) { _,_,_,_ in
                    asyncSignal.end()
                }
            }
            asyncSignal.waitUntilEnd()
        }
    }

    fileprivate func finalize_contact(items: [PixNoteResult], _ asyncSignal: AsyncManualSignalable) {
        var contacts = [CNMutableContact]()
        for item in items {
            guard let _contacts = item.contacts, _contacts.count > 0 else{
                continue
            }
            for c in _contacts{
                contacts.append(contentsOf: c)
            }
        }

        var canSaveContract = false

        asyncSignal.begin()
        ContactManager.default.authorizationStatus { status in
            /*
            /*! The user has not yet made a choice regarding whether the application may access contact data. */
            case notDetermined

            /*! The application is not authorized to access contact data.
             *  The user cannot change this application’s status, possibly due to active restrictions such as parental controls being in place. */
            case restricted

            /*! The user explicitly denied access to contact data for the application. */
            case denied

            /*! The application is authorized to access contact data. */
            case authorized
            */

            if status == CNAuthorizationStatus.notDetermined{
                ContactManager.default.requestAccess { granted in
                    canSaveContract = granted
                    asyncSignal.end()
                }
            }
            else if status == CNAuthorizationStatus.authorized{
                canSaveContract = true
                asyncSignal.end()

            }else{
                DispatchQueue.main.async{
                    UIAlertController.alert("It requires a permission to access your contacts. Please allow Contacts on iOS Settings.".localized, completion: { action in
                        asyncSignal.end()
                    })
                }
            }

        }
        asyncSignal.waitUntilEnd()

        if canSaveContract{

            asyncSignal.begin()
            ContactManager.default.addContacts(Contact: contacts) { result in
                asyncSignal.end()
            }
            asyncSignal.waitUntilEnd()

        }else{

            asyncSignal.begin()
            DispatchQueue.main.async {
                UIAlertController.alert("Sorry, it is not possible to save the contract.".localized, completion:{ _ in
                    asyncSignal.end()
                })
            }
            asyncSignal.waitUntilEnd()
        }
    }

    fileprivate func finalize_action(items: [PixNoteResult], _ asyncSignal: AsyncManualSignalable) {
        let alert = UIAlertController(title: "Choose An Action".localized, message: nil, preferredStyle: .actionSheet)

        for item in items {

            guard let resultGroup = item.resultGroup else{
                continue
            }

            // Phone Number
            for phoneNumberSetInBlock in resultGroup.phoneNumbers ?? []{

                var phoneNumberPool = Set<String>()
                for phoneNumber in phoneNumberSetInBlock where false == phoneNumberPool.contains(phoneNumber) && phoneNumber.count>0 {
                    phoneNumberPool.insert(phoneNumber)

                    let action = UIAlertAction(title: phoneNumber, style: . default, handler: { action in

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
                    })
                    action.accessoryImage = R.image.exifGhostBAppIcon()

                    alert.addAction(action)
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
    }

}

private struct PixNoteDetector{

    private let vision = Vision.vision()

    fileprivate static func isResultFilled(result:PixNoteResult?) -> Bool{
        let preset = PixNote.privateDefaults.selectionPreset

        if preset == SelectionPreset.plaintext.rawValue{
            return result?.plainText?.count ?? 0 > 0
        }

        if preset == SelectionPreset.action.rawValue{
            return result?.resultGroup?.isFilled == true
        }

        if preset == SelectionPreset.contact.rawValue{
            return result?.contacts?.count ?? 0 > 0
        }

        return false
    }


    fileprivate func detectResult(asset:PHAsset, image: UIImage, _ async: AsyncManualSignalable) -> PixNoteResult? {
        guard let visionTexts = vision.textDetector().detect(with: image, async) else {
            return nil
        }

        let preset = PixNote.privateDefaults.selectionPreset
        var result = PixNoteResult(asset: asset)

        // SelectionPreset.plaintext
        if preset == SelectionPreset.plaintext.rawValue{
            result.plainText = visionTexts.parse(type: VisionTextStringParser.self, async)?.joined()
        }

        // SelectionPreset.contact,  SelectionPreset.action
        else if preset == SelectionPreset.contact.rawValue {
            result.contacts = visionTexts.parse(type: VisionTextContactParser.self, async)
        }

        else if preset == SelectionPreset.action.rawValue{

            var result = PixNoteResult(asset: asset)
            var defaults = PixNote.privateDefaults
            let items = Set((defaults.selectedParserCollection.values).reduce([],+))

            var resultGroup = VisionTextResultGroup()

            if items.contains(ParserItem.Key.EmailAddress){
                resultGroup.emails = visionTexts.parse(type: VisionTextEmailAddressParser.self, async)
            }

            if items.contains(ParserItem.Key.PhoneNumber){
                resultGroup.phoneNumbers = visionTexts.parse(type: VisionTextPhoneNumberParser.self, async)
            }

            if items.contains(ParserItem.Key.URL){
                resultGroup.urls = visionTexts.parse(type: VisionTextURLParser.self, async)
            }

            if items.contains(ParserItem.Key.Address){
                resultGroup.addresses = visionTexts.parse(type: VisionTextAddressParser.self, async)
            }

            if items.contains(ParserItem.Key.FlightInformation){
                resultGroup.flights = visionTexts.parse(type: VisionTextFlightInformationParser.self, async)
            }

            result.resultGroup = resultGroup

        }else{
            assert(false, "current preset mode is not supported. \(String(describing: preset))")
            return nil
        }

        return result
    }
}

private class _PixNoteTask: TaskPrototype, Taskable {

    private let emailParser = VisionTextEmailAddressParser()
    private let phoneNumberParser = VisionTextPhoneNumberParser()

    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){}

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {

        guard let asset = (param as? PHAssetItem<ImageEditStateValue>)?.asset else{
            return nil
        }

        if let preheatedResults = AppCenter.default.currentInstanceAs(PixNote.self)?.preheatedResults
        , let result = preheatedResults[asset.localIdentifierWithoutSplitter] {
            return result

        }else if let image = asset.asUIImage{

            let detector = AppCenter.default.currentInstanceAs(PixNote.self)?.detector
            return detector?.detectResult(asset: asset, image: image, async)
        }

        return nil
    }
}


fileprivate class PixNoteDockContent: NSObject, KeyPathWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
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
            view.register(Cell.self, forCellReuseIdentifier: PixNote.info.identifier)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: PixNote.info.identifier) as! Cell

        cell.imageView?.tintColor = primaryColor
        cell.imageView?.contentMode = .scaleAspectFit

        cell.textLabel?.text = "Enable Auto Selection".localized
        cell.optionSwitch.setOn(self.autoSelect, animated: false)
        cell.switchDidChange = { on in
            self.autoSelect = on
            AppCenter.default.currentInstanceAs(PixNote.self)?.autoSelect = on
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


/*

AppContent

*/

private enum SelectionPreset:Int{
    case plaintext
    case contact
    case action
}

private enum Cells {
    case presets
    case autoSelect
    case delete
}

private struct SettingsItem {
    fileprivate var key: Cells
    fileprivate var label:String
    fileprivate var valueGetter:() -> Any
    fileprivate var valueCollection:Any?
    fileprivate var valueHandler:((Any) -> ())?
    fileprivate var cellDescriber: UITableViewCellDescribable //TODO: integrate all properties
    fileprivate var iconImageName:String?
}

private protocol PixNoteAppDefaults: AppDefaults{
    var selectedParserCollection: ParserCollection {get set}
    var selectionPreset: Int {get set}
}

extension Defaults: PixNoteAppDefaults {
    fileprivate var selectedParserCollection: ParserCollection {
        set{ set(newValue) }
        get{ return get(or: ParserDictionary.DefaultCollection) }
    }

    fileprivate var selectionPreset: Int {
        set{ set(newValue) }
        get{ return get(or: SelectionPreset.contact.rawValue ) }
    }
}


extension PixNoteAppDefaults{
    fileprivate func addHandledProperty(_ dictionary:ParserDictionary.Key, _ property:ParserItem.Key){

        var immutableSelf = self
        if immutableSelf.selectedParserCollection[dictionary] == nil{
            immutableSelf.selectedParserCollection = ParserCollection()
            var p = immutableSelf.selectedParserCollection
            p[dictionary] = [property]
            immutableSelf.selectedParserCollection = p
        }else{
            if selectedParserCollection[dictionary]?.contains(property) == false{
                var p = immutableSelf.selectedParserCollection
                p[dictionary]?.append(property)
                immutableSelf.selectedParserCollection = p
            }
        }
    }

    fileprivate func removeHandledProperty(_ dictionary:ParserDictionary.Key, _ property:ParserItem.Key){

        if let index = selectedParserCollection[dictionary]?.index(of: property){
            var immutableSelf = self
            var p = immutableSelf.selectedParserCollection
            p[dictionary]?.remove(at: index)
            immutableSelf.selectedParserCollection = p
        }
    }
}

private typealias ParserCollection = [ParserDictionary.Key: [ParserItem.Key]]

private struct ParserItem {
    enum Key: Int, Codable {
        case PhoneNumber
        case EmailAddress
        case Address

        case Date
        case URL
        case FlightInformation
    }

    fileprivate var key:Key
    fileprivate var label:String
}

private struct ParserDictionary {

    static let DefaultCollection: ParserCollection = [
        ParserDictionary.Key.Information: [
            ParserItem.Key.PhoneNumber
            ,ParserItem.Key.EmailAddress
            ,ParserItem.Key.Address

            ,ParserItem.Key.Date
            ,ParserItem.Key.URL
            ,ParserItem.Key.FlightInformation
        ]
    ]

    enum Key: Int, Codable {
        case Information
    }

    fileprivate var key:Key
    fileprivate var label:String
    fileprivate var items:[ParserItem]
}

class PixNoteAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource, UITableViewPickerCellDelegate{
    fileprivate var cellDescribers = [UITableViewCellDefaultDescribable]()

    private var parserCollection:[ParserDictionary] = [

        ParserDictionary(key: ParserDictionary.Key.Information, label: "Information".localized,
                items: [
                    ParserItem(key: ParserItem.Key.PhoneNumber, label:"Phone Number".localized)
                    ,ParserItem(key: ParserItem.Key.EmailAddress, label:"E-mail Address".localized)
                    ,ParserItem(key: ParserItem.Key.Address, label:"Address".localized)
                    ,ParserItem(key: ParserItem.Key.Date, label:"Date".localized)
                    ,ParserItem(key: ParserItem.Key.FlightInformation, label:"Flight Information".localized)
                    ,ParserItem(key: ParserItem.Key.URL, label:"URL".localized)
                ])
    ]

    required public override init() {
        super.init()
    }

    private var initialSelectedIndexPaths:[IndexPath]?

    lazy var view: UIView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tintColor = UIColor(red:0.13, green:0.15, blue:0.16, alpha:1)
        return tableView
    }()

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = 300
        return preferences
    }

    private var selectedParserCollection: ParserCollection{
        return PixNote.privateDefaults.selectedParserCollection
    }

    private var autoSelect:Bool = false


    func willSetContentView(_ view: UIView, dock: AppDock) {

        if cellDescribers.count>0{
            return
        }

        let cell1 = UITableViewSwitchCellDescriber()
        cell1.itemIdentifier = Cells.autoSelect.hashValue
        cell1.label = "Enable Auto Selection".localized
        cell1.valueGetter = { self.autoSelect }
        cell1.valueHandler = {
            self.autoSelect = $0 as! Bool
            AppCenter.default.currentInstanceAs(PixNote.self)?.autoSelect = self.autoSelect
        }
        cellDescribers.append(cell1)

        let cell0 = UITableViewSegmentControlCellDescriber()
        cell0.itemIdentifier = Cells.presets.hashValue
        cell0.label = "Grab As".localized
        cell0.valueGetter = { PixNote.privateDefaults.selectionPreset }
        cell0.valueCollection = [
            (label:"Plain Text",value: SelectionPreset.plaintext.rawValue),
            (label:"Contact",value: SelectionPreset.contact.rawValue),
            (label:"Action",value: SelectionPreset.action.rawValue)
        ]
        cell0.valueHandler = {
            let preset = $0 as! Int

            var defaults = PixNote.privateDefaults
            defaults.selectionPreset = preset

//            (view as? UITableView)?.performBatchUpdates({
//                if preset == GrabAs.plaintext.rawValue{
//                    for m in self.parserCollection {
//                        for i in m.items{
//                            PixNote.privateDefaults.addHandledProperty(m.key, i.key)
//                        }
//                    }
//                }else if preset == GrabAs.contact.rawValue{
//                    for m in self.parserCollection {
//                        for i in m.items{
//                            PixNote.privateDefaults.removeHandledProperty(m.key, i.key)
//                        }
//                    }
//                    for m in ParserDictionary.DefaultCollection {
//                        for i in m.value{
//                            PixNote.privateDefaults.addHandledProperty(m.key, i)
//                        }
//                    }
//                }
//                (view as? UITableView)?.reloadData()
//            }, completion:nil)

        }
        cellDescribers.append(cell0)

        if let tableView = view as? UITableView{
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = 44
            tableView.allowsSelection = false
            tableView.allowsMultipleSelection = false
            tableView.register(Cell.self, forCellReuseIdentifier: PixNote.info.identifier)

            for desc in cellDescribers {
                tableView.register(describer: desc)
            }
        }
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {

        let defaultsCollection = PixNote.privateDefaults.selectedParserCollection

        //get indexes
        let sections = self.parserCollection.enumerated().compactMap { (section, dictionary) -> [IndexPath]? in
            if let handledItems = defaultsCollection[dictionary.key]{

                return handledItems.compactMap { key -> IndexPath? in
                    guard let item = dictionary.items.index(where: { item -> Bool in
                        return key == item.key
                    }) else{
                        return nil
                    }
                    return IndexPath(item: item, section: 1+section)
                }
            }
            return nil
        }


        //init initialSelectedIndexPaths
        initialSelectedIndexPaths = [IndexPath]()
        for indexPaths in sections{
            initialSelectedIndexPaths?.append(contentsOf: indexPaths)
        }

        (view as! UITableView).reloadData()

        initialSelectedIndexPaths = nil
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }

    func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {

    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + parserCollection.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        let label_section0 = "🖼️ ‣ 🤖 ‣ 📝 " + "Select Photos You Want To Grab!".localized
        return section == 0 ? label_section0 : parserCollection[section-1].label
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? cellDescribers.count : parserCollection[section-1].items.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = indexPath.section == 0 ? settings_tableView(tableView, cellForRowAt: indexPath) : parserCollection_tableView(tableView, cellForRowAt: IndexPath(item: indexPath.item, section: indexPath.section))
        return cell
    }

    func settings_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.cellDescribers[indexPath.item]

        if let cellDescriber = item as? UITableViewPickerCellDescriber
        , let valueCollection = cellDescriber.valueCollection as? [String]
        , let cell: UITableViewPickerCell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewPickerCell {

            cell.values = valueCollection
            cell.delegate = self
            if let value = item.valueGetter() as? String ?? valueCollection.first, let index = valueCollection.index(of: value){
                cell.selectedRow = index
            } else{
                cell.selectedRow = 0
            }
            cell.titleLabel.text = item.label
            return cell

        }
        else if let cellDescriber = item as? UITableViewSwitchCellDescriber
        , let value = item.valueGetter() as? Bool
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSwitchCell {

            cell.textLabel?.text = item.label
            cell.switcher.setOn(value, animated: false)
            cell.switcher.onTintColor = self.view.tintColor
            cell.imageView?.image = item.iconImage?.asUIImage
            cell.switchDidChange = item.valueHandler
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

    func parserCollection_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let dict = self.parserCollection[indexPath.section-1]

        var selected = false
        if let _ = initialSelectedIndexPaths?.index(of: indexPath) {
            selected = true
        }
        if let _ = PixNote.privateDefaults.selectedParserCollection[dict.key]?.index(of: dict.items[indexPath.item].key){
            selected = true
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: PixNote.info.identifier) as! Cell
        cell.textLabel?.text = dict.items[indexPath.item].label
        cell.detailTextLabel?.text = selected ? "may be found" : nil
//        cell.imageView?.image = selected ? R.image.pdFactoryAppIcon() : nil //selected ? UIImageView(image: R.image.pdFactoryAppIcon()) : nil
        cell.detailTextLabel?.textColor = UIColor.gray
        cell.optionSwitch.setOn(selected, animated: false)
        cell.switchDidChange = { on in
            if on{
                PixNote.privateDefaults.addHandledProperty(dict.key, dict.items[indexPath.item].key)
            }else{
                PixNote.privateDefaults.removeHandledProperty(dict.key, dict.items[indexPath.item].key)
            }

            tableView.reloadRows(at: [indexPath], with: .fade)

//            let selectedPreset = PixNote.privateDefaults.selectionPreset
//
//            if selectedPreset == GrabAs.plaintext.rawValue || selectedPreset == GrabAs.contact.rawValue{
//                PixNote.privateDefaults.selectionPreset = GrabAs.action.rawValue
//
//                tableView.reloadSections(IndexSet(integer: 0), with: .none)
//            }

        }
        return cell
    }

    func pickerCell(_ cell: UITableViewPickerCell, didPick row: Int, value: Any) {

    }
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
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        accessoryView = optionSwitch
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func cellSwitchDidChange(sender: UISwitch) {
        switchDidChange?(sender.isOn)
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        optionSwitch.onTintColor = tintColor
    }
}

fileprivate extension UIAlertAction {

    var accessoryImage: UIImage? {
        get {
            if self.responds(to: Selector(Constants.imageKey)) {
                return self.value(forKey: Constants.imageKey) as? UIImage
            }
            return nil
        }
        set {
            if self.responds(to: Selector(Constants.imageKey)) {
                self.setValue(newValue, forKey: Constants.imageKey)
            }
        }
    }

    private struct Constants {
        static var imageKey = "image"
    }
}

