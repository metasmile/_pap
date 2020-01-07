//
//  CurveEditor.BApp.swift
//  pap
//
//  Created by HYOJIN MO on 28/02/2019.
//  Copyright © 2019 Stells. All rights reserved.
//

import UIKit
import PropertyKit
import Photos

protocol CurveEditorDefaults: AppDefaults {
    var colorFilters: [CIBuiltInFilter] { get set }
}

extension Defaults: CurveEditorDefaults {
    internal var colorFilters: [CIBuiltInFilter] {
        set { set(newValue); papLog.app.defaults.log(value:String(describing: newValue)) }
        get { return get(or: []) }
    }
}

class CurveEditorApp: NSObject, BApp, PropertyWatchable, ConfigurableApp, _ConfigurableApp,
    PHAssetFinalizableApp, EditableApp, RecordableApp, PreviewProcessableApp, AppDockApp,
PhotoPickerCollectionViewDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp, PhotoEditViewControllerDelegatableApp {
    public static let taskType: AppTaskable.Type = CurveEditorTask.self

    public static let paramType: AppTaskParamable.Type = _CurveEditorAppAsset.self

    public static var defaultConfigValue: AppConfigValuable {
        let config = FiltersAppConfigValue()
        return config
    }

    @objc dynamic
    public private(set) lazy var config: FiltersAppConfigValue? = type(of:self).defaultConfigValue as? FiltersAppConfigValue

    public private(set) lazy var content: AppDockContent? = CurveEditorAppDockContent(app: self)
    public private(set) lazy var editViewDockContent: AppDockContent? = CurveEditorAppDockContent()

    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func setDefaultEditState(value: ImageEditStateValue?) {
        defaultEditStateValue = value

        if var defaults = type(of: self).defaults as? CurveEditorDefaults, let filter = value?.ciFilter as? CIColorFilterGroup {
            defaults.colorFilters = filter.filters
        }
    }

    public static let info = AppInfo(
        identifier: "com.stells.batch.curveeditor"
        , version: "1.0"
        , phase: .beta
        , appType: CurveEditorApp.self
        , displayName: "Curve Tool".localized.localizedCapitalized
        , description: "Curve Tool".localized
        , keywords: ["Curve", "Color", "RGB"]
        , icon: AppIcon(source: R.image.curveEditorBAppIcon.name, style: .themeColor)
        , themeColor: UIColor(rgb: 0x49CE8A)
        , policy: AppPolicy.default
        , minOSVersion: nil
    )

    required public override init() {
        super.init()

        let controllerContent = self.content as? CurveEditorAppDockContent
        controllerContent?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContent?.filter {
                self.config?.filter = CIFilterItem(filter)
            }
            else if var defaults = type(of: self).defaults as? CurveEditorDefaults {
                let filter = CIColorFilterGroup(filters: defaults.colorFilters)

                let filterItem = CIFilterItem(filter)
                self.config?.filter = filterItem
                self.defaultEditStateValue = filterItem
            }
        }

        let controllerContentInPhotoEditor = self.editViewDockContent as? CurveEditorAppDockContent
        controllerContentInPhotoEditor?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContentInPhotoEditor?.filter {
                self.config?.filter = CIFilterItem(filter)
            }
            else if var defaults = type(of: self).defaults as? CurveEditorDefaults {
                let filter = CIColorFilterGroup(filters: defaults.colorFilters)

                let filterItem = CIFilterItem(filter)
                self.config?.filter = filterItem
            }
        }
    }

    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.actions]
    }

    public static var fixedContentLayout: Bool {
        return true
    }

    public var doneButtonTitle: String? {
        return "Apply".localized
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return true
    }

    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
    }

    //INFO: prevent memory leak for creating CIImage(uiImage:)
    public lazy var previewOriginalImageCache: NSCache<NSString, CIImage>? = NSCache<NSString, CIImage>()
    public func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, in content: AppDockContent?, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void)) {
        let original = cachedOriginalImage(with: appAsset.asset, targetSize: targetSize)

        let filtered = original?.applyFilter(ciFilter: appAsset.editState.ciFilter)
        completion(original?.asUIImage, filtered?.asUIImage)
    }

    public func selectEditState(value: ImageEditStateValue?, in content: AppDockContent?) {
        if let filter = value?.ciFilter as? CIColorFilterGroup {
            (content as? CurveEditorAppDockContent)?.setFilterValues(filter, animated: false)

            if self.recordStack.isEmpty {
                self.register(filter.filters)
            }
        }
    }

    public var recordStack: [[CIBuiltInFilter]] = [[CIBuiltInFilter]]()
    public var recordIndex: Int = 0

    public func didChangeRecordIndex(for item: Array<CIBuiltInFilter>?) {
        var controller: CurveEditorAppDockContent?
        if let content = self.content as? CurveEditorAppDockContent {
            controller = content
        }
        else if let content = self.editViewDockContent as? CurveEditorAppDockContent {
            controller = content
        }

        let filter = CIColorFilterGroup(filters: item)
        controller?.setFilterValues(filter)

        self.config?.filter = CIFilterItem(filter)
    }
}

