//
//  ContainerView.swift
//  RxSwiftProperty
//
//  Created by Joseph Ivie on 11/8/21.
//

import UIKit

public class ContainerView: UIView {
    public var contained: UIViewController? {
        didSet {
            containedView?.removeFromSuperview()
            if let set = contained {
                self.parentViewController?.addChild(set)
                containedView = set.view
            } else {
                containedView = nil
            }
            setNeedsLayout()
        }
    }
    private var containedView: UIView?
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        containedView?.frame = self.bounds
    }
    
    deinit {
        contained?.removeFromParent()
    }
}
private extension UIResponder {
    var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}
