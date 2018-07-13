//
// Created by BLACKGENE on 27/03/2018.
// Copyrig?ht (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import DefaultsKit
import CocoaImageHashing
import MetalPerformanceShaders
import MetalKit
import Vision

private typealias CleanerAppParam = PHAssetItem<ImageEditStateValue>

struct PHAssetGCResult:AppTaskResultable {
    let asset:PHAsset
    let detected:[PHAssetGarbageDetector.Type]
}

private typealias PHAssetID = String

public class CleanerApp: NSObject, BApp, KeyPathWatchable, PHAssetFinalizableApp, AppDockApp, PhotoPickerViewControllerDelegatableApp, PreheatableApp {
    public static let taskType: AppTaskable.Type = _CleanerAppTask.self

    public static let paramType: AppTaskParamable.Type = PHAssetItem<ImageEditStateValue>.self

    public private(set) lazy var dockContent: AppDockContent? = CleanerAppDockContent()

    fileprivate static var privateDefaults = CleanerApp.defaults as! CleanerAppDefaults

    public static let info = AppInfo(
            identifier: "com.stells.pap.cleaner"
            , version: "0.1"
            , phase: .develop
            , appType: CleanerApp.self
            , displayName: "Cleaner".localized, description:nil, keywords:nil
            , iconBundleName: R.image.cleanerBAppIcon.name
            , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: AppTaskPolicy.default)
            , minOSVersion: nil
    )

    public required override init() {}

    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.showActions]
    }

    public var titleWillFinalize: String? {
        return "Cleaning Photos...".localized
    }

    public var doneButtonTitle: String? {
        return "Clean".localized
    }

    @objc dynamic
    public fileprivate (set) lazy var autoSelect: Bool = false

    fileprivate static var SupportingGDTypes:[PHAssetGarbageDetector.Type] = [
        PHAssetGarbageDetector_Similarity.self
//        , PHAssetGarbageDetector_BD.self
//        , PHAssetGarbageDetector_Blurry.self
        , PHAssetGarbageDetector_Screenshots.self
        , PHAssetGarbageDetector_Lockscreens.self
    ]

    /*
        gc
    */

    private var gdInstances = [String:PHAssetGarbageDetector]()

    func disposeGdInstance(identifier:String){
        gdInstances[identifier] = nil
    }

    fileprivate func gc(item: AppAsset, _ async: AsyncWaitSignalable) -> PHAssetGCResult {

        var detected = [PHAssetGarbageDetector.Type]()
        let gdType_Id = type(of: self).SupportingGDTypes.dictionary { $0.identifier }

        for gd in type(of: self).privateDefaults.selectedCollection{
            for gcItem in gd.items where gcItem.enabled{
                if let t = gdType_Id[gcItem.gdIdentifier]{
                    let k = t.identifier

                    var detector:PHAssetGarbageDetector
                    if let d = gdInstances[k]{
                        detector = d
                    }else{
                        detector = t.init()
                        gdInstances[k] = detector
                        print(k,detector)
                    }

                    autoreleasepool{
                        if detector.process(input: item.asset, async) ?? false == true{
                            detected.append(t)
                        }
                    }
                }
            }
        }

        return PHAssetGCResult(asset:item.asset, detected:detected)
    }

    /*
    preheat
    */
    fileprivate var preheatCachedResults = [PHAssetID: PHAssetGCResult]()
    private var preheatingFrontQueueLabel:String?

    func disposePreheatingCache(){
        if let l = preheatingFrontQueueLabel{
            DispatchQueue(label:l).async{
                self.preheatCachedResults.removeAll()
            }
        }else{
            preheatCachedResults.removeAll()
        }
    }

    public func performPreheating(item: AppAsset, _ async: AsyncWaitSignalable) -> PreheatingFinishAction? {
        guard self.autoSelect else { return nil }

        preheatingFrontQueueLabel = async.queueStack.first ?? DispatchQueue.currentLabel

        var result: PHAssetGCResult

        let selectedGdIds = type(of: self).privateDefaults.selectedCollection.compactMap { dictionary -> [GDItem]? in
            return dictionary.items.nilEmpty
        }.reduce([],+).map { $0.gdIdentifier }

        //FIXME:
        if let preheatedResult = preheatCachedResults[item.asset.localIdentifierWithoutSplitter]
        , Set((preheatedResult.detected.map{ $0.identifier })).symmetricDifference(Set(selectedGdIds)).count == 0{
            result = preheatedResult

        }else{
            result = gc(item: item, async)
            preheatCachedResults[item.asset.localIdentifierWithoutSplitter] = result
        }

        return result.detected.count > 0
                ? UICollectionViewPreheatableAppFinishAction.selectItem
                : nil
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncWaitSignalable) -> [AppTaskRespondable] {
//        let items = result
//                .filter { respondable in respondable.info.state == .completed }
//                .compactMap { $0.result as? PHAssetGCResult
//                }
//
//        let alert = UIAlertController(title: "Clean the selected items".localized, message: nil, preferredStyle: .actionSheet)
//
//        let deleteAction = UIAlertAction(title: "Delete".localized, style: .destructive) { action in
//            PHPhotoLibrary.shared().performChanges({
//                PHAssetChangeRequest.deleteAssets(items.map { $0.asset } as NSArray)
//            }, completionHandler: { (success, info) in
//                asyncSignal.end()
//            })
//        }
//        let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel) { action in
//            asyncSignal.end()
//        }
//
//        alert.addAction(deleteAction)
//        alert.addAction(cancelAction)
//
//        asyncSignal.begin()
//
//        DispatchQueue.main.async{
//            UIViewController.root?.present(alert, animated: true)
//        }
//
//        asyncSignal.waitUntilEnd()

        return result
    }
}

