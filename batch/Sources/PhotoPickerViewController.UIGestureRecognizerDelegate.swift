//
// Created by BLACKGENE on 12/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PhotoPickerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == dragSelectionGesture {
            let velocity = dragSelectionGesture.velocity(in: dragSelectionGesture.view)
            return velocity.x.magnitude > velocity.y.magnitude
        }

        let touchLocation = gestureRecognizer.location(in: gestureRecognizer.view)
        if let indexPath = photoCollectionView.indexPathForItem(at: touchLocation){
            let touchEnabled = self.collectionView(self.photoCollectionView, shouldSelectItemAt: indexPath)

            //TODO: static
            if touchEnabled == false{
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }

            return touchEnabled
        }

        return true
    }

    @objc func dragSelectionGestureDidRecognize(sender: DragSelectionGestureRecognizer) {
        let touchLocation = sender.location(in: sender.view)

        switch sender.state {
        case .began:
            dragSelectionGesture.reset()

            guard let indexPath = photoCollectionView.indexPathForItem(at: touchLocation) else { return }
            dragSelectionGesture.selectionMode = photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == true ? .deselect : .select
            dragSelectionGesture.beginIndexPath = indexPath
            dragSelectionGesture.beginLocation = touchLocation

            dragSelection(with: [indexPath])

            dragSelectionGesture.ignoredIndexPaths = photoCollectionView.indexPathsForSelectedItems

            photoCollectionView.isScrollEnabled = false
        case .changed:
            drag(at: touchLocation, with: sender.selectionMode)
            panWithDragging(at: touchLocation)
        default:
            photoCollectionView.isScrollEnabled = true
            sender.reset()
        }
        updateSelectedItemUIs()
    }

    private func drag(at location: CGPoint, with selectionMode: DragSelectionGestureRecognizer.DragSelectionMode) {
        guard
                let beginLocation = dragSelectionGesture.beginLocation,
                let beginIndexPath = dragSelectionGesture.beginIndexPath
                else { return }

        var draggingArea = CGRect(x: min(beginLocation.x, location.x), y: min(beginLocation.y, location.y), width: (beginLocation.x - location.x).magnitude, height: (beginLocation.y - location.y).magnitude)
        draggingArea.origin.x = 0
        draggingArea.size.width = photoCollectionView.bounds.width

        var groupDirection = DragSelectionGestureRecognizer.AutoPanningDirection.none
        if let currentIndexPath = photoCollectionView.indexPathForItem(at: location) {
            let beginRow = beginIndexPath.item / Int(kPhotoPickerNumberOfItemsInRow)
            let currentRow = currentIndexPath.item / Int(kPhotoPickerNumberOfItemsInRow)

            let diffRow = currentRow - beginRow
            if diffRow > 0 {
                groupDirection = .down
            }
            else if diffRow < 0 {
                groupDirection = .up
            }
        }
        else {
            let diffLocation = location.y - beginLocation.y
            if diffLocation > 0 {
                groupDirection = .down
            }
            else if diffLocation < 0 {
                groupDirection = .up
            }
        }

        var groupedIndexPaths = [IndexPath]()
        photoCollectionView.collectionViewLayout.layoutAttributesForElements(in: draggingArea)?.forEach { layoutAttributes in
            let indexPath = layoutAttributes.indexPath

            if let currentIndexPath = photoCollectionView.indexPathForItem(at: location) {
                switch groupDirection {
                case .down:
                    guard indexPath >= beginIndexPath, indexPath <= currentIndexPath else { return }
                case .up:
                    guard indexPath <= beginIndexPath, indexPath >= currentIndexPath else { return }
                default:
                    if currentIndexPath < beginIndexPath { // pan to left
                        guard indexPath <= beginIndexPath, indexPath >= currentIndexPath else { return }
                    }
                    else if currentIndexPath > beginIndexPath { // pan to right
                        guard indexPath >= beginIndexPath, indexPath <= currentIndexPath else { return }
                    }
                    else {
                        guard currentIndexPath == indexPath else { return }
                    }
                }
            }
            else {
                switch groupDirection {
                case .down:
                    guard indexPath >= beginIndexPath else { return }
                case .up:
                    guard indexPath <= beginIndexPath else { return }
                default:
                    return
                }
            }
            groupedIndexPaths.append(indexPath)
        }

        var ignoredIndexPaths = [IndexPath]()
        if selectionMode == .select {
            photoCollectionView.indexPathsForSelectedItems?.forEach { indexPath in
                guard
                        dragSelectionGesture.ignoredIndexPaths?.contains(indexPath) == false,
                        !groupedIndexPaths.contains(indexPath)
                        else { return }

                ignoredIndexPaths.append(indexPath)
            }

            dragDeselection(with: ignoredIndexPaths)
            dragSelection(with: groupedIndexPaths)
        }
        else if selectionMode == .deselect {
            dragSelectionGesture.ignoredIndexPaths?.forEach { indexPath in
                guard !groupedIndexPaths.contains(indexPath) else { return }
                ignoredIndexPaths.append(indexPath)
            }

            photoCollectionView.indexPathsForSelectedItems?.forEach { indexPath in
                guard !groupedIndexPaths.contains(indexPath), !ignoredIndexPaths.contains(indexPath) else { return }
                ignoredIndexPaths.append(indexPath)
            }

            dragDeselection(with: groupedIndexPaths)
            dragSelection(with: ignoredIndexPaths)
        }
    }

    private func dragSelection(with indexPaths: [IndexPath]) {
        _ = indexPaths.map({ self.dragSelection(at: $0) })
    }

    private func dragDeselection(with indexPaths: [IndexPath]) {
        _ = indexPaths.map({ self.dragDeselection(at: $0) })
    }

    private func dragSelection(at indexPath: IndexPath) {
        self.selectCollectionViewItem(at: indexPath)
    }

    private func dragDeselection(at indexPath: IndexPath) {
        if photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == true {
            photoCollectionView.deselectItem(at: indexPath, animated: false)
            collectionView(photoCollectionView, didDeselectItemAt: indexPath)
        }
    }

    private func panWithDragging(at location: CGPoint) {
        let pointInScreen = photoCollectionView.convert(location, to: view)
        let boundingInsets = appDockInsets
        let boundingArea = UIEdgeInsetsInsetRect(photoCollectionView.frame, boundingInsets)
        guard !boundingArea.contains(pointInScreen) else {
            dragSelectionGesture.stopAutoPanning()
            return
        }

        var panVelocity: CGFloat = 0
        let scrollDirection: DragSelectionGestureRecognizer.AutoPanningDirection = (pointInScreen.y <= boundingArea.minY) ? .up : .down
        switch scrollDirection {
        case .up:
            panVelocity = (boundingInsets.top - pointInScreen.y) / boundingInsets.top
            dragSelectionGesture.panAutomatically { [weak self] in
                guard let collectionView = self?.photoCollectionView else { return }
                let autoPanningOffsetY = collectionView.contentOffset.y - DragSelectionGestureRecognizer.kSTDragSelectionGestureRecognizerAutoPanningIncrement * panVelocity
                let beginOfContentOffsetY = -boundingInsets.top
                if autoPanningOffsetY > beginOfContentOffsetY {
                    collectionView.contentOffset.y = autoPanningOffsetY
                }
                else {
                    collectionView.contentOffset.y = beginOfContentOffsetY
                }
            }
        case .down:
            panVelocity = (pointInScreen.y - boundingArea.maxY) / boundingInsets.bottom
            dragSelectionGesture.panAutomatically { [weak self] in
                guard let collectionView = self?.photoCollectionView else { return }
                let autoPanningOffsetY = collectionView.contentOffset.y + DragSelectionGestureRecognizer.kSTDragSelectionGestureRecognizerAutoPanningIncrement * panVelocity
                let endOfContentOffsetY = collectionView.contentSize.height - (self?.appDockView?.frame.minY ?? 0)
                if autoPanningOffsetY < endOfContentOffsetY {
                    collectionView.contentOffset.y = autoPanningOffsetY
                }
                else {
                    collectionView.contentOffset.y = endOfContentOffsetY
                }
            }
        default:
            break
        }
    }
}
