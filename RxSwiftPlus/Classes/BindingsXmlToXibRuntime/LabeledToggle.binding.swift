//Stub file made with Butterfly 2 (by Lightning Kite)
import XmlToXibRuntime
import RxSwift
import RxCocoa


public extension SubjectType where Element == Bool, Observer.Element == Element {
    @discardableResult
    func bind(_ view: ToggleView) -> Self{
        var suppress = false
        subscribe(
            onNext: { value in
                guard !suppress else { return }
                if value != view.isOn {
                    suppress = true
                    view.setOn(value, animated: true)
                    suppress = false
                }
            },
            onError: nil,
            onCompleted: nil,
            onDisposed: nil
        ).disposed(by: view.removed)
        let observer = self.asObserver()
        view.addAction(for: .valueChanged, action: { [weak view] in
            guard let view = view else { return }
            guard !suppress else { return }
            suppress = true
            observer.onNext(view.isOn)
            suppress = false
        }).disposed(by: view.removed)
        return self
    }
    @discardableResult
    func bindNoUncheck(_ view: ToggleView) -> Self{
        var suppress = false
        subscribe(
            onNext: { value in
                guard !suppress else { return }
                if value != view.isOn {
                    suppress = true
                    view.setOn(value, animated: true)
                    suppress = false
                }
            },
            onError: nil,
            onCompleted: nil,
            onDisposed: nil
        ).disposed(by: view.removed)
        let observer = self.asObserver()
        view.addAction(for: .valueChanged, action: { [weak view] in
            guard let view = view else { return }
            guard !suppress else { return }
            suppress = true
            if view.isOn {
                observer.onNext(true)
            } else {
                view.isOn = true
            }
            suppress = false
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
