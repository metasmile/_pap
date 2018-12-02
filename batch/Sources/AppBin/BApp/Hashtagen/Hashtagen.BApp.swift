//
// Created by BLACKGENE on 20/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import PropertyKit
import FirebaseMLVision
import TagListView

private typealias HashtagenAppParam = AppAsset

private extension Array where Element==String{
    func getHashTagString(separator:String="#", allowWhiteSpace:Bool=false) -> String{
        var sourceStrings = self
        if allowWhiteSpace == false{
            sourceStrings = sourceStrings.map{ $0.remove(" ") }
        }
        return separator + "\(sourceStrings.joined(separator: " "+separator))"
    }
}

private protocol HashtagenAppDefaults: AppDefaults{
    var autoSelect: Bool {get set}
}

extension Defaults: HashtagenAppDefaults {
    fileprivate var autoSelect: Bool {
        set{ set(newValue); }
        get{ return get(or: true) }
    }
}


public class HashtagenApp: NSObject, PropertyWatchable, BApp
        , AppDockApp
        , FinalizableApp
        , PhotoPickerViewControllerAppearanceDelegatableApp
        , PhotoPickerCollectionViewDelegatableApp
        , PreheatableApp {
    public static let taskType: AppTaskable.Type = _HashtagenAppTask.self

    public static let paramType: AppTaskParamable.Type = HashtagenAppParam.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.hashtagen"
            , version: "1.0"
            , phase: .develop
            , appType: HashtagenApp.self
            , displayName: "Hashtagen"
            , description: "Finding and collecting hashtags from your photos you selected.".localized
            , keywords: ["#", "Instagram", "Hashtag", "Social Network", "Twitter", "Facebook", "Digial Marketing"]
            , iconBundleName: R.image.hashtagenBAppIcon.name
            , themeColor: UIColor(rgb: 0xE429A8)
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    fileprivate lazy var labelDetector = HashtagenAppDetector()

    public private(set) lazy var content: AppDockContent? = HashtagenAppDockContent()

    private let appDefaults = HashtagenApp.defaults as! HashtagenAppDefaults

    @objc dynamic
    public fileprivate (set) lazy var autoSelect: Bool = appDefaults.autoSelect

    required public override init(){
        super.init()
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return true
    }

    func didDeselectAll(callee: PhotoPickerViewControllerUniversalOperations) {
        self.detectingSig.done()
        (content as? HashtagenAppDockContent)?.setLabelsIfNeeded([])
    }

    private let detectingSig = AsyncSignal()
    func didSelect(asset: PHAsset, indexPath: IndexPath, callee: PhotoPickerViewControllerUniversalOperations) {
        DispatchQueue(label: (preheatingFrontQueueLabel ?? DispatchQueue.global(qos: .utility).label)).async{
            self.performDetectingTags(for: PHAssetItem(asset: asset, indexPath: indexPath), self.detectingSig, exclude:false)
        }
    }

    func didDeselect(asset: PHAsset, indexPath: IndexPath, callee: PhotoPickerViewControllerUniversalOperations) {
        DispatchQueue(label: (preheatingFrontQueueLabel ?? DispatchQueue.global(qos: .utility).label)).async{
            self.performDetectingTags(for: PHAssetItem(asset: asset, indexPath: indexPath), self.detectingSig, exclude:true)
        }
    }

    fileprivate var preheatCachedResults = [String:VisionLabelPHAssetDetectResult]()
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

    public func didCancelPreheating() {
        (content as? PreheatableAppSubscribable)?.didStopPreheating()
    }

    public func didFinishCurrentPreheatingCycle() {
        (content as? PreheatableAppSubscribable)?.didStopPreheating()
    }

    public func performPreheating(item: PHAssetParamable,  _ async: AsyncWaitSignalable)  -> PreheatingFinishAction? {
        if self.autoSelect == false{
            return nil
        }

        (content as? PreheatableAppSubscribable)?.didStartPreheating()

        preheatingFrontQueueLabel = async.queueStack.first ?? DispatchQueue.currentLabel

        performDetectingTags(for: item, async)

        return nil
    }

    @discardableResult
    private func performDetectingTags(for item: PHAssetParamable, _ async: AsyncWaitSignalable, exclude:Bool=false)  -> Bool {
        var detectedResult:VisionLabelPHAssetDetectResult?

        if let r = preheatCachedResults[item.asset.localIdentifierWithoutSplitter]{
            detectedResult = r

        }else{
            if let r = labelDetector.detectResult(asset: item.asset, async), r.labelTextsConfidenceDescending.count > 0{
                detectedResult = r
                //FIXME: BAD_EXEC -> use common queue.
                preheatCachedResults[item.asset.localIdentifierWithoutSplitter] = detectedResult
            }
        }

        if let r = detectedResult{
            (content as? HashtagenAppDockContent)?.setLabelsIfNeeded([r], remove:exclude)
        }

        return detectedResult != nil
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncWaitSignalable) -> [AppTaskRespondable] {

        if let _ = UIViewController.presentable,
           let hashtagsString = (content as? HashtagenAppDockContent)?.currentTags.getHashTagString().nilEmpty {

            asyncSignal.begin()
            DispatchQueue.global().async {

                UIActivityViewController.share(activityItems: [hashtagsString]) { (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, activityError: Error?) in

                    (self.content as? HashtagenAppDockContent)?.setLabelsIfNeeded([])

                    asyncSignal.end()
                }
            }
            asyncSignal.waitUntilEnd()
        }

        return result
    }

    public var titleWillBegin: String? {
        return "Starting to find...".localized
    }

    public var titleWillFinalize: String? {
        return "Finding Hashtags From Photos...".localized
    }

    public var doneButtonTitle: String? {
        return "Get All Items".localized
    }
}

