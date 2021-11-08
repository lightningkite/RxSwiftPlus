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
    func showIn(_ view: UIStackView, _ makeView: @escaping (Observable<Element.Element>) -> UIView) -> Self{
        var existingViews: Array<(UIView,BehaviorSubject<Element.Element>)> = []
        subscribe(
            onNext: {items in
                let countDiff = existingViews.count - items.count
                if(countDiff > 0) {
                    for _ in 1...countDiff{
                        existingViews.remove(at: existingViews.count - 1)
                    }
                } else if countDiff < 0 {
                    let itemsArray: Array<Element.Element> = Array(items)
                    for index in existingViews.count...items.count {
                        let prop = BehaviorSubject<Element.Element>(value: itemsArray[index - 1])
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
