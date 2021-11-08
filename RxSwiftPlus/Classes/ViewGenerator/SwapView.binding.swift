//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import RxSwift

//--- SwapView.bindStack(ViewControllerAccess, StackProperty<ViewGenerator>)
public extension ObservableType where Element : Collection, Element.Element: ViewGenerator {
    @discardableResult
    func showIn(_ view: SwapView, dependency: ViewControllerAccess) -> Self {
        var lastCount = 0
        subscribe(onNext: { value in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
                var animation = SwapView.Animation.fade
                if lastCount == 0 {
                    animation = .fade
                } else if value.count > lastCount {
                    animation = .push
                } else if value.count < lastCount {
                    animation = .pop
                }
                lastCount = value.count
                if let newView = Array(value).last?.generate(dependency: dependency) {
                    view.swap(dependency: dependency, to: newView, animation: animation)
                } else {
                    view.swap(dependency: dependency, to: nil, animation: animation)
                }
            })
        }).disposed(by: view.removed)
        return self
    }
}

public extension ObservableType where Element : Collection, Element.Element == ViewGenerator {
    @discardableResult
    func showIn(_ view: SwapView, dependency: ViewControllerAccess) -> Self {
        var lastCount = 0
        subscribe(onNext: { value in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
                var animation = SwapView.Animation.fade
                if lastCount == 0 {
                    animation = .fade
                } else if value.count > lastCount {
                    animation = .push
                } else if value.count < lastCount {
                    animation = .pop
                }
                lastCount = value.count
                if let newView = Array(value).last?.generate(dependency: dependency) {
                    view.swap(dependency: dependency, to: newView, animation: animation)
                } else {
                    view.swap(dependency: dependency, to: nil, animation: animation)
                }
            })
        }).disposed(by: view.removed)
        return self
    }
}
