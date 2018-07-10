//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import DefaultsKit
import CocoaImageHashing
import MetalPerformanceShaders
import MetalKit
import Vision

private typealias CleanerAppParam = PHAssetItem<ImageEditStateValue>
private struct CleanerAppResult: AppTaskResultable {
    fileprivate let asset:PHAsset
    
    init(asset:PHAsset){
        self.asset = asset
    }
    
    fileprivate var lockscreen:Bool?
    fileprivate var hasSimilarAsset:Bool?
    fileprivate var isTooBlurry:Bool?
}


private typealias PHAssetID = String

public class CleanerApp: NSObject, BApp, KeyPathWatchable, PHAssetFinalizableApp, AppDockApp, PhotoPickerViewControllerDelegatableApp, PreheatableApp {
    public static let taskType: AppTaskable.Type = _CleanTask.self

    public static let paramType: AppTaskParamable.Type = PHAssetItem<ImageEditStateValue>.self
    
    public private(set) lazy var dockContent: AppDockContent? = CleanerAppDockContent()

    fileprivate static let privateDefaults = CleanerApp.defaults as! CleanerAppDefaults

    public static let info = AppInfo(
            identifier: "com.stells.pap.cleaner"
            , version: "0.1"
            , phase: .develop
            , appType: CleanerApp.self
            , displayName: "Cleaner".localized, description:nil, keywords:nil
            , iconBundleName: R.image.cleanerBAppIcon.name
            , policy: AppPolicy.default
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
        return "Start".localized
    }
    
    @objc dynamic
    public fileprivate (set) lazy var autoSelect: Bool = false
    
    fileprivate var detector = CleanerAppDetector()
    
    fileprivate var preheatedResults = [PHAssetID: CleanerAppResult]()
    fileprivate var preheatedSimilarities = [PHAssetID: [PHAssetID]]()
    
    public func performPreheating(item: AppAsset, _ async: AsyncSignal) -> PreheatingFinishAction? {
        guard self.autoSelect else { return nil }
        
        var preheatedResult:CleanerAppResult? = preheatedResults[item.asset.localIdentifierWithoutSplitter]
        if preheatedResult == nil {
            preheatedResult = self.detector.detectResult(asset: item.asset, async) ?? CleanerAppResult(asset: item.asset)
            preheatedResults[item.asset.localIdentifierWithoutSplitter] = preheatedResult
        }
        
        if preheatedResult?.lockscreen == true || preheatedResult?.hasSimilarAsset == true || preheatedResult?.isTooBlurry == true {
            return UICollectionViewPreheatableAppFinishAction.selectItem
        }
        
        return nil
    }
    
    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        let items = result.filter { respondable in respondable.info.state == .completed }.compactMap { $0.result as? CleanerAppResult }
        
        let alert = UIAlertController(title: "Clean the selected items".localized, message: nil, preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete".localized, style: .destructive) { action in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(items.map { $0.asset } as NSArray)
            }, completionHandler: { (success, info) in
                asyncSignal.end()
            })
        }
        let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel) { action in
            asyncSignal.end()
        }
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        asyncSignal.begin()
        
        DispatchQueue.main.async{
            UIViewController.root?.present(alert, animated: true)
        }
        
        asyncSignal.waitUntilEnd()
        
        return result
    }
}

private struct CleanerAppDetector {
    fileprivate mutating func detectResult(asset:PHAsset, _ async: AsyncManualSignalable) -> CleanerAppResult? {
        var result = CleanerAppResult(asset: asset)
        
//            if asset.mediaSubtypes.contains(.photoScreenshot) {
//                result.lockscreen = true
//            }
        
        autoreleasepool {
            result.hasSimilarAsset = detectSimilarAsset(asset)
            guard result.hasSimilarAsset != true else { return }
            
            result.isTooBlurry = detectBlurryImage(asset)
            guard result.isTooBlurry != true else { return }
        }
        
        return result
    }
    
    private func croppedFaceGroup(_ image: CIImage) -> CIImage? {
        let dispatchGroup = DispatchGroup()
        
        var faceBounds: CGRect?
        
        let faceDetectRequest = VNDetectFaceRectanglesRequest { (request, error) in
            dispatchGroup.leave()
            
            if let faces = (request.results as? [VNFaceObservation])?.compactMap({ $0.boundingBox }), !faces.isEmpty, let bounds = faces[1...].reduce(faces.first, { $0?.union($1) }), bounds.width * bounds.height > 0.2 {
                let transform = CGAffineTransform(scaleX: image.extent.width, y: image.extent.height)
                faceBounds = bounds.applying(transform)
            }
        }
        
        dispatchGroup.enter()
        try? VNImageRequestHandler(ciImage: image, options: [:]).perform([faceDetectRequest])
        dispatchGroup.wait()
        
        guard let rect = faceBounds else { return nil }
        return image.cropped(to: rect)
    }
    
