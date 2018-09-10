//
// Created by BLACKGENE on 12/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PhotoPickerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard !AppCenter.default.task.isRunning else { return false }
        
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
            
            UIViewController.root?.view.isUserInteractionEnabled = false
            photoCollectionView.isScrollEnabled = false
        case .changed:
            if !panWithDragging(at: touchLocation, with: sender.selectionMode) {
                drag(at: touchLocation, with: sender.selectionMode)
            }
        default:
            UIViewController.root?.view.isUserInteractionEnabled = true
            photoCollectionView.isScrollEnabled = true
            
            sender.reset()
            
            batchPreviewView.updatePreviews(forced: true)
        }
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
            let beginRow = beginIndexPath.item / Int(numberOfItemsInRow)
            let currentRow = currentIndexPath.item / Int(numberOfItemsInRow)

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

        let groupedIndexPaths = NSMutableOrderedSet()
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
            groupedIndexPaths.add(indexPath)
        }
        
        let currentSelectionSet = Set<IndexPath>(photoCollectionView.indexPathsForSelectedItems ?? [])
        
        if selectionMode == .select {
            let deselectedSet = currentSelectionSet.subtracting(groupedIndexPaths.set as! Set<IndexPath>)
            let deselectedIndexPaths = Array(deselectedSet).filter { dragSelectionGesture.ignoredIndexPathInfo?[$0] != true }
            
            groupedIndexPaths.minusSet(currentSelectionSet)
            var selectedIndexPaths = groupedIndexPaths.compactMap { $0 as? IndexPath }
            
            selectedIndexPaths.sort()
            if groupDirection == .up {
                selectedIndexPaths.reverse()
            }

            dragDeselection(with: deselectedIndexPaths)
            dragSelection(with: selectedIndexPaths)
        }
        else if selectionMode == .deselect {
            var selectedIndexPaths = [IndexPath]()
            if let ignoredSet = dragSelectionGesture.ignoredIndexPathSet {
                let selectedSet = NSMutableOrderedSet(orderedSet: ignoredSet, copyItems: true)
                selectedSet.minusSet(currentSelectionSet)
                selectedSet.minusSet(groupedIndexPaths.set)
                selectedIndexPaths.append(contentsOf: selectedSet.array.compactMap { $0 as? IndexPath })
            }
            
            dragDeselection(with: groupedIndexPaths.compactMap { $0 as? IndexPath })
            dragSelection(with: selectedIndexPaths)
        }
    }

    private func dragSelection(with indexPaths: [IndexPath]) {
        indexPaths.forEach({ self.dragSelection(at: $0) })
    }

    private func dragDeselection(with indexPaths: [IndexPath]) {
        let assets = indexPaths.compactMap { PHAssets.fetched.asset(at: $0) }
        
        indexPaths.forEach({ self.photoCollectionView.deselectItem(at: $0, animated: false) })
        batchPreviewView.removeCollectionViewItems(with: assets)
        
        updateUIDisplays()
        updateVisibleCellsEnabled()
    }

    private func dragSelection(at indexPath: IndexPath) {
        self.selectCollectionViewItem(at: indexPath)
    }

    private func panWithDragging(at location: CGPoint, with selectionMode: DragSelectionGestureRecognizer.DragSelectionMode) -> Bool {
        let pointInScreen = photoCollectionView.convert(location, to: view)
        let boundingInsets = appDockInsets
        let boundingArea = UIEdgeInsetsInsetRect(photoCollectionView.frame, boundingInsets)
        guard !boundingArea.contains(pointInScreen) else {
            dragSelectionGesture.stopAutoPanning()
            return false
        }
        
        let beginContentOffset = photoCollectionView.contentOffset

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
                let diatanceY = collectionView.contentOffset.y - beginContentOffset.y
                let estimatedTouchLocation = CGPoint(x: location.x, y: location.y + diatanceY)
                self?.drag(at: estimatedTouchLocation, with: selectionMode)
            }
        case .down:
            panVelocity = (pointInScreen.y - boundingArea.maxY) / boundingInsets.top
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
                let diatanceY = collectionView.contentOffset.y - beginContentOffset.y
                let estimatedTouchLocation = CGPoint(x: location.x, y: location.y + diatanceY)
                self?.drag(at: estimatedTouchLocation, with: selectionMode)
            }
        default:
            break
        }
        
        return true
    }
}
