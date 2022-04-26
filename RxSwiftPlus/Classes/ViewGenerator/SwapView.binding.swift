//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import RxSwift


public extension ObservableType{
    @discardableResult
    func showIn(_ view: SwapView, transition: TransitionTriple = TransitionTriple.Companion.INSTANCE.FADE, makeView: @escaping (Element) -> UIView) -> Self {
        var currentValue: Element? = nil
        subscribe(onNext: { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
                currentValue = newValue
                view.swap(dependency: nil, to: makeView(newValue), transition: transition)
            })
        }).disposed(by: view.removed)
        return self
    }
}

public extension ObservableType where Element: ViewGenerator{
    
    @discardableResult
    func showIn(_ view: SwapView, dependency: ViewControllerAccess, transition: TransitionTriple = TransitionTriple.Companion.INSTANCE.FADE) -> Self {
        subscribe(onNext: { value in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
                view.swap(dependency: dependency, to: value.generate(dependency: dependency), transition: transition)
            })
        }).disposed(by: view.removed)
        return self
    }
    
}

//--- SwapView.bindStack(ViewControllerAccess, StackProperty<ViewGenerator>)
public extension ObservableType where Element : Collection, Element.Element: ViewGenerator {
    @discardableResult
    func showIn(_ view: SwapView, dependency: ViewControllerAccess, stackTransition: StackTransition = StackTransition.Companion.INSTANCE.PUSH_POP) -> Self {
        var lastCount = 0
        subscribeAutoDispose(view){ view, value in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
                let newCount = value.count
                var transition:TransitionTriple
                let newGenerator = value.lastOrNull()
                
                if(lastCount == 0){
                    transition = (newGenerator as? UsesCustomTransition)?.transition.neutral ?? stackTransition.neutral
                } else if (newCount == 0) {
                    transition = (newGenerator as? UsesCustomTransition)?.transition.neutral ?? stackTransition.neutral
                } else if (newCount > lastCount) {
                    transition = (newGenerator as? UsesCustomTransition)?.transition.neutral ?? stackTransition.neutral
                } else if (newCount < lastCount) {
                    transition = (newGenerator as? UsesCustomTransition)?.transition.neutral ?? stackTransition.neutral
                } else {
                    transition = (newGenerator as? UsesCustomTransition)?.transition.neutral ?? stackTransition.neutral
                }
                
                lastCount = newCount
                view.swap(dependency: dependency, to: newGenerator?.generate(dependency: dependency), transition: transition)
            })
        }
        return self
    }
}

public extension ObservableType where Element : Collection, Element.Element == ViewGenerator {
    @discardableResult
    func showIn(_ view: SwapView, dependency: ViewControllerAccess, stackTransition: StackTransition = StackTransition.Companion.INSTANCE.PUSH_POP) -> Self {
        var lastCount = 0
        var currentGenerator: ViewGenerator? = nil
        self
            .debounce(RxTimeInterval.milliseconds(50), scheduler: MainScheduler.instance)
            .subscribeAutoDispose(view){ view, value in
                let newCount = value.count
                var transition:TransitionTriple
                let newGenerator = value.lastOrNull()
                
                if(lastCount == 0){
                    transition = (newGenerator as? UsesCustomTransition)?.transition.neutral ?? stackTransition.neutral
                } else if (newCount == 0) {
                    transition = (currentGenerator as? UsesCustomTransition)?.transition.pop ?? stackTransition.pop
                } else if (newCount > lastCount) {
                    transition = (newGenerator as? UsesCustomTransition)?.transition.push ?? stackTransition.push
                } else if (newCount < lastCount) {
                    transition = (currentGenerator as? UsesCustomTransition)?.transition.pop ?? stackTransition.pop
                } else {
                    transition = (newGenerator as? UsesCustomTransition)?.transition.neutral ?? stackTransition.neutral
                }
                currentGenerator = newGenerator
                lastCount = newCount
                view.swap(dependency: dependency, to: newGenerator?.generate(dependency: dependency), transition: transition)
            }
        return self
    }
}