    private func detectBlurryImage(_ asset: PHAsset) -> Bool {
        // https://www.pyimagesearch.com/2015/09/07/blur-detection-with-opencv/
        // https://stackoverflow.com/questions/46893198/detecting-if-image-is-blurred-using-opencv
        //
        guard
            asset.imageType == .stillImage,
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue(),
            let commandBuffer = commandQueue.makeCommandBuffer(),
            var ciImage = asset.asCIImage
            else { return false }
        
        if let face = croppedFaceGroup(ciImage) {
            ciImage = face
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: Int(ciImage.extent.width), height: Int(ciImage.extent.height), mipmapped: false)
        textureDescriptor.usage = [MTLTextureUsage.shaderRead, MTLTextureUsage.shaderWrite]
        
        guard
            let sourceTexture = device.makeTexture(descriptor: textureDescriptor),
            let binaryTexture = device.makeTexture(descriptor: textureDescriptor),
            let laplacianTexture = device.makeTexture(descriptor: textureDescriptor)
            else { return false }
        
        ImageAlignment.sharedCIContext.render(ciImage, to: sourceTexture, commandBuffer: commandBuffer, bounds: ciImage.extent, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        MPSImageLaplacian(device: device).encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: laplacianTexture)
        MPSImageThresholdBinary(device: device, thresholdValue: 0.4, maximumValue: 1, linearGrayColorTransform: nil).encode(commandBuffer: commandBuffer, sourceTexture: laplacianTexture, destinationTexture: binaryTexture)
        
        let numberOfHistogramEntries = 256
        
        var histogramInfo = MPSImageHistogramInfo(
            numberOfHistogramEntries: numberOfHistogramEntries,
            histogramForAlpha: false,
            minPixelValue: vector_float4(0, 0, 0, 0),
            maxPixelValue: vector_float4(1, 1, 1, 1))
        
        let histogram = MPSImageHistogram(device: device, histogramInfo: &histogramInfo)
        let bufferLength = histogram.histogramSize(forSourceFormat: binaryTexture.pixelFormat)
        guard let histogramInfoBuffer = device.makeBuffer(length: bufferLength, options: []) else { return false }
        
        histogram.encode(to: commandBuffer, sourceTexture: binaryTexture, histogram: histogramInfoBuffer, histogramOffset: 0)
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let histogramContents = histogramInfoBuffer.contents().bindMemory(to: Float.self, capacity: numberOfHistogramEntries)
        
        let threshold: Float = 0.00000000000000000000000000000000000000000031 //TODO: this is a manual threshold
        let numberOfWhitePixels = histogramContents[numberOfHistogramEntries - 1]
        
        return numberOfWhitePixels < threshold
    }
    
    fileprivate var targetAssets = [PHAsset]()
    fileprivate let imageHashing = OSImageHashing.sharedInstance()
    
    private mutating func detectSimilarAsset(_ asset: PHAsset) -> Bool {
        // https://github.com/ameingast/cocoaimagehashing/
        
        let timeClustering: TimeInterval = 60 // 1 minute
        
        var hasSimilar = false
        for targetAsset in targetAssets[..<min(targetAssets.count, 20)] {
            guard let fromDate = targetAsset.creationDate, let toDate = asset.creationDate, fromDate.timeIntervalSince(toDate).magnitude < timeClustering else {
                continue
            }
            
            guard let fromData = targetAsset.requestThumbnailImage(targetSize: CGSize(width: 100, height: 100))?.asData, let toData = asset.requestThumbnailImage(targetSize: CGSize(width: 100, height: 100))?.asData else { continue }
            
            let fromHash = imageHashing.hashImageData(fromData)
            let toHash = imageHashing.hashImageData(toData)
            let distance = imageHashing.hashDistance(fromHash, to: toHash)
            
            if distance < imageHashing.hashDistanceSimilarityThreshold(withProvider: .dHash) {
                hasSimilar = true
                break
            }
        }
        
        targetAssets.insert(asset, at: 0)
        
        return hasSimilar
    }
}

private class _CleanTask: AppTaskPrototype, AppTaskable {
    public func cancel(_ param: AppTaskParamable, _ async: AsyncManualSignalable){}

    public func perform(_ param: AppTaskParamable, _ async: AsyncManualSignalable) throws -> AppTaskResultable? {
        if let asset = (param as? PHAssetItem<ImageEditStateValue>)?.asset{
            return PHAssetResultItem(asset: asset, contentEditingOutput: nil)
        }
        return nil
    }
}

