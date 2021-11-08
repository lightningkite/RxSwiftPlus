import RxSwift
import UIKit
import RxCocoa

public extension UIView {
    private static var disposablesAssociationKey: UInt8 = 0
    private static var disposablesExtension: ExtensionProperty<UIView, DisposeBag> = ExtensionProperty()
    private static var beenActiveExtension: ExtensionProperty<UIView, Bool> = ExtensionProperty()
    var removed: DisposeBag {
        get {
            return UIView.disposablesExtension.getOrPut(self) {DisposeBag() }
        }
        set(value) {
            UIView.disposablesExtension.set(self, value)
        }
    }

    func refreshLifecycle() {

        let previouslyActive = UIView.beenActiveExtension.get(self) == true
        if !previouslyActive && window != nil {
            UIView.beenActiveExtension.set(self, true)
        }
        if previouslyActive && window == nil {
            removed = DisposeBag()
        }

        for view in self.subviews {
            view.refreshLifecycle()
        }
    }
    
    func removedDeinitHandler() {
        removed = DisposeBag()
        for view in self.subviews {
            view.removedDeinitHandler()
        }
    }

    private func connected() -> Bool {
        return self.window != nil || self.superview?.connected() ?? false
    }
}
