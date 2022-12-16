//
//  UIStackView.binding.swift
//  RxSwiftPlus
//
//  Created by Joseph Ivie on 10/14/21.
//

import Foundation
import UIKit
import RxSwift


public extension ObservableType where Element: Collection {
    @discardableResult
    func showIn(_ view: UIStackView, makeView: @escaping (Observable<Element.Element>) -> UIView) -> Self {
        view.alignment = .fill
        var existingViews: Array<(UIView,BehaviorSubject<Element.Element>)> = []
        subscribe(
            onNext: {items in
                let countDiff = existingViews.count - items.count
                if(countDiff > 0) {
                    for _ in 1...countDiff{
                        let removedView = existingViews.remove(at: existingViews.count - 1)
                        view.removeArrangedSubview(removedView.0)
                        removedView.0.removeFromSuperview()
                    }	
                } else if countDiff < 0 {
                    let itemsArray: Array<Element.Element> = Array(items)
                    for index in existingViews.count...itemsArray.count - 1 {
                        let prop = BehaviorSubject<Element.Element>(value: itemsArray[index])
                        let cellView = makeView(prop)
                        view.addArrangedSubview(cellView)
                        existingViews.append((cellView, prop))
                    }
                }
                
                for (index, item) in items.enumerated(){
                    existingViews[index].1.onNext(item)
                }
            },
            onError: nil,
            onCompleted: nil,
            onDisposed: nil
        ).disposed(by: view.removed)
        return self
    }
}
