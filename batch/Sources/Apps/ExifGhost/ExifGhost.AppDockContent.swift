//
// Created by BLACKGENE on 16/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit

private protocol ExifGhostAppDefaults: AppDefaults{
    var handledProperties:[String:[String]] {get set}
}

extension ExifGhostAppDefaults{
    fileprivate func addHandledProperty(_ dictionary:String, _ property:String){
        guard ImageMetadata.supportedDictionaries.contains(dictionary) else{
            assert(false, "\(dictionary) is not supported dictionary")
            return
        }

        var immutableSelf = self
        if immutableSelf.handledProperties[dictionary] == nil{
            immutableSelf.handledProperties = [String:[String]]()
            var p = immutableSelf.handledProperties
            p[dictionary] = [property]
            immutableSelf.handledProperties = p
        }else{
            if handledProperties[dictionary]?.contains(property) == false{
                var p = immutableSelf.handledProperties
                p[dictionary]?.append(property)
                immutableSelf.handledProperties = p
            }
        }
    }

    fileprivate func removeHandledProperty(_ dictionary:String, _ property:String){
        guard ImageMetadata.supportedDictionaries.contains(dictionary) else{
            assert(false, "\(dictionary) is not supported dictionary")
        }

        if let index = handledProperties[dictionary]?.index(of: property){
            var immutableSelf = self
            var p = immutableSelf.handledProperties
            p[dictionary]?.remove(at: index)
            immutableSelf.handledProperties = p
        }
    }
}

extension Defaults: ExifGhostAppDefaults {
    fileprivate var handledProperties: [String:[String]] {
        set{ set(newValue) }

        get{ return get(or:[
            ImageMetadata.Dictionary.GPS: [
                ImageMetadata.Keys.GPSDateStamp
                , ImageMetadata.Keys.GPSDateStamp
                , ImageMetadata.Keys.GPSAltitude
                , ImageMetadata.Keys.GPSAltitudeRef
                , ImageMetadata.Keys.GPSLatitude
                , ImageMetadata.Keys.GPSLatitudeRef
                , ImageMetadata.Keys.GPSLongitude
                , ImageMetadata.Keys.GPSLongitudeRef
                , ImageMetadata.Keys.GPSImgDirection
                , ImageMetadata.Keys.GPSImgDirectionRef
            ],
            ImageMetadata.Dictionary.EXIF: [
                ImageMetadata.Keys.ExifDateTimeDigitized
                , ImageMetadata.Keys.ExifDateTimeOriginal
                , ImageMetadata.Keys.ExifLensMake
                , ImageMetadata.Keys.ExifLensModel
                , ImageMetadata.Keys.ExifLensSerialNumber
                , ImageMetadata.Keys.ExifLensSerialNumber
                , ImageMetadata.Keys.ExifSubsecTime
                , ImageMetadata.Keys.ExifSubsecTimeOriginal
                , ImageMetadata.Keys.ExifSubsecTimeDigitized
            ],
            ImageMetadata.Dictionary.TIFF: [
                ImageMetadata.Keys.TIFFDateTime
                , ImageMetadata.Keys.TIFFArtist
                , ImageMetadata.Keys.TIFFCopyright
                , ImageMetadata.Keys.TIFFDocumentName
                , ImageMetadata.Keys.TIFFSoftware
                , ImageMetadata.Keys.TIFFMake
                , ImageMetadata.Keys.TIFFModel
                , ImageMetadata.Keys.TIFFImageDescription
                , ImageMetadata.Keys.TIFFHostComputer
            ],
        ]) }
    }
}

private struct MetadataItem{
    fileprivate var key:String
    fileprivate var label:String
}

private struct MetadataDictionary{
    fileprivate var key:String
    fileprivate var label:String
    fileprivate var items:[MetadataItem]
}

class ExifGhostAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    private let items:[MetadataDictionary] = [
        MetadataDictionary(key:ImageMetadata.Dictionary.EXIF, label: "EXIF",
                items: ImageMetadata.Keys.EXIF.map { key -> MetadataItem in
                    return MetadataItem(key:key, label: ImageMetadata.LabelsForKeys.EXIF[key] ?? key)
                }),

        MetadataDictionary(key:ImageMetadata.Dictionary.GPS, label: "GPS",
                items: ImageMetadata.Keys.GPS.map { key -> MetadataItem in
                    return MetadataItem(key:key, label: ImageMetadata.LabelsForKeys.GPS[key] ?? key)
                }),

        MetadataDictionary(key:ImageMetadata.Dictionary.TIFF, label: "TIFF",
                items: ImageMetadata.Keys.TIFF.map { key -> MetadataItem in
                    return MetadataItem(key:key, label: ImageMetadata.LabelsForKeys.TIFF[key] ?? key)
                })
    ]

    private var initialSelectedIndexPaths:[IndexPath]? = [IndexPath]()

    var view: UIView{
        let view = UITableView()
        view.dataSource = self
        view.delegate = self
        view.rowHeight = 44
        view.allowsSelection = false
        view.allowsMultipleSelection = false
        view.register(Cell.self, forCellReuseIdentifier: ExifGhost.info.identifier)
        return view
    }

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.minimumHeight = (self.view as! UITableView).rowHeight * 5
        preferences.pinned = false
        return preferences
    }

    fileprivate var appDefaults:ExifGhostAppDefaults?{
        return (AppCenter.default.current as? PersistableApp.Type)?.defaults as? ExifGhostAppDefaults
    }

    func didSetContentView(_ view:UIView) {

        if let defaultsProperties = self.appDefaults?.handledProperties{
            let sections = self.items.enumerated().compactMap { (section, dictionary) -> [IndexPath]? in
                if let handledItems = defaultsProperties[dictionary.key]{
                    print(handledItems)
                    print(dictionary.items)

                    return handledItems.compactMap { key -> IndexPath? in
                        guard let item = dictionary.items.index(where: { item -> Bool in
                            return key == item.key
                        }) else{
                            return nil
                        }
                        return IndexPath(item: item, section: section)
                    }
                }
                return nil
            }

            for indexPaths in sections{
                initialSelectedIndexPaths?.append(contentsOf: indexPaths)
            }
        }

        (view as! UITableView).reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return items[section].label
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].items.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dict = self.items[indexPath.section]

        var selected = false
        if let _ = initialSelectedIndexPaths?.index(of: indexPath) {
            selected = true
        }
        if let appDefaults = appDefaults
        , let _ = appDefaults.handledProperties[dict.key]?.index(of: dict.items[indexPath.item].key){
            selected = true
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: ExifGhost.info.identifier) as! Cell
        cell.textLabel?.text = dict.items[indexPath.item].label
        cell.optionSwitch.setOn(selected, animated: false)
        cell.switchDidChange = { on in
            let dict = self.items[indexPath.section]
            if on{
                self.appDefaults?.addHandledProperty(dict.key, dict.items[indexPath.item].key)
            }else{
                self.appDefaults?.removeHandledProperty(dict.key, dict.items[indexPath.item].key)
            }

            if self.initialSelectedIndexPaths != nil{
                self.initialSelectedIndexPaths = nil
            }
        }
        return cell
    }

    func createSelectedBackgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        return view
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
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryView = optionSwitch
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func cellSwitchDidChange(sender: UISwitch) {
        switchDidChange?(sender.isOn)
    }
}