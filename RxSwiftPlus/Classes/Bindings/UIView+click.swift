//
//  UIView+click.swift
//  RxSwiftPlus
//
//  Created by Joseph Ivie on 11/8/21.
//

import UIKit
import RxCocoa
import RxSwift

public extension Reactive where Base: UIView {
    var click: Observable<Void> {
        if let btn = self.base as? UIButton {
            return btn.rx.tap.asObservable()
        } else {
            base.isUserInteractionEnabled = true
            let recognizer = UITapGestureRecognizer()
            let publisher = PublishSubject<Void>()
            recognizer.rx.event.subscribe(onNext: { _ in
                publisher.onNext(())
            }, onDisposed: { publisher.onCompleted() }).disposed(by: base.removed)
            base.addGestureRecognizer(recognizer)
            return publisher
        }
    }
    var longClick: Observable<Void> {
        base.isUserInteractionEnabled = true
        let recognizer = UILongPressGestureRecognizer()
        let publisher = PublishSubject<Void>()
        recognizer.rx.event.subscribe(onNext: { [weak recognizer] ev in
            guard let recognizer = recognizer else { return }
            if recognizer.state == .ended {
                publisher.onNext(())
            }
        }, onDisposed: { publisher.onCompleted() }).disposed(by: base.removed)
        base.addGestureRecognizer(recognizer)
        return publisher
    }
}

public extension UIView {
    
//    @objc var elevation: CGFloat {
//        get {
//            return layer.shadowRadius
//        }
//        set(value) {
//            layer.shadowOffset = CGSize(width: 0, height: value)
//            layer.shadowRadius = value
//            layer.shadowOpacity = 0.5
//            layer.shadowColor = UIColor.black.cgColor
//        }
//    }
    
    func setOnClickListener(_ action: @escaping (UIView)->Void) {
        rx.click
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                action(self)
            })
            .disposed(by: removed)
    }
    func setOnLongClickListener(_ action: @escaping (UIView)->Bool) {
        rx.longClick
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let _ = action(self)
            })
            .disposed(by: removed)
    }

    func onClick(disabledMilliseconds: Int = 500, action: @escaping ()->Void) {
        rx.click.throttle(.milliseconds(Int(disabledMilliseconds)), latest: false, scheduler: MainScheduler.instance)
            .subscribe(onNext: action)
            .disposed(by: removed)
    }
    func onLongClick(action: @escaping ()->Void) {
        rx.longClick
            .subscribe(onNext: action)
            .disposed(by: removed)
    }
    func onClick<T>(_ observable: Observable<T>, disabledMilliseconds: Int = 500, action: @escaping (T)->Void) {
        rx.click.throttle(.milliseconds(Int(disabledMilliseconds)), latest: false, scheduler: MainScheduler.instance)
            .flatMap { _ in observable.take(1) }
            .subscribe(onNext: action)
            .disposed(by: removed)
    }
    func onLongClick<T>(_ observable: Observable<T>, action: @escaping (T)->Void) {
        rx.longClick
            .flatMap { _ in observable.take(1) }
            .subscribe(onNext: action)
            .disposed(by: removed)
    }
}
