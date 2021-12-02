//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import Cosmos
import RxSwift
import RxCocoa

public extension CosmosView {
    var ratingFloat: Float { get { return Float(rating) } set(value) { self.rating = Double(value) }}
}

public extension SubjectType where Element == Float, Observer.Element == Float {
    
    @discardableResult
    func bind(_ view: CosmosView) -> Self {
        self.toSubjectDouble().bind(view)
        return self
    }
}


public extension SubjectType where Element == Double, Observer.Element == Double {
    
    @discardableResult
    func bind(_ view: CosmosView) -> Self {
        
        var suppress = false
        subscribe(onNext:  { (value) in
            guard !suppress else { return }
            suppress = true
            view.rating = value
            suppress = false
        }).disposed(by: view.removed)
        let observer = self.asObserver()
        view.didTouchCosmos = { rating in
            guard !suppress else { return }
            suppress = true
            observer.onNext(rating)
            suppress = false
        }
        
        return self
    }
    
}