private struct HashtagenAppDetector{

    private let vision = Vision.vision()

    fileprivate func detectResult(asset:PHAsset, _ async: AsyncWaitSignalable) -> VisionLabelPHAssetDetectResult? {
        var results:VisionLabelPHAssetDetectResult?

        if let image = asset.asUIImage  {
            async.begin()

            vision.labelDetector().detect(in: VisionImage(image: image), completion:{ (labels,e) in
                if e == nil, let labels:[VisionLabel] = labels?.nilEmpty{
                    results = VisionLabelPHAssetDetectResult(asset: asset, visionLabels: labels)
                }
                async.end()
            })
            async.waitUntilEnd()
        }

        return results
    }
}

private class _HashtagenAppTask: AppTaskPrototype, AppTaskable {
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){}

    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is HashtagenAppParam, "TaskParamable type of this app is \(HashtagenAppParam.self)")
        guard let _param = param as? HashtagenAppParam else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }

    private func _perform(_ param: HashtagenAppParam, _ async: AsyncWaitSignalable) throws -> VisionLabelPHAssetDetectResult?  {
        if let app = AppCenter.default.currentInstanceAs(HashtagenApp.self){
            return app.preheatCachedResults[param.asset.localIdentifierWithoutSplitter] ?? app.labelDetector.detectResult(asset: param.asset, async)
        }
        return nil
    }
}


/*
HashtagenAppDockContent
*/

extension HashtagenAppDockContent: PreheatableAppSubscribable{
    func prepareStatusDisplaying(label:String?){

//        var desc = self.settingCellDescribers.first { describable in
//            describable.itemIdentifier == CleanerAppSettingCells.autoSelect.hashValue
//        }
//        desc?.detailedLabel = label
    }

    func didStartPreheating() {
//        prepareStatusDisplaying(label: "Activating Current Visible Items ...".localized)
//        self.startSelectionBotIconAnimation(self.settingCellDescribers, CleanerAppSettingCells.autoSelect.hashValue)
    }

    func didStopPreheating() {

//        prepareStatusDisplaying(label: CleanerApp.privateDefaults.autoSelect ? "On Standby".localized : nil)
//        self.stopSelectionBotIconAnimation(self.settingCellDescribers, CleanerAppSettingCells.autoSelect.hashValue)
    }
}

private class IntrinsicTableView: UITableView {
    override var contentSize:CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}

//TODO: hashtag expanding from suggest api
//TODO: # or commma selection
//TODO: threshold for confidence

