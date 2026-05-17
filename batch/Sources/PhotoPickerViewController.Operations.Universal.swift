import Foundation
import UIKit
import Photos

extension PhotoPickerViewController: PhotoPickerViewControllerUniversalOperations {
    func performInSelectionContext() {
        
    }
    
    func performInNonSelectionContext(performWhenAllowed: (() -> ())?) {
        performWhenAllowed?()
    }
    
    @discardableResult
    func selectInCurrentContext(with asset: PHAsset, animated: Bool) -> Bool {
        return false
    }
    
    @discardableResult
    func selectInCurrentContext(at indexPath: IndexPath, animated: Bool) -> Bool {
        return false
    }
}
