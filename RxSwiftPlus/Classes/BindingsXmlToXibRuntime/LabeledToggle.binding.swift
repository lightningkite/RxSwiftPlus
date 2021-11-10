//Stub file made with Butterfly 2 (by Lightning Kite)
import XmlToXibRuntime
import RxSwift
import RxCocoa


public extension SubjectType where Element == Bool, Observer.Element == Element {
    @discardableResult
    func bind(_ view: ToggleView) -> Self{
        subscribe(
            onNext: { value in if(value != view.isOn) { view.setOn(value, animated: true) } },
            onError: nil,
            onCompleted: nil,
            onDisposed: nil
        ).disposed(by: view.removed)
        let observer = self.asObserver()
        view.addAction(for: .valueChanged, action: { [weak view] in
            guard let view = view else { return }
            observer.onNext(view.isOn)
        }).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func bindNoUncheck(_ view: ToggleView) -> Self{
        subscribe(
            onNext: { value in if(value != view.isOn) { view.setOn(value, animated: true) } },
            onError: nil,
            onCompleted: nil,
            onDisposed: nil
        ).disposed(by: view.removed)
        let observer = self.asObserver()
        view.addAction(for: .valueChanged, action: { [weak view] in
            guard let view = view else { return }
            if view.isOn {
                observer.onNext(true)
            } else {
                view.isOn = true
            }
        }).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func bind(_ view: LabeledToggle) -> Self{
        return bind(view.toggle)
    }
    @discardableResult
    func bindNoUncheck(_ view: LabeledToggle) -> Self{
        return bindNoUncheck(view.toggle)
    }
}
