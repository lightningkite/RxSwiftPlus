//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import Cosmos
import RxSwift
import RxCocoa


public typealias UIRatingBar = CosmosView


public extension SubjectType where Element == Float, Observer.Element == Float {
    
    @discardableResult
    func bind(_ view: UIRatingBar) -> Self {
        
        var suppress = false
        subscribe(onNext:  { (value) in
            guard !suppress else { return }
            suppress = true
            view.rating = Double(value)
            suppress = false
        }).disposed(by: view.removed)
        let observer = self.asObserver()
        view.didTouchCosmos = { rating in
            guard !suppress else { return }
            suppress = true
            observer.onNext(Float(rating))
            suppress = false
        }
        
        return self
    }
    
}

