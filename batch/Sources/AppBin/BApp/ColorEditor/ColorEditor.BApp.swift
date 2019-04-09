//
//  ColorEditor.BApp.swift
//  pap
//
//  Created by HYOJIN MO on 28/02/2019.
//  Copyright © 2019 Stells. All rights reserved.
//

import UIKit
import PropertyKit
import Photos

protocol ColorEditorDefaults: AppDefaults {
    var colorFilters: [CIBuiltInFilter] { get set }
}

extension Defaults: ColorEditorDefaults {
    internal var colorFilters: [CIBuiltInFilter] {
        set { set(newValue); papLog.app.defaults.log(value:String(describing: newValue)) }
        get { return get(or: []) }
    }
}

class ColorEditorApp: NSObject, BApp, PropertyWatchable, ConfigurableApp, _ConfigurableApp,
    PHAssetFinalizableApp, EditableApp, UndoableApp, PreviewProcessableApp, AppDockApp,
PhotoPickerCollectionViewDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp, PhotoEditorViewControllerDelegatableApp {
    public static let taskType: AppTaskable.Type = ColorEditorTask.self
    
    public static let paramType: AppTaskParamable.Type = _ColorEditorAppAsset.self
    
    public static var defaultConfigValue: AppConfigValuable {
        let config = FiltersAppConfigValue()
        return config
    }
    
    @objc dynamic
    public private(set) lazy var config: FiltersAppConfigValue? = type(of:self).defaultConfigValue as? FiltersAppConfigValue
    
    public private(set) lazy var content: AppDockContent? = ColorEditorAppDockContent(app: self)
    public private(set) lazy var photoEditorDockContent: AppDockContent? = ColorEditorAppDockContent()
    
    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {
        defaultEditStateValue = editStateValue
        
        if var defaults = type(of: self).defaults as? ColorEditorDefaults, let filter = editStateValue?.ciFilter as? CIColorFilterGroup {
            defaults.colorFilters = filter.filters
        }
    }
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.coloreditor"
        , version: "0.1"
        , phase: .beta
        , appType: ColorEditorApp.self
        , displayName: "Curve Tool".localized.localizedCapitalized
        , description: "Curve Tool".localized
        , keywords: ["Curve", "Color", "RGB"]
        , iconBundleName: nil
        , themeColor: UIColor(rgb: 0x49CE8A)
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    required public override init() {
        super.init()
        
        let controllerContent = self.content as? ColorEditorAppDockContent
        controllerContent?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContent?.filter {
                self.config?.filter = CIFilterItem(filter)
            }
            else if var defaults = type(of: self).defaults as? ColorEditorDefaults {
                let filter = CIColorFilterGroup(filters: defaults.colorFilters)

                let filterItem = CIFilterItem(filter)
                self.config?.filter = filterItem
                self.defaultEditStateValue = filterItem
            }
        }
        
        let controllerContentInPhotoEditor = self.photoEditorDockContent as? ColorEditorAppDockContent
        controllerContentInPhotoEditor?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContentInPhotoEditor?.filter {
                self.config?.filter = CIFilterItem(filter)
            }
            else if var defaults = type(of: self).defaults as? ColorEditorDefaults {
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
    
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?) {
        if let filter = editStateValue?.ciFilter as? CIColorFilterGroup {
            (content as? ColorEditorAppDockContent)?.setFilterValues(filter, animated: false)
            
            if self.undoStack.isEmpty {
                self.registerUndo(filter.filters)
            }
        }
    }
    
    public var undoStack: [[CIBuiltInFilter]] = [[CIBuiltInFilter]]()
    public var undoItemIndex: Int = 0

    public func undoItemIndexDidChange(_ item: Array<CIBuiltInFilter>?) {
        var controller: ColorEditorAppDockContent?
        if let content = self.content as? ColorEditorAppDockContent {
            controller = content
        }
        else if let content = self.photoEditorDockContent as? ColorEditorAppDockContent {
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

fileprivate class CIColorFilterGroup: CIFilterGroup<CIBuiltInFilter> {
    var filterAttributes: [CIFilterAttributes] {
        return filters.map { $0.filterAttributes.values }.reduce([], +)
    }
}

class _ColorEditorAppAsset: _FiltersAppAsset {}

struct ColorEditorResultItem: AppTaskResultable {
    var asset: PHAsset
    var result: [PHAssetEditingResultItem]?
    
    init(asset: PHAsset, result: [PHAssetEditingResultItem]?) {
        self.asset = asset
        self.result = result
    }
}

public class ColorEditorValue: ImageEditStateValue {}

private class ColorEditorTask: AppTaskPrototype, AppTaskable {
    public typealias ParamType = _ColorEditorAppAsset
    public typealias ResultType = PHAssetResultItem
    
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){
        
        (param as? _ColorEditorAppAsset)?.cancelAllRequestIDs()
        (param as? _ColorEditorAppAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _ColorEditorAppAsset, "TaskParamable type of this app is \(_ColorEditorAppAsset.self)")
        guard let _param = param as? _ColorEditorAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _ColorEditorAppAsset, _ async: AsyncWaitSignalable) throws -> PHAssetResultItem?  {
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
                    
                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: ColorEditorApp.self, editInfo: editInfo, from: asset)
                    
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

class ColorEditorAppDockContent: NSObject, PropertyWatchable, AppDockContent, AppDockDelegate {
    var app: ColorEditorApp?
    convenience init(app: ColorEditorApp) {
        self.init()
        
        self.app = app
    }
    
    lazy var view: UIView = {
        let toneCurveControl = CIToneCurveControl(frame: .zero)
        return toneCurveControl
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
        
        if let filters = filters, !filters.isEmpty {
            colorFilters = filters
        }
        else {
            colorFilters = [CIToneCurveFilter()]
        }
    }
    
    fileprivate func setFilterValues(_ filter: CIColorFilterGroup?, animated: Bool = true) {
        guard let filter = filter?.copy() as? CIColorFilterGroup else { return }
        
        self.installFilters(with: filter.filters)
        
        DispatchQueue.main.async {
            self.reloadData()
        }
    }
    
    private func reloadData() {
        guard let control = view as? CIToneCurveControl else { return }
        let filter = colorFilters.first
        
        filter?.editableItems?.enumerated().forEach { idx, item in
            control.setItem(item, at: idx)
        }
        
        control.resetHandler = { idx in
            guard let attributeItem = filter?.editableItems?[safe: idx] else { return }
            
            attributeItem.value = attributeItem.defaultValue
            control.setItem(attributeItem, at: idx)
            
            DispatchQueue.main.async {
                self.markAsEditedFilter(self.colorFilters)
                self.filter = CIColorFilterGroup(filters: self.colorFilters)
            }
        }
        
        control.sliderDidChangeHandler = { idx, value in
            guard let attributeItem = filter?.editableItems?[safe: idx] else { return }
            
            attributeItem.value = value
            control.setToolViewItem(showsButton: attributeItem.hasChanges, at: idx)
            
            DispatchQueue.main.async {
                self.filter = CIColorFilterGroup(filters: self.colorFilters)
            }
        }
        control.sliderDidEndHandler = { idx, value in
            DispatchQueue.main.async {
                self.markAsEditedFilter(self.colorFilters)
                self.filter = CIColorFilterGroup(filters: self.colorFilters)
            }
        }
        control.updateCurve()
    }
    
    private func markAsEditedFilter(_ filters: [CIBuiltInFilter]?) {
        guard let filters = filters else { return }
        self.app?.registerUndo(filters.copyElements())
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
        toolView.heightAnchor.constraint(lessThanOrEqualToConstant: 44).isActive = true
        
        sliderView.translatesAutoresizingMaskIntoConstraints = false
        sliderView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        sliderView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        sliderView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        sliderView.bottomAnchor.constraint(equalTo: toolView.topAnchor).isActive = true
        
        for slider in sliders {
            sliderView.addArrangedSubview(slider)
            
            let resetControl = CIToneCurveResetControl(frame: .zero)
            resetControl.addTarget(self, action: #selector(self.resetButtonDidTap), for: .touchUpInside)
            resetControl.highlightedColor = ColorEditorApp.info.themeColor
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
        slider.centerNotchColor = ColorEditorApp.info.themeColor ?? .red
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
