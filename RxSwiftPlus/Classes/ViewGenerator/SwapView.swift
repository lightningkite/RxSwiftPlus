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
    var swapping = false
    
    open func swap(dependency: ViewControllerAccess?, to: UIView?, transition: TransitionTriple){
        if swapping {
            fatalError()
        }
        swapping = true
        
        //animate out
        if let old = current {
            UIView.animate(withDuration: 0.25, animations: {
                transition.exit(old)
            }, completion: { [weak self] _ in
                old.removeFromSuperview()
                if(to == nil){
                    self?.visible = false
                }
            })
        }
        
        
        if let newView = to{
            self.visible = true
            UIView.performWithoutAnimation {
                self.isHidden = false
                self.addSubview(newView)
                newView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
                self.rightAnchor.constraint(equalTo: newView.rightAnchor).isActive = true
                newView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
                self.bottomAnchor.constraint(equalTo: newView.bottomAnchor).isActive = true
                
                self.layoutIfNeeded()
                transition.enter(newView)
            }
            
            //animate in
            UIView.animate(
                withDuration: 0.25,
                animations: {
                    newView.transform = .identity
                    newView.alpha = 1
                },
                completion: { [weak self] _ in
                    self?.visible = true
                }
            )
        }
        
        current = to
        dependency?.runKeyboardUpdate(root: to, discardingRoot: current)
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
    }
}

