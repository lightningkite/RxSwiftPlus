//
//  RootVG.swift
//  RxSwiftProperty_Example
//
//  Created by Joseph Ivie on 8/30/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import RxSwiftProperty
import RxSwift

//extension UILabel {
//    func setLabel(value:String){
//        self.text = value
//    }
//}

class RootVG: ViewGenerator {
    
    let stack = ValueSubject<Array<ViewGenerator>>([])
    
    let item = ValueSubject("Hello World")
    
    init() {
//        stack.reset(t: SelectorVG(stack: stack))
        stack.value = [SelectorVG(stack: stack)]
    }
    
    func generate(dependency: ViewControllerAccess) -> UIView {
        let view = RootLayout.make()
        stack
            .showIn(view.swapView, dependency: dependency)
            .map { $0.count <= 1 }
            .subscribeAutoDispose(view.backButton, \UIButton.isHidden)
        view.backButton.rx.controlEvent(.touchUpInside)
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: {
                self.stack.value = self.stack.value.dropLast()
            })
            .disposed(by: view.backButton.removed)
        return view
    }
}

class SelectorVG: ViewGenerator {
    init(stack: ValueSubject<Array<ViewGenerator>>) {
    }
    
    let data: Array<String> = Array(1...100).map {
        let charCount = Int.random(in: 1...40)
        var out = "Entry \($0) - "
        for i in 1...charCount {
            out += "xX"
        }
        return out
    }
    
    func generate(dependency: ViewControllerAccess) -> UIView {
        let view = SelectorLayout.make()
        Observable.just(data).showIn(view.collectionView) { obs in
            let btn = UILabel(frame: .zero)
            btn.numberOfLines = 0
            obs.subscribeAutoDispose(btn, \UILabel.text)
            btn.textColor = .black
            return btn
        }
        return view
    }
}
