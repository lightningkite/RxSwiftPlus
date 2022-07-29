//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import UIKit
import RxSwift
import RxCocoa


//--- UIView.bindVisible(Property<Boolean>)
public extension UIView {
    var visible: Bool {
        get {
            return self.alpha != 0
        }
        set(value) {
            self.alpha = value ? 1 : 0
        }
    }
    var exists: Bool{
        get {
            return !self.isHidden
        }
        set(value) {
            self.isHidden = !value
        }
    }
    
    @discardableResult fileprivate func createSpinner(_ color: UIColor? = nil) -> UIActivityIndicatorView {
        if let x = self.subviews.lazy.compactMap({ $0 as? UIActivityIndicatorView }).first {
            return x
        } else {
            let spinner = UIActivityIndicatorView(frame: .zero)
            spinner.translatesAutoresizingMaskIntoConstraints = false
            if let color = color {
                spinner.color = color
            }
            addSubview(spinner)
            spinner.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            spinner.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            return spinner
        }
    }
    fileprivate var mySpinner: UIActivityIndicatorView { return createSpinner() }
    
    fileprivate func setSpinnerVisible(){
        let spinner = mySpinner
        UIView.animate(withDuration: 0.25, animations: {
            spinner.startAnimating()
            self.subviews.forEach({subView in subView.alpha = 0})
            spinner.alpha = 1
        })
    }
    
    fileprivate func setSpinnerInVisible(){
        let spinner = mySpinner
        UIView.animate(withDuration: 0.25, animations: {
            spinner.stopAnimating()
            self.subviews.forEach({subView in subView.alpha = 1})
            spinner.alpha = 0
        })
    }
}


public extension ObservableConvertibleType {
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW, Element) -> Void)-> Self{
        asObservable().subscribe(
            onNext: { value in setter(view, value) }
        ).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element) -> Void)-> Self{
        asObservable().subscribe(
            onNext: { value in setter(view)(value) }
        ).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element, UIControl.State) -> Void)-> Self{
        asObservable().subscribe(
            onNext: { value in setter(view)(value, .normal) }
        ).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element?) -> Void)-> Self{
        asObservable().subscribe(
            onNext: { value in setter(view)(value) }
        ).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element?, UIControl.State) -> Void)-> Self{
        asObservable().subscribe(
            onNext: { value in setter(view)(value, .normal) }
        ).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: ReferenceWritableKeyPath<VIEW, Element>)-> Self{
        asObservable().subscribe(
            onNext: { value in view[keyPath: setter] = value }
        ).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: ReferenceWritableKeyPath<VIEW, Element?>)-> Self{
        asObservable().subscribe(
            onNext: { value in view[keyPath: setter] = value }
        ).disposed(by: view.removed)
        return self
    }
    
//    @discardableResult
//    func into<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW, Element) -> Void)-> Self{
//        return subscribeAutoDispose(view, setter)
//    }
//    @discardableResult
//    func into<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element) -> Void)-> Self{
//        return subscribeAutoDispose(view, setter)
//    }
//    @discardableResult
//    func into<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element, UIControl.State) -> Void)-> Self{
//        return subscribeAutoDispose(view, setter)
//    }
//    @discardableResult
//    func into<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element?) -> Void)-> Self{
//        return subscribeAutoDispose(view, setter)
//    }
//    @discardableResult
//    func into<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element?, UIControl.State) -> Void)-> Self{
//        return subscribeAutoDispose(view, setter)
//    }
//    @discardableResult
//    func into<VIEW: UIView>(_ view: VIEW, _ setter: ReferenceWritableKeyPath<VIEW, Element>)-> Self{
//        return subscribeAutoDispose(view, setter)
//    }
//    @discardableResult
//    func into<VIEW: UIView>(_ view: VIEW, _ setter: ReferenceWritableKeyPath<VIEW, Element?>)-> Self{
//        return subscribeAutoDispose(view, setter)
//    }
}

public extension ObservableConvertibleType where Element: OptionalType {
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element.Wrapped) -> Void)-> Self{
        asObservable().subscribe(
            onNext: { value in
                if let value = value.asOptional() {
                    setter(view)(value)
                }
            }
        ).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element.Wrapped, UIControl.State) -> Void)-> Self{
        asObservable().subscribe(
            onNext: { value in
                if let value = value.asOptional() {
                    setter(view)(value, .normal)
                }
            }
        ).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: ReferenceWritableKeyPath<VIEW, Element.Wrapped>)-> Self{
        asObservable().subscribe(
            onNext: { value in
                if let value = value.asOptional() {
                    view[keyPath: setter] = value
                }
            }
        ).disposed(by: view.removed)
        return self
    }
    
//    @discardableResult
//    func into<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element.Wrapped) -> Void)-> Self{
//        return subscribeAutoDispose(view, setter)
//    }
//    @discardableResult
//    func into<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element.Wrapped, UIControl.State) -> Void)-> Self{
//        return subscribeAutoDispose(view, setter)
//    }
//    @discardableResult
//    func into<VIEW: UIView>(_ view: VIEW, _ setter: ReferenceWritableKeyPath<VIEW, Element.Wrapped>)-> Self{
//        return subscribeAutoDispose(view, setter)
//    }

}


public extension ObservableType where Element == Bool {
    func showLoading(_ view: UIView, color: UIColor? = nil) -> Void {
        view.createSpinner(color)
        subscribe(
            onNext: { value in
                if (value) {
                    view.setSpinnerVisible()
                } else {
                    view.setSpinnerInVisible()
                }
            }
        ).disposed(by: view.removed)
    }
}


public extension PrimitiveSequence where Trait == SingleTrait {
    
//    @discardableResult
//    func into<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW, Element) -> Void)-> Self{
//        return subscribeAutoDispose(view, setter)
//    }
    
    @discardableResult
    func showLoading(_ view: UIView, color: UIColor? = nil) -> Self {
        
//        view.createSpinner(color)
//
//        return self.do(
//            onSubscribe: { view.setSpinnerVisible() },
//            onDispose: { view.setSpinnerInVisible() }
//        )
        return self
    }
}

public extension PrimitiveSequence where Trait == MaybeTrait {
    
//    @discardableResult
//    func into<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW, Element) -> Void)-> Self{
//        return subscribeAutoDispose(view, setter)
//    }
    
    @discardableResult
    func showLoading(_ view: UIView, color: UIColor? = nil) -> Self {
        
//        view.createSpinner(color)
//
//        return self.do(
//            onSubscribe: { view.setSpinnerVisible() },
//            onDispose: { view.setSpinnerInVisible() }
//        )
        return self
    }
}

public extension UIView {
    var showLoading: Bool {
        get {
            return mySpinner.alpha > 0.5
        }
        set(value) {
            if (value) {
                self.setSpinnerVisible()
            } else {
                self.setSpinnerInVisible()
            }
        }
    }
}