fileprivate class CIToneCurveFilter: CIBuiltInFilter {
    convenience init() {
        self.init(name: "CIToneCurve", editableItems: [
            CIFilterAttributeItem(name: "Blacks".localized, attributeKey: "inputPoint0", defaultValue: 0, minimumValue: 0, maximumValue: 1, offset: 1),
            CIFilterAttributeItem(name: "Shadows".localized, attributeKey: "inputPoint1", defaultValue: 0.25, minimumValue: 0, maximumValue: 1, offset: 1),
            CIFilterAttributeItem(name: "Midtones".localized, attributeKey: "inputPoint2", defaultValue: 0.5, minimumValue: 0, maximumValue: 1, offset: 1),
            CIFilterAttributeItem(name: "Highlights".localized, attributeKey: "inputPoint3", defaultValue: 0.75, minimumValue: 0, maximumValue: 1, offset: 1),
            CIFilterAttributeItem(name: "Whites".localized, attributeKey: "inputPoint4", defaultValue: 1.0, minimumValue: 0, maximumValue: 1, offset: 1)
        ])
    }
}

private class RGBChannelCompositing: CIFilter {
    var inputRedImage : CIImage?
    var inputGreenImage : CIImage?
    var inputBlueImage : CIImage?

    let rgbChannelCompositingKernel = CIColorKernel(source:
        "kernel vec4 rgbChannelCompositing(__sample red, __sample green, __sample blue)" +
            "{" +
            "   return vec4(red.r, green.g, blue.b, 1.0);" +
        "}"
    )

    override var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: "RGB Compositing",

            "inputRedImage": [kCIAttributeIdentity: 0,
                              kCIAttributeClass: "CIImage",
                              kCIAttributeDisplayName: "Red Image",
                              kCIAttributeType: kCIAttributeTypeImage],

            "inputGreenImage": [kCIAttributeIdentity: 0,
                                kCIAttributeClass: "CIImage",
                                kCIAttributeDisplayName: "Green Image",
                                kCIAttributeType: kCIAttributeTypeImage],

            "inputBlueImage": [kCIAttributeIdentity: 0,
                               kCIAttributeClass: "CIImage",
                               kCIAttributeDisplayName: "Blue Image",
                               kCIAttributeType: kCIAttributeTypeImage]
        ]
    }

    override var outputImage: CIImage!
    {
        guard let inputRedImage = inputRedImage,
            let inputGreenImage = inputGreenImage,
            let inputBlueImage = inputBlueImage,
            let rgbChannelCompositingKernel = rgbChannelCompositingKernel else
        {
            return nil
        }

        let extent = inputRedImage.extent.union(inputGreenImage.extent.union(inputBlueImage.extent))
        let arguments = [inputRedImage, inputGreenImage, inputBlueImage]

        return rgbChannelCompositingKernel.apply(extent: extent, arguments: arguments)
    }
}

fileprivate class CIColorFilterGroup: CIFilterGroup<CIBuiltInFilter> {
    var filterAttributes: [CIFilterAttributes] {
        return filters.map { $0.filterAttributes.values }.reduce([], +)
    }

    override var outputImage: CIImage? {
        guard let image = inputImage else { return nil }

        let compositing = RGBChannelCompositing()
        autoreleasepool {
            filters[safe: 1]?.setValue(image, forKey: kCIInputImageKey)
            compositing.inputRedImage = filters[safe: 1]?.outputImage
        }
        autoreleasepool {
            filters[safe: 2]?.setValue(image, forKey: kCIInputImageKey)
            compositing.inputGreenImage = filters[safe: 2]?.outputImage
        }
        autoreleasepool {
            filters[safe: 3]?.setValue(image, forKey: kCIInputImageKey)
            compositing.inputBlueImage = filters[safe: 3]?.outputImage
        }

        filters[safe: 0]?.setValue(compositing.outputImage, forKey: kCIInputImageKey)
        return filters[safe: 0]?.outputImage
    }
}

