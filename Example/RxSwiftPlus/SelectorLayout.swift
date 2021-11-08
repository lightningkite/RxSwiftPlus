//
//  SelectorLayout.swift
//  RxSwiftPlus_Example
//
//  Created by Joseph Ivie on 8/30/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

class SelectorLayout: UIView {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    static func make() -> Self {
        return UINib(nibName: "SelectorLayout", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! Self
    }
}
