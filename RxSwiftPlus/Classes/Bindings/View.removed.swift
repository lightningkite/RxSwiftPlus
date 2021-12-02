import RxSwift
import UIKit
import LifecycleHooks
import RxCocoa

public extension UIView {
//    static private let bag = DisposeBag()
//    var removed: DisposeBag { UIView.bag }
    private var detectorView: RemovedDetectorView  {
        if let observer = (subviews.lazy.compactMap { $0 as? RemovedDetectorView }.first) {
            return observer
        }
        let observer = RemovedDetectorView()
        addSubview(observer)
        return observer
    }

    var removed: DisposeBag {
        get {
            assert(Thread.isMainThread)
            return detectorView.disposeBag!
        }
        set(value) {
            detectorView.disposeBagOverridden = true
            detectorView.disposeBag = value
        }
    }
    
}

private class RemovedDetectorView: UIView {

    var disposeBag: DisposeBag? = DisposeBag()
    var disposeBagOverridden = false
    var hasBeenActive = false
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        isHidden = true
    }
    
    override func didMoveToWindow() {
        guard !disposeBagOverridden else { return }
        if window != nil {
            hasBeenActive = true
        } else if hasBeenActive {
            hasBeenActive = false
            disposeBag = nil
        }
    }

    override var isHidden: Bool {
        get {
            return super.isHidden
        }
        set {
            precondition(newValue == true)
            super.isHidden = newValue
        }
    }

    override var isUserInteractionEnabled: Bool {
        get {
            return super.isHidden
        }
        set {
            precondition(newValue == false)
            super.isHidden = newValue
        }
    }

    func hide() {
        isHidden = true
        isUserInteractionEnabled = false
    }
    
    override var debugDescription: String {
        return "\(super.debugDescription) (hidden? \(isHidden))"
    }
}