class _CurveEditorAppAsset: _FiltersAppAsset {}

struct CurveEditorResultItem: AppTaskResultable {
    var asset: PHAsset
    var result: [PHAssetEditingResultItem]?

    init(asset: PHAsset, result: [PHAssetEditingResultItem]?) {
        self.asset = asset
        self.result = result
    }
}

public class CurveEditorValue: ImageEditStateValue {}

private class CurveEditorTask: AppTaskPrototype, AppTaskable {
    public typealias ParamType = _CurveEditorAppAsset
    public typealias ResultType = PHAssetResultItem

    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){

        (param as? _CurveEditorAppAsset)?.cancelAllRequestIDs()
        (param as? _CurveEditorAppAsset)?.cancelProcessing()
    }

    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _CurveEditorAppAsset, "TaskParamable type of this app is \(_CurveEditorAppAsset.self)")
        guard let _param = param as? _CurveEditorAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }

    private func _perform(_ assetItem: _CurveEditorAppAsset, _ async: AsyncWaitSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?

        async.begin()

        DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
            assetItem.runEditing({ (progress) in
                AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, editingResultItems, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
                    let filterAttributes = (assetItem.editState.ciFilter as? CIColorFilterGroup)?.filters.map({ $0.filterAttributes.values }).reduce([], +) ?? []

                    var editInfo: [String: Any] = [:]
                    if let jsonData = try? JSONEncoder().encode(filterAttributes), let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? Array<Any> {
                        editInfo["filterAttributes"] = json
                    }

                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: CurveEditorApp.self, editInfo: editInfo, from: asset)

                    result = PHAssetResultItem(
                        asset: assetItem,
                        editingResultItems: editingResultItems,
                        contentEditingOutput: contentEditingOutput)
                }
                async.end()
            }
        }

        async.waitUntilEnd()
        return result
    }
}

class CurveEditorAppDockContent: NSObject, PropertyWatchable, AppDockContent, AppDockDelegate {
    var app: CurveEditorApp?
    convenience init(app: CurveEditorApp) {
        self.init()

        self.app = app
    }

    private lazy var toneCurveControl = CIToneCurveControl(frame: .zero)

    private var channelButtonActions: [UIButton: (() -> Void)] = [:]
    private func createChannelButton(with title: String, tintColor: UIColor? = nil, handler: (() -> Void)? = nil) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        if let tintColor = tintColor {
            button.tintColor = tintColor
        }
        button.addTarget(self, action: #selector(self.channelButtonDidTap), for: .touchUpInside)

        if let handler = handler {
            channelButtonActions[button] = handler
        }
        return button
    }

    @objc private func channelButtonDidTap(sender: UIButton) {
        UIFeedback.select()
        channelButtonActions[sender]?()
    }

    fileprivate var selectedChannel = 0 {
        didSet {
            rgbButton.isSelected = selectedChannel == 0
            redButton.isSelected = selectedChannel == 1
            greenButton.isSelected = selectedChannel == 2
            blueButton.isSelected = selectedChannel == 3
            reloadData()
        }
    }

    private lazy var rgbButton = createChannelButton(with: "RGB", handler: { self.selectedChannel = 0 })
    private lazy var redButton = createChannelButton(with: "R", handler: { self.selectedChannel = 1 })
    private lazy var greenButton = createChannelButton(with: "G", handler: { self.selectedChannel = 2 })
    private lazy var blueButton = createChannelButton(with: "B", handler: { self.selectedChannel = 3 })

    lazy var view: UIView = {
        let view = UIView(frame: .zero)

        rgbButton.isSelected = true

        let stackView = UIStackView(arrangedSubviews: [rgbButton, redButton, greenButton, blueButton])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .fill

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true

        view.addSubview(toneCurveControl)
        toneCurveControl.translatesAutoresizingMaskIntoConstraints = false
        toneCurveControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        toneCurveControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        toneCurveControl.leadingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 8).isActive = true
        toneCurveControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true

