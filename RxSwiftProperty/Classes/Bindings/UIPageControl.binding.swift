//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import UIKit
import RxSwift
import RxCocoa

public extension SubjectType where Element == Int, Observer.Element == Int {
    
    @discardableResult
    func bind(_ view: UIPageControl) -> Self {
        var suppress = false
        subscribe(
            onNext: {value in
                guard !suppress else { return }
                suppress = true
                view.currentPage = value
                suppress = false
            }
        ).disposed(by: view.removed)
        let observer = self.asObserver()
        view.addAction(for: .valueChanged, action: {
            guard !suppress else { return }
            suppress = true
            observer.onNext(view.currentPage)
            suppress = false
        }).disposed(by: view.removed)
        return self
    }
    
    @discardableResult
    func bind(_ view: UIPageControl, _ count: Int) -> Self {
        var suppress = false
        view.numberOfPages = count
        subscribe(
            onNext: {value in
                guard !suppress else { return }
                suppress = true
                view.currentPage = value
                suppress = false
            }
        ).disposed(by: view.removed)
        let observer = self.asObserver()
        view.addAction(for: .valueChanged, action: {
            guard !suppress else { return }
            suppress = true
            observer.onNext(view.currentPage)
            suppress = false
        }).disposed(by: view.removed)
        return self
    }
    
    @discardableResult
    func bind<Observable:ObservableType>(_ view: UIPageControl, _ count: Observable) -> Self where Observable.Element == Int{
        var suppress = false
        count.subscribe(onNext: { count in
            view.numberOfPages = count
        }).disposed(by: view.removed)
        subscribe(
            onNext: {value in
                guard !suppress else { return }
                suppress = true
                view.currentPage = value
                suppress = false
            }
        ).disposed(by: view.removed)
        let observer = self.asObserver()
        view.addAction(for: .valueChanged, action: {
            guard !suppress else { return }
            suppress = true
            observer.onNext(view.currentPage)
            suppress = false
        }).disposed(by: view.removed)
        return self
    }
}