//fileprivate class CleanerAppDockContent: NSObject, KeyPathWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
//    private lazy var defaults = CleanerApp.defaults as! CleanerAppDefaults
//
//    private let primaryColor = UIColor(red:0.6, green:0.6, blue:0.6, alpha:1)
//
//    lazy var view: UIView = {
//        let tableView = UITableView(frame: .zero, style: .grouped)
//        return tableView
//    }()
//
//    private var autoSelect:Bool = false
//
//    var preferences: AppDockContentPreferable? {
//        var preferences = AppDockContentPreferences()
//        preferences.preferredHeight = (view as! UITableView).rowHeight + 48
//        return preferences
//    }
//
//    func willSetContentView(_ view: UIView, dock: AppDock) {
//        if let view = view as? UITableView{
//            view.dataSource = self
//            view.delegate = self
//            view.rowHeight = 52
//            view.allowsSelection = false
//            view.register(Cell.self, forCellReuseIdentifier: CleanerApp.info.identifier)
//            //            view.backgroundColor = UIColor(red: 31 / 255.0, green: 31 / 255.0, blue: 31 / 255.0, alpha: 1)
//            view.tintColor = self.primaryColor
//            //            view.separatorInset.left = view.rowHeight
//        }
//    }
//
//    func didSetContentView(_ view:UIView, dock:AppDock) {
//        if options != nil{
//            (view as! UITableView).reloadData()
//        }
//    }
//
//    @objc dynamic
//    var options:[String: Any]? // Bool may be other custom Codable type instead of Any
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 50
//    }
//
//    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        return 0
//    }
//
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return section == 0 ? "🖼️ ‣ 🤖 ‣ ❌ " + "Select Photos You Want To Clean!".localized : nil
//    }
//
//    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//        return nil
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 1
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: CleanerApp.info.identifier) as! Cell
//
//        cell.imageView?.tintColor = primaryColor
//        cell.imageView?.contentMode = .scaleAspectFit
//
//        cell.textLabel?.text = "Enable Auto Selection".localized
//        cell.optionSwitch.setOn(self.autoSelect, animated: false)
//        cell.switchDidChange = { on in
//            self.autoSelect = on
//            AppCenter.default.currentInstanceAs(CleanerApp.self)?.autoSelect = on
//        }
//
//        return cell
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//    }
//
//    private class Cell: UITableViewCell {
//        lazy var optionSwitch: UISwitch = {
//            let view = UISwitch()
//            view.addTarget(self, action: #selector(self.cellSwitchDidChange), for: .valueChanged)
//            return view
//        }()
//
//        var switchDidChange: ((Bool) -> Void)?
//
//        override func prepareForReuse() {
//            super.prepareForReuse()
//
//            switchDidChange = nil
//        }
//
//        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//            super.init(style: style, reuseIdentifier: reuseIdentifier)
//
//            accessoryView = optionSwitch
//        }
//
//        required init?(coder aDecoder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
//
//        @objc func cellSwitchDidChange(sender: UISwitch) {
//            switchDidChange?(sender.isOn)
//        }
//
//        override func layoutSubviews() {
//            super.layoutSubviews()
//        }
//
//        override func tintColorDidChange() {
//            super.tintColorDidChange()
//
//            optionSwitch.onTintColor = tintColor
//        }
//    }
//}





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

private protocol CleanerAppDefaults: AppDefaults{
    var selectedParserCollection: ParserCollection {get set}
    var selectionPreset: Int {get set}
    var saveContactWithoutEdit:Bool {get set}
    var quickActionOnly:Bool {get set}
}

extension Defaults: CleanerAppDefaults {
    fileprivate var selectedParserCollection: ParserCollection {
        set{ set(newValue) }
        get{ return get(or: ParserDictionary.DefaultCollection) }
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


extension CleanerAppDefaults{
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

        case FlightNumber
        case GPSCoordinates
    }

    fileprivate var key:Key
    fileprivate var label:String
    fileprivate var iconImageBundleName:String?
}

private struct ParserDictionary {

    static let DefaultCollection: ParserCollection = [
        ParserDictionary.Key.Information: [
            ParserItem.Key.PhoneNumber
            ,ParserItem.Key.EmailAddress
            ,ParserItem.Key.Address

            ,ParserItem.Key.Date
            ,ParserItem.Key.URL
            ,ParserItem.Key.FlightNumber
        ]
    ]

    enum Key: Int, Codable {
        case Information
    }

