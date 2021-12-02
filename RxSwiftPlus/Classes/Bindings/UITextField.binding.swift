//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import UIKit
import RxSwift
import RxCocoa



public extension SubjectType where Element == Optional<String>, Observer.Element == Element {
    @discardableResult
    func bind(_ view: UITextField) -> Self{
        self.bind(view.rx.text).disposed(by: view.removed)
        return self
    }
    
    @discardableResult
    func bind(_ view: UITextView) -> Self {
        self.bind(view.rx.text).disposed(by: view.removed)
        return self
    }
}
public extension SubjectType where Element == String, Observer.Element == Element {
    @discardableResult
    func bind(_ view: UITextField) -> Self {
        self.map(read: {$0 as String?}, write: {$0 ?? ""}).bind(view)
        return self
    }
    
    @discardableResult
    func bind(_ view: UITextView) -> Self {
        self.map(read: {$0 as String?}, write: {$0 ?? ""}).bind(view)
        return self
    }
}
