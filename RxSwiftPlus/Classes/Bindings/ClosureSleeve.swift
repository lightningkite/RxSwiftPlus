//
//  ClosureSleeve.swift
//
//  Created by Joseph Ivie on 1/2/19.
//

import Foundation
import UIKit
import RxSwift

class ClosureSleeve {
    let closure: () -> ()

    init(closure: @escaping () -> ()) {
        self.closure = closure
    }
    @objc public func invoke() {
        closure()
    }
}

public extension UIControl {
    func addAction(for controlEvents: UIControl.Event = .primaryActionTriggered, action: @escaping () -> ()) -> Disposable {
        let sleeve = ClosureSleeve(closure: action)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
        return DisposableLambda { [sleeve] in
            // Retain the sleeve until disposed
            let _ = sleeve
        }
    }
    func addOnStateChange(action: @escaping (UIControl.State)->Void) -> Disposable {
        let toRetain = [
            observe(\.isHighlighted, options: [.old, .new]) { (provider, changes) in
                action(provider.state)
            },
            observe(\.isSelected, options: [.old, .new]) { (provider, changes) in
                action(provider.state)
            },
            observe(\.isEnabled, options: [.old, .new]) { (provider, changes) in
                action(provider.state)
            }
        ]
        return DisposableLambda { [toRetain] in
            // Retain the sleeve until disposed
            let _ = toRetain
        }
    }
}

public extension UIGestureRecognizer {
    func addAction(action: @escaping () -> ()) -> Disposable {
        let sleeve = ClosureSleeve(closure: action)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke))
        return DisposableLambda { [sleeve] in
            // Retain the sleeve until disposed
            let _ = sleeve
        }
    }
}

public extension UIBarButtonItem {
    convenience init(title: String?, style: UIBarButtonItem.Style, until: DisposeCondition, action: @escaping () -> ()) {
        let sleeve = ClosureSleeve(closure: action)
        self.init(title: title, style: style, target: sleeve, action: #selector(ClosureSleeve.invoke))
        DisposableLambda { [sleeve] in
            // Retain the sleeve until disposed
            let _ = sleeve
        }.until(until)
    }
}

public extension NSObject {
    private static var anything = ExtensionProperty<NSObject, Dictionary<String, Any?>>()
    private var extensions: Dictionary<String, Any?>? {
        get {
            return NSObject.anything.get(self)
        }
    }

    func retain<T>(item: T, as string: String = "[\(arc4random())]") -> DisposableLambda {
        NSObject.anything.modify(self, defaultValue: [:]) { box in
            box[string] = item
        }
        return DisposableLambda {
            NSObject.anything.modify(self, defaultValue: [:]) { box in
                box[string] = nil
            }
        }
    }
}