private class _CleanerAppTask: AppTaskPrototypeDefaultConcurrencyCountPolicy, AppTaskable {

    func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){}

    func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        guard let item = param as? AppAsset else{
            return nil
        }

        return AppCenter.default.currentInstanceAs(CleanerApp.self)?.gc(item: item, async)
    }
}

/*
    Config
*/


private protocol CleanerAppDefaults: AppDefaults{
    var selectedCollection: [GDDictionary] {get set}
    var selectionPreset: Int {get set}
    var saveContactWithoutEdit:Bool {get set}
    var quickActionOnly:Bool {get set}
}

extension Defaults: CleanerAppDefaults {
    fileprivate var selectedCollection: [GDDictionary] {
        set{ set(newValue) }
        get{
            let defaultCollection = GDDictionary.DefaultCollection
            let collection = get(or: defaultCollection )

            //diff == 0 return
            if defaultCollection == collection{
                return collection
            }
            
            //if not -> migrate
            var migratedCollection = [GDDictionary]()
            let keyedCollection = collection.dictionary { $0.key }
            
            var modCount = 0
            for ddict in defaultCollection {
                guard let ndict = keyedCollection[ddict.key] else {
                    migratedCollection.append(ddict)
                    continue
                }
                
                var m_dict = ddict
                let oGDIds = ddict.itemsGDIdentifiers
                let nGDIds = ndict.itemsGDIdentifiers
                
                for nGDId in nGDIds{
                    if let oindex = oGDIds.index(of: nGDId)
                        , let nindex = nGDIds.index(of: nGDId){
                        m_dict.items[oindex] = ndict.items[nindex]
                        modCount += 1
                    }
                }
                migratedCollection.append(m_dict)
            }
            
            if modCount > 0{
                let mSelf = self
                mSelf.selectedCollection = migratedCollection
            }
            
            return migratedCollection
        }
    }

    fileprivate var selectionPreset: Int {
        set{ set(newValue) }
        get{ return get(or: SelectionPreset.action.rawValue ) }
    }

    fileprivate var saveContactWithoutEdit: Bool {
        set{ set(newValue) }
        get{ return get(or: false ) }
    }

    fileprivate var quickActionOnly: Bool {
        set{ set(newValue) }
        get{ return get(or: false ) }
    }
}

private struct GDItem:Codable, Hashable {
    fileprivate let gdIdentifier: String
    fileprivate let label: String
    fileprivate var iconImageName: String?
    fileprivate var enabled: Bool
    private let _hashValue: Int

    init(gd: PHAssetGarbageDetector.Type, enabled:Bool=true) {
        self.gdIdentifier = gd.identifier
        self._hashValue = gdIdentifier.hashValue
        self.label = gd.label
        self.iconImageName = gd.iconImageName
        self.enabled = enabled
    }

    var hashValue: Int {
        return _hashValue
    }
}

private struct GDDictionary:Codable, Hashable {
    static let DefaultCollection: [GDDictionary] = [
        GDDictionary(
                key: .Default
                , label: "Targets".localized
                , items: CleanerApp.SupportingGDTypes.map { GDItem(gd: $0) }
        )
    ]

    enum Key: Int, Codable {
        case Default
    }

    fileprivate var key:Key
    fileprivate var label:String
    fileprivate var items:[GDItem]
    fileprivate var itemsGDIdentifiers:[String]{
        return items.map { $0.gdIdentifier }
    }

    var hashValue: Int{
        return key.rawValue
    }
}