        return view
    }()

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = 260
        return preferences
    }

    func willSetContentView(_ view: UIView, dock: AppDock) {

    }

    func didSetContentView(_ view:UIView, dock:AppDock) {
        view.tintColor = view.colorTheme.tintColor

        if colorFilters.isEmpty {
            installFilters()
        }

        reloadData()
    }

    @objc dynamic var filter: CIFilter?

    fileprivate var colorFilters = [CIBuiltInFilter]()

    private func installFilters(with filters: [CIBuiltInFilter]? = nil) {
        colorFilters.removeAll()

        if let filters = filters, filters.count == 4 {
            colorFilters = filters
        }
        else {
            colorFilters = [
                CIToneCurveFilter(),
                CIToneCurveFilter(),
                CIToneCurveFilter(),
                CIToneCurveFilter()
            ]
        }
    }

    fileprivate func setFilterValues(_ filter: CIColorFilterGroup?, animated: Bool = true) {
        guard let filter = filter?.copy() as? CIColorFilterGroup else { return }

        self.installFilters(with: filter.filters)

        DispatchQueue.main.async {
            self.reloadData()
        }
    }

    private func updateChannelButtonStates() {
        redButton.tintColor = colorFilters[safe: 1]?.hasChanges == true ? UIColor(rgb: 0xEC2F4B) : rgbButton.tintColor
        greenButton.tintColor = colorFilters[safe: 2]?.hasChanges == true ? UIColor(rgb: 0x38EF7D) : rgbButton.tintColor
        blueButton.tintColor = colorFilters[safe: 3]?.hasChanges == true ? UIColor(rgb: 0x00C3FF) : rgbButton.tintColor
    }

    private func reloadData() {
        let filter = colorFilters[safe: selectedChannel]

        switch selectedChannel {
        case 1: self.toneCurveControl.highlightedColor = UIColor(rgb: 0xEC2F4B)
        case 2: self.toneCurveControl.highlightedColor = UIColor(rgb: 0x38EF7D)
        case 3: self.toneCurveControl.highlightedColor = UIColor(rgb: 0x00C3FF)
        default: self.toneCurveControl.highlightedColor = .white
        }

        updateChannelButtonStates()

        filter?.editableItems?.enumerated().forEach { idx, item in
            self.toneCurveControl.setItem(item, at: idx)
        }

        self.toneCurveControl.resetHandler = { idx in
            guard let attributeItem = filter?.editableItems?[safe: idx] else { return }

            attributeItem.value = attributeItem.defaultValue
            self.toneCurveControl.setItem(attributeItem, at: idx)

            DispatchQueue.main.async {
                self.markAsEditedFilter(self.colorFilters)
                self.filter = CIColorFilterGroup(filters: self.colorFilters)
                self.updateChannelButtonStates()
            }
        }

        self.toneCurveControl.sliderDidChangeHandler = { idx, value in
            guard let attributeItem = filter?.editableItems?[safe: idx] else { return }

            attributeItem.value = value
            self.toneCurveControl.setToolViewItem(showsButton: attributeItem.hasChanges, at: idx)

            DispatchQueue.main.async {
                self.filter = CIColorFilterGroup(filters: self.colorFilters)
            }
        }
        self.toneCurveControl.sliderDidEndHandler = { idx, value in
            DispatchQueue.main.async {
                self.markAsEditedFilter(self.colorFilters)
                self.filter = CIColorFilterGroup(filters: self.colorFilters)
                self.updateChannelButtonStates()
            }
        }
        self.toneCurveControl.updateCurve()
    }

    private func markAsEditedFilter(_ filters: [CIBuiltInFilter]?) {
        guard let filters = filters else { return }
        self.app?.register(filters.copyElements())
    }
}

// https://github.com/FlexMonkey/ImageToneCurveEditor/tree/master/ToneCurveEditor

fileprivate extension UIBezierPath {
    func interpolatePointsWithHermite(_ interpolationPoints : [CGPoint], alpha: CGFloat = 1.0/3.0) {
        guard !interpolationPoints.isEmpty else { return }
        move(to: interpolationPoints[0])

        let n = interpolationPoints.count - 1

        for index in 0..<n {
            var currentPoint = interpolationPoints[index]
            var nextIndex = (index + 1) % interpolationPoints.count
            var prevIndex = index == 0 ? interpolationPoints.count - 1 : index - 1
            var previousPoint = interpolationPoints[prevIndex]
            var nextPoint = interpolationPoints[nextIndex]
            let endPoint = nextPoint
            var mx : CGFloat
            var my : CGFloat

            if index > 0 {
                mx = (nextPoint.x - previousPoint.x) / 2.0
                my = (nextPoint.y - previousPoint.y) / 2.0
            }
            else {
                mx = (nextPoint.x - currentPoint.x) / 2.0
                my = (nextPoint.y - currentPoint.y) / 2.0
            }

            let controlPoint1 = CGPoint(x: currentPoint.x + mx * alpha, y: currentPoint.y + my * alpha)
            currentPoint = interpolationPoints[nextIndex]
            nextIndex = (nextIndex + 1) % interpolationPoints.count
            prevIndex = index
            previousPoint = interpolationPoints[prevIndex]
            nextPoint = interpolationPoints[nextIndex]

            if index < n - 1 {
                mx = (nextPoint.x - previousPoint.x) / 2.0
                my = (nextPoint.y - previousPoint.y) / 2.0
            }
            else {
                mx = (currentPoint.x - previousPoint.x) / 2.0
                my = (currentPoint.y - previousPoint.y) / 2.0
            }

            let controlPoint2 = CGPoint(x: currentPoint.x - mx * alpha, y: currentPoint.y - my * alpha)

            addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        }
    }
}

