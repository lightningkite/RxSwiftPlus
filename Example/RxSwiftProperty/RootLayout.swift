//
//  SelectorLayout.swift
//  RxSwiftProperty_Example
//
//  Created by Joseph Ivie on 8/30/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import RxSwiftProperty

class RootLayout: UIView {
    
    @IBOutlet weak var swapView: SwapView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var label: UILabel!
    
    static func make() -> Self {
        return UINib(nibName: "RootLayout", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! Self
    }
}