fileprivate class HashtagenAppDockContent: NSObject, PropertyWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource, TagListViewDelegate{
    private lazy var defaults = HashtagenApp.defaults as! HashtagenAppDefaults

    private let primaryColor = HashtagenApp.info.themeColor

    private var settedLabelResults = [VisionLabelPHAssetDetectResult]()

    fileprivate var currentTags:[String]{
        return self.tagsView.tagViews.compactMap { $0.titleLabel?.text }.uniq()
    }

    fileprivate func setLabelsIfNeeded(_ settingResults:[VisionLabelPHAssetDetectResult], remove:Bool=false){
        let resultsAdding = Array<VisionLabelPHAssetDetectResult>(Set(settingResults).subtracting(Set(settedLabelResults)))
        let shouldRemoveAll = settingResults.count == 0 || resultsAdding.count==0 && settedLabelResults.count == 0

        if shouldRemoveAll{
            self.settedLabelResults = []

        }else if resultsAdding.count>0, remove == false{
            self.settedLabelResults += resultsAdding

        }else if settingResults.count>0, remove{
            self.settedLabelResults = Array(Set(self.settedLabelResults).subtracting(Set(settingResults)))
        }

        DispatchQueue.mainAsyncIfNot {

            let removingTags = Set(settingResults.labelTextsConfidenceDescending).subtracting(Set(self.settedLabelResults.labelTextsConfidenceDescending))
            let currentTagsSet = Set(self.currentTags)
            let addingTags = resultsAdding.labelTextsConfidenceDescending.filter{ !currentTagsSet.contains($0) }

//            self.tagsView.removeAllTags()
//            for l in self.settedLabelResults.labelTextsConfidenceDescending{
//                self.tagsView.addTag(l)
//            }

            UIView.animate(withDuration: 0.3){
                if shouldRemoveAll{
                    self.tagsView.removeAllTags()

                }else if remove{
                    for l in removingTags{
                        self.tagsView.removeTag(l)
                    }

                }else{
                    for l in addingTags{
                        self.tagsView.addTag(l)
                    }
                }
            }
        }
    }

    fileprivate lazy var tableView:UITableView = {
        let tableView = IntrinsicTableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 52
        tableView.allowsSelection = false
        tableView.register(Cell.self, forCellReuseIdentifier: HashtagenApp.info.identifier)
//            tableView.backgroundColor = UIColor(red: 31 / 255.0, green: 31 / 255.0, blue: 31 / 255.0, alpha: 1)
        tableView.tintColor = self.primaryColor
        return tableView
    }()

    private lazy var tagsView:TagListView = {
        let tagListView = TagListView()
        tagListView.enableRemoveButton = true
        tagListView.cornerRadius = 10
        tagListView.paddingY = 6
        tagListView.paddingX = 9
        tagListView.textFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        tagListView.alignment = .center
        tagListView.tagBackgroundColor = tagListView.colorTheme.objectBackgroundColor ?? tagListView.tagBackgroundColor
        tagListView.delegate = self
        return tagListView
    }()

    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        tagView.isSelected = !tagView.isSelected
    }

    func tagRemoveButtonPressed(_ title: String, tagView: TagView, sender: TagListView) {
        UIView.animate(withDuration: 0.2) {
            self.tagsView.removeTagView(tagView)
        }
    }


    lazy var view: UIView = {

        let scrollView = UIScrollView()

        let stackView = UIStackView()
        scrollView.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.topAnchor.constraint(equalTo:scrollView.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo:scrollView.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo:scrollView.trailingAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo:scrollView.bottomAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo:scrollView.widthAnchor).isActive = true
        //@_@ what the?: https://stackoverflow.com/questions/31668970/is-it-possible-for-uistackview-to-scroll

        stackView.addArrangedSubview(self.tableView)
        stackView.addArrangedSubview(self.tagsView)

        return scrollView
    }()

    var contentScrollable: AppDockContentScrollable? {
        guard let scrollView = view as? UIScrollView else { return nil }
        return AppDockScrollableContent(scrollView)
    }

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = tableView.rowHeight * CGFloat(4)
        return preferences
    }

    func willSetContentView(_ view: UIView, dock: AppDock) {


    }

    func didSetContentView(_ view:UIView, dock:AppDock) {
        if options != nil{
            tableView.reloadData()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: HashtagenApp.info.identifier) as! Cell

//        cell.imageView?.image = nil
        cell.imageView?.tintColor = primaryColor
        cell.imageView?.contentMode = .scaleAspectFit

        cell.textLabel?.text = "Auto Tagging Bot".localized
        cell.imageView?.image = R.image.commonCellIconRobot()?.withRenderingMode(.alwaysTemplate)
        cell.imageView?.tintColor = primaryColor

        cell.optionSwitch.setOn(defaults.autoSelect, animated: false)
        cell.optionSwitch.onTintColor = HashtagenApp.info.themeColor
        cell.switchDidChange = { on in
            self.defaults.autoSelect = on
            AppCenter.default.currentInstanceAs(HashtagenApp.self)?.autoSelect = on
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

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            accessoryView = optionSwitch
//            backgroundColor = .clear
//            textLabel?.font = UIFont.systemFont(ofSize: 14)
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
    }
}

import Intents

extension HashtagenApp:UIApplicationDelegateLaunchableApp{
    static var intents: [INIntent] {
        if #available(iOS 12.0, *) {
            let openAppIntent = OpenIntent()
            openAppIntent.appId = HashtagenApp.info.identifier
            openAppIntent.appName = NSString.deferredLocalizedIntentsString(with: HashtagenApp.info.displayName) as String
            openAppIntent.suggestedInvocationPhrase = "Open Restorer.".localized

            let asb = AutoSelectIntent()
            asb.appId = info.identifier
            asb.appName = openAppIntent.appName
            asb.suggestedInvocationPhrase = "Auto Select on %@.".localizedFormatted(info.displayName)

            return [openAppIntent, asb]
        } else {
            return []
        }
    }

    func didLaunchHandling(with userActivity: NSUserActivity) {

        if #available(iOS 12.0, *) {
            guard let intent = userActivity.interaction?.intent else {
                return
            }

            if intent is AutoSelectIntent{
                var mutableDefaults = self.appDefaults
                mutableDefaults.autoSelect = true

                (content as? HashtagenAppDockContent)?.tableView.reloadData()
            }
        }

    }

    func didLaunchHandling(with shortcutItem: UIApplicationShortcutItem) {
    }
}
