//
//  SwapView.swift
//  Butterfly
//
//  Created by Joseph Ivie on 10/24/19.
//  Copyright © 2019 Lightning Kite. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
open class SwapView: UIView {
    public enum Animation {
        case push
        case pop
        case fade
    }
    var current: UIView?
    private var constraintsForView = Dictionary<UIView, Array<NSLayoutConstraint>>()
    
    private var hiding = false
    var swapping = false
    open func swap(dependency: ViewControllerAccess, to: UIView?, animation: Animation){
        if swapping {
            fatalError()
        }
        let previouslyHiding = self.hiding
        let hiding = to == nil
        self.hiding = hiding
        swapping = true
        let previousView = current
        if let old = current {
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                if hiding {
                    old.alpha = 0
                    self?.isHidden = true
                } else {
                    switch animation {
                    case .fade:
                        old.alpha = 0
                    case .pop:
                        old.transform = CGAffineTransform.init(translationX: old.frame.width, y: 0)
                    case .push:
                        old.transform = CGAffineTransform.init(translationX: -old.frame.width, y: 0)
                    }
                }
            }, completion: { _ in
                old.removeFromSuperview()
            })
        }
        if let new = to {
            UIView.performWithoutAnimation {
                self.isHidden = false
                self.addSubview(new)
                new.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
                self.rightAnchor.constraint(equalTo: new.rightAnchor).isActive = true
                new.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
                self.bottomAnchor.constraint(equalTo: new.bottomAnchor).isActive = true
                
//                new.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
////                self.rightAnchor.constraint(equalTo: new.rightAnchor).isActive = true
//                new.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
////                self.bottomAnchor.constraint(equalTo: new.bottomAnchor).isActive = true
//                let huggingConstraints = [
////                    new.leftAnchor.constraint(equalTo: self.leftAnchor),
//                    self.rightAnchor.constraint(equalTo: new.rightAnchor),
////                    new.topAnchor.constraint(equalTo: self.topAnchor),
//                    self.bottomAnchor.constraint(equalTo: new.bottomAnchor)
//                ]
//                let compressingConstraints = [
////                    new.leftAnchor.constraint(greaterThanOrEqualTo: self.leftAnchor),
//                    self.rightAnchor.constraint(lessThanOrEqualTo: new.rightAnchor),
////                    new.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor),
//                    self.bottomAnchor.constraint(lessThanOrEqualTo: new.bottomAnchor)
//                ]
//                for c in huggingConstraints {
//                    c.priority = .defaultLow
//                    c.isActive = true
//                }
//                for c in compressingConstraints {
//                    c.priority = .defaultHigh
//                    c.isActive = true
//                }
                
                self.layoutIfNeeded()
                if previouslyHiding {
                    new.alpha = 0
                } else {
                    switch animation {
                    case .fade:
                        new.alpha = 0
                    case .pop:
                        new.transform = CGAffineTransform.init(translationX: -self.frame.width, y: 0)
                    case .push:
                        new.transform = CGAffineTransform.init(translationX: self.frame.width, y: 0)
                    }
                }
            }
            UIView.animate(withDuration: 0.25, animations: { [self] in
                new.transform = .identity
                new.alpha = 1
            }, completion: { _ in
                // yahoo!
            })
            current = new
        } else {
            current = nil
        }
        dependency.runKeyboardUpdate(root: to, discardingRoot: previousView)
        swapping = false
    }
    
    weak var lastHit: UIView?
    var lastPoint: CGPoint?
    override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        lastPoint = point
        for key in subviews.reversed() {
            guard !key.isHidden, key.alpha > 0.1 else { continue }
            if key.frame.contains(point) {
                lastHit = key
                if let sub = key.hitTest(key.convert(point, from: self), with: event) {
                    return sub
                } else {
                    return key
                }
            }
        }
        return nil
    }}

