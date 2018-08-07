//
// Created by BLACKGENE on 20/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

//TODO: reactive style -> when(tap: .. ).when(pinch: .. ).when(swipe: .. )

extension UIView {

    // In order to create computed properties for extensions, we need a key to
    // store and access the stored property
    fileprivate struct AssociatedObjectKeys {
        static var tapGestureRecognizer = "MediaViewerAssociatedObjectKey_mediaViewer"
    }

    fileprivate typealias Action = (() -> Void)?

    // Set our computed property type to a closure
    fileprivate var tapGestureRecognizerAction: Action? {
        set {
            if let newValue = newValue {
                // Computed properties get stored as associated objects
                objc_setAssociatedObject(self, &AssociatedObjectKeys.tapGestureRecognizer, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            }
        }
        get {
            let tapGestureRecognizerActionInstance = objc_getAssociatedObject(self, &AssociatedObjectKeys.tapGestureRecognizer) as? Action
            return tapGestureRecognizerActionInstance
        }
    }

    // This is the meat of the sauce, here we create the tap gesture recognizer and
    // store the closure the user passed to us in the associated object we declared above
    public func addTapGestureRecognizer(action: (() -> Void)?) {
        self.isUserInteractionEnabled = true
        self.tapGestureRecognizerAction = action
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        self.addGestureRecognizer(tapGestureRecognizer)
    }

    // Every time the user taps on the UIImageView, this function gets called,
    // which triggers the closure we stored
    @objc fileprivate func handleTapGesture(sender: UITapGestureRecognizer) {
        if let action = self.tapGestureRecognizerAction {
            action?()
        } else {
            print("no action")
        }
    }

}

class DragSelectionGestureRecognizer: UIPanGestureRecognizer {
    static var kSTDragSelectionGestureRecognizerAutoPanningIncrement: CGFloat = 12

    enum DragSelectionMode {
        case none
        case select
        case deselect
    }

    enum AutoPanningDirection {
        case none
        case up
        case down
    }

    var beginIndexPath: IndexPath?
    var ignoredIndexPaths: [IndexPath]? {
        didSet {
            ignoredIndexPathInfo = [:]
            ignoredIndexPaths?.forEach { ignoredIndexPathInfo?[$0] = true }
            
            ignoredIndexPathSet = NSMutableOrderedSet(array: ignoredIndexPaths ?? [])
        }
    }
    private(set) var ignoredIndexPathInfo: [IndexPath: Bool]?
    private(set) var ignoredIndexPathSet: NSMutableOrderedSet?
    var beginLocation: CGPoint?
    var selectionMode = DragSelectionGestureRecognizer.DragSelectionMode.none
    var autoPanningTimer: CADisplayLink?

    override func reset() {
        super.reset()
        
        beginIndexPath = nil
        beginLocation = nil
        ignoredIndexPaths = nil
        ignoredIndexPathInfo = nil
        ignoredIndexPathSet = nil
        selectionMode = .none
        stopAutoPanning()
    }

    private var panHandler: (() -> Void)?
    func panAutomatically(_ panBlock: (() -> Void)?) {
        if autoPanningTimer == nil {
            autoPanningTimer = CADisplayLink(target: self, selector: #selector(self.autoPanningTimerDidChange))
            autoPanningTimer?.add(to: .main, forMode: RunLoop.Mode.common)
        }
        panHandler = panBlock
    }

    func stopAutoPanning() {
        autoPanningTimer?.remove(from: .main, forMode: RunLoop.Mode.common)
        autoPanningTimer = nil
        panHandler = nil
    }

    @objc func autoPanningTimerDidChange(sender: CADisplayLink) {
        self.panHandler?()
    }
}