fileprivate class CIToneCurveResetControl: DesignableControl {
    var highlightedColor: UIColor? {
        didSet {
            resetButton.setTitleColor(highlightedColor ?? .white, for: .normal)
        }
    }

    private(set) lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("☀︎", for: .normal)
        button.setTitleColor(highlightedColor ?? .white, for: .normal)
        button.addTarget(self, action: #selector(self.resetButtonDidTap), for: .touchUpInside)
        return button
    }()

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.light)
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.textAlignment = .right
        label.backgroundColor = UIColor.clear
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    @objc private func resetButtonDidTap(sender: UIButton) {
        UIFeedback.select()
        sendActions(for: .touchUpInside)
    }

    override func initialize() {
        super.initialize()

        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

        addSubview(resetButton)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor).isActive = true
        resetButton.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: 2).isActive = true
        resetButton.isHidden = true
    }
}

fileprivate class CIToneCurveControl: DesignableView {
    private class CIToneCurveLayer: CALayer {
        var strokeColor: CGColor?
        var lineWidth: CGFloat = 1
        var curveValues: [Float]?

        override func draw(in ctx: CGContext) {
            guard let curveValues = curveValues else { return }

            let path = UIBezierPath()

            let margin = 20
            let thumbRadius = 15
            let widgetWidth = Int(frame.width)
            let widgetHeight = Int(frame.height) - margin - margin - thumbRadius - thumbRadius

            var interpolationPoints : [CGPoint] = [CGPoint]()

            for (i, value) in curveValues.enumerated() {
                let pathPointX = i * (widgetWidth / curveValues.count) + (widgetWidth / curveValues.count / 2)
                let pathPointY = thumbRadius + margin + widgetHeight - Int(Float(widgetHeight) * value)

                interpolationPoints.append(CGPoint(x: pathPointX,y: pathPointY))
            }

            path.interpolatePointsWithHermite(interpolationPoints)

            ctx.setLineJoin(.round)
            ctx.addPath(path.cgPath)
            ctx.setStrokeColor(strokeColor ?? UIColor.yellow.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.strokePath()
        }

        override func action(forKey event: String) -> CAAction? {
            switch event {
            case "bounds", "position": return NSNull()
            default: return super.action(forKey: event)
            }
        }
    }

    private lazy var sliderView: UIStackView = {
        let view = UIStackView(frame: .zero)
        view.alignment = UIStackView.Alignment.fill
        view.distribution = UIStackView.Distribution.fillProportionally
        view.axis = NSLayoutConstraint.Axis.horizontal
        return view
    }()

    private lazy var toolView: UIStackView = {
        let view = UIStackView(frame: .zero)
        view.alignment = UIStackView.Alignment.fill
        view.distribution = UIStackView.Distribution.fillProportionally
        view.axis = NSLayoutConstraint.Axis.horizontal
        return view
    }()

    private lazy var curveLayer: CIToneCurveLayer = {
        let layer = CIToneCurveLayer()
        layer.strokeColor = UIColor.init(white: 0.5, alpha: 1).cgColor
        layer.lineWidth = 1
        return layer
    }()

    override func initialize() {
        super.initialize()

        layer.addSublayer(curveLayer)

        addSubview(sliderView)
        addSubview(toolView)

        toolView.translatesAutoresizingMaskIntoConstraints = false
        toolView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        toolView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        toolView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        toolView.heightAnchor.constraint(equalToConstant: 44).isActive = true

        sliderView.translatesAutoresizingMaskIntoConstraints = false
        sliderView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        sliderView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        sliderView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        sliderView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        for slider in sliders {
            sliderView.addArrangedSubview(slider)

            let resetControl = CIToneCurveResetControl(frame: .zero)
            resetControl.addTarget(self, action: #selector(self.resetButtonDidTap), for: .touchUpInside)
            resetControl.highlightedColor = CurveEditorApp.info.themeColor
            toolView.addArrangedSubview(resetControl)
        }

        updateCurve()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layoutIfNeeded()
    }

    override func layoutIfNeeded() {
        super.layoutIfNeeded()

        curveLayer.frame = sliderView.bounds
        updateCurve()
    }

    @objc fileprivate func updateCurve() {
        curveLayer.curveValues = sliders.map { $0.value }
        curveLayer.setNeedsDisplay()
    }

    private func generateSlider() -> PrecisionLevelSlider {
        let slider = PrecisionLevelSlider(axis: .vertical)
        slider.longNotchColor = .white
        slider.shortNotchColor = UIColor.init(white: 0.5, alpha: 1)
        slider.centerNotchColor = CurveEditorApp.info.themeColor ?? .red
        slider.numberOfNotches = 20

        slider.addTarget(self, action: #selector(self.updateCurve), for: .scrollDidChanged)
        slider.addTarget(self, action: #selector(self.sliderValueChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(self.sliderDidBegin), for: .scrollDidBegin)
        slider.addTarget(self, action: #selector(self.sliderDidEnd), for: .scrollDidEnd)
        return slider
    }

    private(set) lazy var sliders: [PrecisionLevelSlider] = {
        return (0...4).map { _ in generateSlider() }
    }()

    override func tintColorDidChange() {
        super.tintColorDidChange()

        sliders.forEach { $0.tintColor = self.tintColor }
    }

    var highlightedColor: UIColor? {
        didSet {
            sliders.forEach { $0.centerNotchColor = highlightedColor ?? CurveEditorApp.info.themeColor ?? .red }
            toolView.arrangedSubviews.forEach { ($0 as? CIToneCurveResetControl)?.highlightedColor = highlightedColor ?? CurveEditorApp.info.themeColor }
        }
    }

    func setItem(_ item: CIFilterAttributeItem, at index: Int) {
        setToolViewItem(title: item.name, showsButton: item.hasChanges, at: index)
        setValue(item.value, defaultValue: item.defaultValue, range: item.minimumValue...item.maximumValue, at: index)
    }

    private func setToolViewItem(title: String, showsButton: Bool, at index: Int) {
        let resetControl = toolView.arrangedSubviews[safe: index] as? CIToneCurveResetControl
        resetControl?.titleLabel.text = title
        resetControl?.titleLabel.textColor = .white

        resetControl?.resetButton.isHidden = !showsButton
    }

    func setToolViewItem(showsButton: Bool, at index: Int) {
        let resetControl = toolView.arrangedSubviews[safe: index] as? CIToneCurveResetControl
        resetControl?.resetButton.isHidden = !showsButton
    }

    private func setValue(_ value: Float, defaultValue: Float, range: ClosedRange<Float>, at index: Int) {
        let slider = sliders[safe: index]
        slider?.minimumValue = range.lowerBound
        slider?.maximumValue = range.upperBound
        slider?.defaultValue = defaultValue
        slider?.value = value
    }

    private func setValue(_ value: Float, at index: Int) {
        let slider = sliders[safe: index]
        slider?.value = value
    }

    var resetHandler: ((Int) -> Void)?
    var sliderDidChangeHandler: ((Int, Float) -> Void)?
    var sliderDidBeginHandler: ((Int, Float) -> Void)?
    var sliderDidEndHandler: ((Int, Float) -> Void)?

    @objc private func resetButtonDidTap(sender: CIToneCurveResetControl) {
        guard let idx = toolView.arrangedSubviews.firstIndex(of: sender) else { return }
        self.resetHandler?(idx)
    }

    @objc private func sliderValueChanged(sender: PrecisionLevelSlider) {
        guard let idx = sliders.firstIndex(of: sender) else { return }
        self.sliderDidChangeHandler?(idx, sender.value)
    }

    @objc private func sliderDidBegin(sender: PrecisionLevelSlider) {
        guard let idx = sliders.firstIndex(of: sender) else { return }
        self.sliderDidBeginHandler?(idx, sender.value)
    }

    @objc private func sliderDidEnd(sender: PrecisionLevelSlider) {
        guard let idx = sliders.firstIndex(of: sender) else { return }
        self.sliderDidEndHandler?(idx, sender.value)
    }
}
