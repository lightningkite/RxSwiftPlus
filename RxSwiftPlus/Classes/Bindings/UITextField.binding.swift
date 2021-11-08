//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import UIKit
import RxSwift
import RxCocoa



public extension SubjectType where Element == Optional<String>, Observer.Element == Element {
    @discardableResult
    func bind(_ view: UITextField) -> Self{
        (view.rx.text <-> self).disposed(by: view.removed)
        return self
    }
    
    @discardableResult
    func bind(_ view: UITextView) -> Self {
        (view.rx.text <-> self).disposed(by: view.removed)
        return self
    }
}
