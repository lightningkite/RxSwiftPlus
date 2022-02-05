//
//  UIView+replace.swift
//  XmlToXibRuntime
//
//  Created by Joseph Ivie on 2/1/22.
//

import UIKit

extension UIView {
    public func replace(other: UIView) {
        if let superview = superview {
            if let superview = superview as? UIStackView {
                guard let index = (superview.arrangedSubviews.firstIndex { $0 == self }) else { return }
                self.removeFromSuperview()
                superview.insertArrangedSubview(other, at: index)
            } else {
                guard let index = (superview.subviews.firstIndex { $0 == self }) else { return }
                self.removeFromSuperview()
                //TODO: Actually copy the old constraints.
                superview.insertSubview(other, at: index)
                other.leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
                other.rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
                other.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
                other.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
            }
        }
    }
}