    fileprivate var key:Key
    fileprivate var label:String
    fileprivate var items:[ParserItem]
}

fileprivate class CleanerAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource, UITableViewPickerCellDelegate{
    private lazy var tintColor = UIColor(red:0.36, green:0.31, blue:0.71, alpha:1)

    fileprivate var settingCellDescribers = [UITableViewCellDefaultDescribable]()

    private var parserCollection:[ParserDictionary] {
        get{
            if CleanerApp.privateDefaults.selectionPreset == SelectionPreset.plaintext.rawValue{
                return []
            }

            return type(of: self).defaultParserCollection
        }
    }

    fileprivate static let defaultParserCollection:[ParserDictionary] = [

        ParserDictionary(key: ParserDictionary.Key.Information, label: "Items".localized,
                items: [
                    ParserItem(key: ParserItem.Key.PhoneNumber, label:"Phone Number".localized, iconImageBundleName:R.image.ico_action_phonenumber.name)
                    ,ParserItem(key: ParserItem.Key.EmailAddress, label:"E-mail Address".localized, iconImageBundleName:R.image.ico_action_email.name)
                    ,ParserItem(key: ParserItem.Key.Address, label:"Address".localized, iconImageBundleName:R.image.ico_action_address.name)
                    ,ParserItem(key: ParserItem.Key.Date, label:"Date".localized, iconImageBundleName:R.image.ico_action_date.name)
                    ,ParserItem(key: ParserItem.Key.URL, label:"URL", iconImageBundleName:R.image.ico_action_url.name)
                    ,ParserItem(key: ParserItem.Key.FlightNumber, label:"Flight Number".localized, iconImageBundleName:R.image.ico_action_flightnumber.name)
                ])
    ]

    required public override init() {
        super.init()
    }

    private var initialSelectedIndexPaths:[IndexPath]?

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

    private var selectedParserCollection: ParserCollection{
        return CleanerApp.privateDefaults.selectedParserCollection
    }

    private var autoSelect:Bool = false


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
        cell1.label = "Enable Auto Selection".localized
        cell1.valueGetter = { self.autoSelect }
        cell1.valueHandler = {
            self.autoSelect = $0 as! Bool
            AppCenter.default.currentInstanceAs(CleanerApp.self)?.autoSelect = self.autoSelect
        }
        settingCellDescribers.append(cell1)

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
        settingCellDescribers.append(cell0)

        //auto save
        if CleanerApp.privateDefaults.selectionPreset == SelectionPreset.contact.rawValue{
            settingCellDescribers.append(createCellDescriber_SelectionPreset_contact_saveContactWithoutEdit())
        }
        else if CleanerApp.privateDefaults.selectionPreset == SelectionPreset.action.rawValue{
            settingCellDescribers.append(createCellDescriber_SelectionPreset_action_quickActionsOnly())
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

        let defaultsCollection = CleanerApp.privateDefaults.selectedParserCollection

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

        let label_section0 = "🖼️ ‣ 🔍 ‣ ⭐ " + "Select Photos To Find Everything.".localized
        return section == 0 ? label_section0 : parserCollection[section-1].label
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? settingCellDescribers.count : parserCollection[section-1].items.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = indexPath.section == 0 ? settings_tableView(tableView, cellForRowAt: indexPath) : parserCollection_tableView(tableView, cellForRowAt: IndexPath(item: indexPath.item, section: indexPath.section))
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

    func parserCollection_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let dict = self.parserCollection[indexPath.section-1]

        var selected = false
        if let _ = initialSelectedIndexPaths?.index(of: indexPath) {
            selected = true
        }
        if let _ = CleanerApp.privateDefaults.selectedParserCollection[dict.key]?.index(of: dict.items[indexPath.item].key){
            selected = true
        }

        let dataItem = dict.items[indexPath.item]

        let cell = tableView.dequeueReusableCell(withIdentifier: CleanerApp.info.identifier) as! Cell
        cell.textLabel?.text = dataItem.label
        cell.detailTextLabel?.text = selected ? "may be found" : nil

        cell.imageView?.tintColor = self.view.tintColor
        let image = dataItem.iconImageBundleName?.asUIImageNamed
        cell.imageView?.image = image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)

        cell.detailTextLabel?.textColor = UIColor.gray
        cell.optionSwitch.setOn(selected, animated: false)
        cell.switchDidChange = { on in
            if on{
                CleanerApp.privateDefaults.addHandledProperty(dict.key, dict.items[indexPath.item].key)
            }else{
                CleanerApp.privateDefaults.removeHandledProperty(dict.key, dict.items[indexPath.item].key)
            }

            tableView.reloadRows(at: [indexPath], with: .fade)

//            let selectedPreset = CleanerApp.privateDefaults.selectionPreset
//
//            if selectedPreset == GrabAs.plaintext.rawValue || selectedPreset == GrabAs.contact.rawValue{
//                CleanerApp.privateDefaults.selectionPreset = GrabAs.action.rawValue
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
