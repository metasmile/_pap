//
//  App.UI.VideoTrimControl.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 7. 16..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class AppUIVideoTrimControl: UIView {
    private var duration: CMTime = kCMTimeZero
    private var trimmingRange: CMTimeRange = kCMTimeRangeZero
    
    var minimumDuration: CMTime = kCMTimeZero
    var maximumDuration: CMTime = kCMTimeZero
    
    private lazy var timelineView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.bounces = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    private lazy var imageGenerator: AVAssetImageGenerator? = {
        guard let video = video else { return nil }
        let imageGenerator = AVAssetImageGenerator(asset: video)
        return imageGenerator
    }()
    
    private var timeline = [CMTime]()
    
    var asset: PHAsset? {
        didSet {
            guard let asset = asset, let video = asset.asAVAsset else { return }
            
            self.video = video
            
            self.timelineCellSize = AVMakeRect(aspectRatio: asset.pixelSize, insideRect: bounds).size
            let numberOfCells = ceil(timelineCellSize.width / bounds.width)
            print(numberOfCells, timelineCellSize.width / bounds.width)
            
        }
    }
    
    var video: AVAsset? {
        didSet {
            guard let video = video else { return }
            duration = video.duration
            trimmingRange = CMTimeRangeMake(kCMTimeZero, duration)
        }
    }
    
    private var timelineCellSize: CGSize = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        addSubview(timelineView)
        timelineView.fitConstraints(to: self)
        
        timelineView.dataSource = self
        timelineView.delegate = self
    }
}

extension AppUIVideoTrimControl: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return timeline.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AppUIVideoTrimTimelineCell.reuseIdentifier, for: indexPath) as! AppUIVideoTrimTimelineCell
        return cell
    }
}

extension AppUIVideoTrimControl: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return timelineCellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

private class AppUIVideoTrimTimelineCell: UICollectionViewCell {
    class var reuseIdentifier: String {
        return "AppUIVideoTrimTimelineCell"
    }
}
