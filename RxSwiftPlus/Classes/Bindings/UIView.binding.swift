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
    
    fileprivate static var loadCountExtension: ExtensionProperty<UIView, Int> = ExtensionProperty()
    fileprivate var loadCount: Int {
        get {
            return UIView.loadCountExtension.getOrPut(self){ 0 }
        }
        set(value) {
            UIView.loadCountExtension.set(self, value)
            if(value > 0){
                self.setSpinnerVisible()
            }else{
                self.setSpinnerInVisible()
            }
        }
    }
    
    fileprivate static var spinnerExtension: ExtensionProperty<UIView, UIActivityIndicatorView> = ExtensionProperty()
    
    fileprivate func createSpinner(_ color:UIColor?){
        let spinner = UIActivityIndicatorView(frame: .zero)
        if let color = color {
            spinner.color = color
        }
        UIView.spinnerExtension.set(self, spinner)
    }
    
    fileprivate func setSpinnerVisible(){
        let spinner = UIView.spinnerExtension.getOrPut(self) {UIActivityIndicatorView(frame: .zero)}
        spinner.startAnimating()
        self.addSubview(spinner)
        self.subviews.forEach({subView in subView.alpha = 0})
    }
    
    fileprivate func setSpinnerInVisible(){
        let spinner = UIView.spinnerExtension.getOrPut(self) {UIActivityIndicatorView(frame: .zero)}
        spinner.stopAnimating()
        spinner.removeFromSuperview()
        self.subviews.forEach({subView in subView.alpha = 1})
    }
}


public extension ObservableType {
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW, Element) -> Void)-> Self{
        subscribe(
            onNext: { value in setter(view, value) }
        ).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element) -> Void)-> Self{
        subscribe(
            onNext: { value in setter(view)(value) }
        ).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element, UIControl.State) -> Void)-> Self{
        subscribe(
            onNext: { value in setter(view)(value, .normal) }
        ).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element?) -> Void)-> Self{
        subscribe(
            onNext: { value in setter(view)(value) }
        ).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW) -> (Element?, UIControl.State) -> Void)-> Self{
        subscribe(
            onNext: { value in setter(view)(value, .normal) }
        ).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: ReferenceWritableKeyPath<VIEW, Element>)-> Self{
        subscribe(
            onNext: { value in view[keyPath: setter] = value }
        ).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: ReferenceWritableKeyPath<VIEW, Element?>)-> Self{
        subscribe(
            onNext: { value in view[keyPath: setter] = value }
        ).disposed(by: view.removed)
        return self
    }
}

private func test(view: UILabel) {
    Observable.just("asdf").subscribeAutoDispose(view, \.text)
}


public extension ObservableType where Element == Bool {
    func showLoading(_ view: UIView, _ color: UIColor? = nil) -> Void {
        
        view.createSpinner(color)
        
        subscribe(
            onNext: { value in
                if(value){
                    view.setSpinnerVisible()
                }else{
                    view.setSpinnerInVisible()
                }
            }
        ).disposed(by: view.removed)
    }
}


public extension PrimitiveSequence where Trait == SingleTrait {
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW, Element) -> Void)-> Self{
        subscribe(
            onSuccess: { value in setter(view, value) }
        ).disposed(by: view.removed)
        return self
    }
    
    
    @discardableResult
    func showLoading(_ view: UIView, _ color: UIColor? = nil) -> Self {
        
        view.createSpinner(color)
        
        return self.do(
            onSubscribe: { view.loadCount += 1 },
            onDispose: { view.loadCount -= 1 }
        )
    }
}

public extension PrimitiveSequence where Trait == MaybeTrait {
    @discardableResult
    func subscribeAutoDispose<VIEW: UIView>(_ view: VIEW, _ setter: @escaping (VIEW, Element) -> Void)-> Self{
        subscribe(
            onSuccess: { value in setter(view, value) }
        ).disposed(by: view.removed)
        return self
    }
    
    
    @discardableResult
    func showLoading(_ view: UIView, _ color: UIColor? = nil) -> Self {
        
        view.createSpinner(color)
        
        return self.do(
            onSubscribe: { view.loadCount += 1 },
            onDispose: { view.loadCount -= 1 }
        )
    }
}

