//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import MapKit


//--- ViewControllerAccess
@objc public class ViewControllerAccess: NSObject {
    public unowned let parentViewController: UIViewController
    public init(_ parentViewController: UIViewController){
        self.parentViewController = parentViewController
    }
}

// MARK: - Extensions to make view controller keyboard-aware.
// Move these to a separate file if you want

public extension ViewControllerAccess {
    func runKeyboardUpdate(root: UIView? = nil, discardingRoot: UIView? = nil) {
        let currentFocus = UIResponder.current as? UIView
        var dismissOld = false
        if let currentFocus = currentFocus {
            if let discardingRoot = discardingRoot, discardingRoot.containsSub(other: currentFocus) {
                //We're discarding the focus
                dismissOld = true
            }
        }
        if let root = root, let keyboardView = root.findFirstFocus(startup: true) {
            post {
                if keyboardView.window != nil {
                    keyboardView.becomeFirstResponder()
                }
            }
            dismissOld = false
        }
        if dismissOld {
            self.parentViewController.view.endEditing(true)
        }
    }
}

private extension UIView {
    func containsSub(other: UIView?) -> Bool {
        if self === other { return true }
        guard let other = other else { return false }
        return self.containsSub(other: other.superview)
    }
}
