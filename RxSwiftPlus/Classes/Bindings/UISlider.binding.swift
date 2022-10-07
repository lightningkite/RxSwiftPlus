//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import UIKit
import RxCocoa
import RxSwift



public extension SubjectType where Element == Int, Observer.Element == Element {
    @discardableResult
    func bind(_ view: UISlider, range: ClosedRange<Int>? = nil) -> Self {
        if let range = range {
            view.minimumValue = Float(range.lowerBound)
            view.maximumValue = Float(range.upperBound)
        }
        var suppress = false
        let observer = self.asObserver()
        view.addAction(for: .valueChanged, action: { [weak view] in
            guard let view = view, !suppress else { return }
            suppress = true
            let v = view.value.rounded()
            observer.onNext(Int(v))
            view.value = v
            suppress = false
        }).disposed(by: view.removed)
        subscribe(
            onNext: { (value) in
                guard !suppress else { return }
                suppress = true
                view.setValue(Float(value), animated: false)
                suppress = false
            },
            onError: nil,
            onCompleted: nil,
            onDisposed: nil
        ).disposed(by: view.removed)
        return self
    }
}
