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
            immutableSelf.handledProperties[dictionary] = [property]
        }else{
            if handledProperties[dictionary]?.contains(property) == true{
                immutableSelf.handledProperties[dictionary]?.append(property)
            }
        }
    }

    fileprivate func removeHandledProperty(_ dictionary:String, _ property:String){
        guard ImageMetadata.supportedDictionaries.contains(dictionary) else{
            assert(false, "\(dictionary) is not supported dictionary")
        }

        if let index = handledProperties[dictionary]?.index(of: property){
            var immutableSelf = self
            immutableSelf.handledProperties[dictionary]?.remove(at: index)
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
        view.allowsMultipleSelection = true
        view.rowHeight = UITableViewAutomaticDimension
        return view
    }

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.minimumHeight = 200
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

//    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
//
//    }
//
//    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
//
//    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .none

        initialSelectedIndexPaths = nil

        let dict = items[indexPath.section].key
        let prop = items[indexPath.section].items[indexPath.item].key
        appDefaults?.addHandledProperty(dict, prop)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark

        initialSelectedIndexPaths = nil

        let dict = items[indexPath.section].key
        let prop = items[indexPath.section].items[indexPath.item].key
        appDefaults?.removeHandledProperty(dict, prop)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "myIdentifier")

        cell.textLabel?.text = items[indexPath.section].items[indexPath.item].label
//        cell.detailTextLabel?.text = "ok. my first UITableView"

        if cell.multipleSelectionBackgroundView == nil{
            cell.multipleSelectionBackgroundView = createSelectedBackgroundView()
        }

        let targetSelectedIndexPaths = initialSelectedIndexPaths ?? tableView.indexPathsForSelectedRows
        let selected = targetSelectedIndexPaths?.contains(indexPath) == true

        cell.accessoryType = selected ? .checkmark : .none
        cell.isSelected = selected
        // cell.accessoryView <- Ghost Icon

        return cell
    }

    func createSelectedBackgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        return view
    }
}
