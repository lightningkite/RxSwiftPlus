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
        self.main = EmptyViewGenerator()
        super.init(coder: coder)
    }
        
    weak var backgroundLayerBottom: UIView!
    weak var innerView: UIView!
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
        
        rerender()
    }
    private func rerender(){
        if let old = innerView {
            old.removeFromSuperview()
            post {
                old.refreshLifecycle()
            }
        }
        let m = main.generate(dependency: ViewControllerAccess(self))
        innerView = m
        innerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(innerView)
        
        m.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        m.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        m.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        m.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }
    
}