/*

AppContent

*/

private enum SelectionPreset:Int{
    case action
    case contact
    case plaintext
}

private enum CleanerAppSettingCells {
    case presets
    case autoSelect
    case saveContactWithoutEdit
    case quickActionOnly
//    case delete
}

private struct SettingsItem {
    fileprivate var key: CleanerAppSettingCells
    fileprivate var label:String
    fileprivate var valueGetter:() -> Any
    fileprivate var valueCollection:Any?
    fileprivate var valueHandler:((Any) -> ())?
    fileprivate var cellDescriber: UITableViewCellDescribable //TODO: integrate all properties
    fileprivate var iconImageName:String?
}

fileprivate class CleanerAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource, UITableViewPickerCellDelegate{
    private lazy var tintColor = UIColor(red:0.34, green:0.55, blue:0.87, alpha:1)

    fileprivate var settingCellDescribers = [UITableViewCellDefaultDescribable]()

    private lazy var defaultCollections = CleanerApp.privateDefaults.selectedCollection

    private var isActivatedAtLeastOne:Bool{
        let activatedDicts = self.defaultCollections.compactMap { dictionary -> GDDictionary? in
            return dictionary.items.compactMap { $0.enabled ? $0 : nil }.count > 0 ? dictionary : nil
        }
        return activatedDicts.count > 0
    }

    private func startAutoSelectIfNeeded(){
        AppCenter.default.currentInstanceAs(CleanerApp.self)?.autoSelect = self.isActivatedAtLeastOne
    }
    private func stopAutoSelect(){
        AppCenter.default.currentInstanceAs(CleanerApp.self)?.autoSelect = false
    }

    required public override init() {
        super.init()
    }

    lazy var view: UIView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tintColor = tintColor
        return tableView
    }()

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = 300
        return preferences
    }

    private func createCellDescriber_SelectionPreset_contact_saveContactWithoutEdit() -> UITableViewSwitchCellDescriber{
        let celld = UITableViewSwitchCellDescriber()
        celld.itemIdentifier = CleanerAppSettingCells.saveContactWithoutEdit.hashValue
        celld.label = "Save Found Contacts Directly".localized
        celld.valueGetter = { CleanerApp.privateDefaults.saveContactWithoutEdit }
        celld.valueHandler = {
            var defaults = CleanerApp.privateDefaults
            defaults.saveContactWithoutEdit = $0 as! Bool
        }
        return celld
    }

    private func createCellDescriber_SelectionPreset_action_quickActionsOnly() -> UITableViewSwitchCellDescriber{
        let celld = UITableViewSwitchCellDescriber()
        celld.itemIdentifier = CleanerAppSettingCells.quickActionOnly.hashValue
        celld.label = "Quick Actions Only".localized
        celld.valueGetter = { CleanerApp.privateDefaults.quickActionOnly }
        celld.valueHandler = {
            var defaults = CleanerApp.privateDefaults
            defaults.quickActionOnly = $0 as! Bool
        }
        return celld
    }

    func willSetContentView(_ view: UIView, dock: AppDock) {

        if settingCellDescribers.count>0{
            return
        }

        let cell1 = UITableViewSwitchCellDescriber()
        cell1.itemIdentifier = CleanerAppSettingCells.autoSelect.hashValue
        cell1.label = "Auto Garbage Selection".localized
        cell1.valueGetter = { AppCenter.default.currentInstanceAs(CleanerApp.self)?.autoSelect }
        cell1.valueHandler = {
            AppCenter.default.currentInstanceAs(CleanerApp.self)?.autoSelect = $0 as! Bool

        }
//        settingCellDescribers.append(cell1)

        let cell0 = UITableViewSegmentControlCellDescriber()
        cell0.itemIdentifier = CleanerAppSettingCells.presets.hashValue
        cell0.label = "Formats".localized
        cell0.valueGetter = { CleanerApp.privateDefaults.selectionPreset }
        cell0.valueCollection = [
            (label:"Actions".localized,value: SelectionPreset.action.rawValue),
            (label:"Contacts".localized,value: SelectionPreset.contact.rawValue),
            (label:"Plain Text".localized,value: SelectionPreset.plaintext.rawValue)
        ]
        cell0.valueHandler = {
            let preset = $0 as! Int

            var defaults = CleanerApp.privateDefaults
            defaults.selectionPreset = preset

            // selectionPreset changed -> other self.parserCollection getter will be returned.
            (view as? UITableView)?.reloadData()


            [
                CleanerAppSettingCells.saveContactWithoutEdit.hashValue
                , CleanerAppSettingCells.quickActionOnly.hashValue
            ].forEach { hashValue in

                if let index = self.settingCellDescribers.index(where:{ describable in
                    return describable.itemIdentifier == hashValue
                }){
                    self.settingCellDescribers.remove(at: index)
                }
            }

            //saveContactWithoutEdit
            if preset == SelectionPreset.contact.rawValue{
                self.settingCellDescribers.append(self.createCellDescriber_SelectionPreset_contact_saveContactWithoutEdit())
            }

            if preset == SelectionPreset.action.rawValue{
                self.settingCellDescribers.append(self.createCellDescriber_SelectionPreset_action_quickActionsOnly())
            }

            (view as? UITableView)?.reloadData()

            // autoSelect turn off and restore
            cell1.valueHandler?(false)

        }
//        settingCellDescribers.append(cell0)

        //auto save
        if CleanerApp.privateDefaults.selectionPreset == SelectionPreset.contact.rawValue{
//            settingCellDescribers.append(createCellDescriber_SelectionPreset_contact_saveContactWithoutEdit())
        }
        else if CleanerApp.privateDefaults.selectionPreset == SelectionPreset.action.rawValue{
//            settingCellDescribers.append(createCellDescriber_SelectionPreset_action_quickActionsOnly())
        }

        if let tableView = view as? UITableView{
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = 44
            tableView.allowsSelection = false
            tableView.allowsMultipleSelection = false
            tableView.register(Cell.self, forCellReuseIdentifier: CleanerApp.info.identifier)

            for desc in settingCellDescribers {
                tableView.register(describer: desc)
            }
        }
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {

        (view as! UITableView).reloadData()

        startAutoSelectIfNeeded()
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }

    func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {

    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + defaultCollections.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        let label_section0 = "🖼️ ‣ 🔍 ‣ ⭐ " + "Select Photos To Find Everything.".localized
        return section == 0 ? label_section0 : defaultCollections[section-1].label
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? settingCellDescribers.count : defaultCollections[section-1].items.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = indexPath.section == 0 ? settings_tableView(tableView, cellForRowAt: indexPath) : itemCollection_tableView(tableView, cellForRowAt: IndexPath(item: indexPath.item, section: indexPath.section))
        return cell
    }

    func settings_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.settingCellDescribers[indexPath.item]

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

    func itemCollection_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let dictIndex = indexPath.section-1
        let dict = defaultCollections[dictIndex]

        let dataItem = dict.items[indexPath.item]
        let selected = dataItem.enabled

        let cell = tableView.dequeueReusableCell(withIdentifier: CleanerApp.info.identifier) as! Cell
        cell.textLabel?.text = dataItem.label
        itemCollection_tableView_cell_update(cell: cell, selected: selected)

        cell.imageView?.tintColor = self.view.tintColor
        let image = dataItem.iconImageName?.asUIImageNamed
        cell.imageView?.image = image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)

        cell.detailTextLabel?.textColor = UIColor.gray
        cell.optionSwitch.setOn(selected, animated: false)

        cell.switchDidChange = { on in
            self.defaultCollections[dictIndex].items[indexPath.item].enabled = on
            CleanerApp.privateDefaults.selectedCollection = self.defaultCollections

            self.stopAutoSelect()
            AppCenter.default.currentInstanceAs(CleanerApp.self)?.disposePreheatingCache()

            if on == false{
                let identifier = self.defaultCollections[dictIndex].items[indexPath.item].gdIdentifier
                AppCenter.default.currentInstanceAs(CleanerApp.self)?.disposeGdInstance(identifier: identifier)
            }

            self.startAutoSelectIfNeeded()

//            if let cellDesc:UITableViewCellDefaultDescribable = self.settingCellDescribers.first(where:{ describable in
//                describable.itemIdentifier == CleanerAppSettingCells.autoSelect.hashValue
//            }){
//                let activated = self.defaultCollections.compactMap { dictionary -> [GDItem]? in
//                    return dictionary.items.nilEmpty
//                }.reduce([],+).compactMap { $0.enabled ? $0 : nil }.count>0
//
//                if cellDesc.valueGetter() as? Bool ?? false != activated{
//                    cellDesc.valueHandler?(activated)
//                    tableView.reloadSections(IndexSet(integer: 0), with: .none)
//                }
//            }

            self.itemCollection_tableView_cell_update(cell: cell, selected: on)
        }

        return cell
    }

    func itemCollection_tableView_cell_update(cell:UITableViewCell, selected:Bool){
        cell.detailTextLabel?.text = selected ? "%@ might be found".localizedFormatted("").trimmed : nil
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
