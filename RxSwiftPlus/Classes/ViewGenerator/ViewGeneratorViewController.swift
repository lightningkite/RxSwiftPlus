//
//  ButterflyViewController.swift
//  Butterfly
//
//  Created by Joseph Ivie on 10/21/19.
//  Copyright © 2019 Lightning Kite. All rights reserved.
//

import Foundation
import UIKit
import RxSwift


open class ViewGeneratorViewController: UIViewController, UINavigationControllerDelegate {
    
    open var main: ViewGenerator
    public init(_ main: ViewGenerator){
        self.main = main
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        self.main = ViewGeneratorDefault()
        super.init(coder: coder)
    }
        
    weak var innerView: UIView!
    static public var refreshViewOnRotate: Bool = false
    private let bag = DisposeBag()
    
    open var defaultBackgroundColor: UIColor = .white
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.view = UIView(frame: .zero)
        self.view.backgroundColor = defaultBackgroundColor
        
        showDialogEvent.subscribe(onNext: { [weak self] (request) in
            guard let self = self else { return }
            let message = request.string
            let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
            if let confirmation = request.confirmation {
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    confirmation()
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                    
                }))
            } else {
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    
                }))
            }
            self.present(alert, animated: true, completion: {})
        }).disposed(by: bag)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        rerender()
    }
    private var bottomConstraint: NSLayoutConstraint?
    private func rerender(){
        if let old = innerView {
            old.removeFromSuperview()
        }
        let m = main.generate(dependency: ViewControllerAccess(self))
        innerView = m
        innerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(innerView)
        
        m.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        m.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        m.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        let constraint = self.view.bottomAnchor.constraint(equalTo: m.bottomAnchor)
        constraint.isActive = true
        bottomConstraint = constraint
    }
    
    private var suppressKeyboardUpdate: Bool = false
    override open func viewDidAppear(_ animated: Bool) {
        addKeyboardObservers()
    }
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeKeyboardObservers()
    }
    
    var previouslyLandscape: Bool?
    open override func viewWillLayoutSubviews() {
        if ViewGeneratorViewController.refreshViewOnRotate {
            let newLandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
            if previouslyLandscape != newLandscape {
                previouslyLandscape = newLandscape
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
                    self.rerender()
                })
            }
        }
    }
    
    /// Asks the system to resign all first responders (usually input fields), which effectively
    /// causes the keyboard to dismiss itself.
    func resignAllFirstResponders() {
        view.endEditing(true)
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    var lastFocus: Date = Date()
    var lastTapPosition: CGPoint = .zero
    
    @objc func dismissKeyboard(gestureRecognizer: UITapGestureRecognizer) {
        lastTapPosition = gestureRecognizer.location(in: self.view)
        let x = self.view.firstResponder
        post {
            let y = self.view.firstResponder
            if x === y {
                self.resignAllFirstResponders()
            }
        }
    }
    
    func addKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    /// Remove observers that were added previously.
    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: self.view.window
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: self.view.window
        )
    }

    var suppressIsActive = false
    
    /// Method's notified when the keyboard is about to be shown or change its size.
    ///
    /// - Parameter notification: System keyboard notification
    @objc func keyboardWillChangeFrame(notification: NSNotification) {
        if
            let userInfo = notification.userInfo,
            let keyboardFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let keyboardAnimationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber
        {
            let keyboardHeight = keyboardFrameValue.cgRectValue.height
            if keyboardHeight > 20 {
                post {
                    self.suppressKeyboardUpdate = true
                    if !ApplicationAccess.INSTANCE.softInputActive.value {
                        ApplicationAccess.INSTANCE.softInputActive.value = true
                    }
                    self.suppressKeyboardUpdate = false
                }
            }
            UIView.animate(
                withDuration: keyboardAnimationDuration.doubleValue,
                animations: {
                    if #available(iOS 11.0, *) {
                        self.bottomConstraint?.constant = keyboardHeight - (self.view.window?.safeAreaInsets.bottom ?? 0)
                    } else {
                        self.bottomConstraint?.constant = keyboardHeight
                    }
                    self.view.layoutIfNeeded()
                },
                completion: { _ in
                }
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                if let view = UIResponder.current as? UIView {
                    view.scrollToMe(animated: true)
                }
            })
        }
    }
    
    /// Method's notified when the keyboard is about to be dismissed.
    ///
    /// - Parameter notification: System keyboard notification
    @objc func keyboardWillHide(notification: NSNotification) {
        if
            let userInfo = notification.userInfo,
            let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.suppressKeyboardUpdate = true
                ApplicationAccess.INSTANCE.softInputActive.value = false
                self.suppressKeyboardUpdate = false
            }
            UIView.animate(
                withDuration: animationDuration.doubleValue,
                animations: {
                    self.bottomConstraint?.constant = 0
                    self.view.layoutIfNeeded()
                },
                completion: { _ in
                }
            )
        }
    }

}
