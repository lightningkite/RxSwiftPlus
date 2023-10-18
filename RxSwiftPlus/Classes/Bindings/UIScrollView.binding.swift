//
//  UIScrollView.binding.swift
//  RxSwiftPlus
//
//  Created by Brady Svedin on 10/17/23.
//

import Foundation
import UIKit

public extension UIScrollView{
    
    internal static let atEndExtension = ExtensionProperty<UIScrollView, ()->Void>()
    func whenScrolledToEnd(action: @escaping () -> Void) -> Void{
        if(self.delegate == nil){
            let dg = ScrollViewDelegate()
            self.delegate = dg
            self.retain(item: dg).disposed(by: self.removed)
        }
        UIScrollView.atEndExtension.set(self, action)
    }
}

class ScrollViewDelegate: NSObject, UIScrollViewDelegate{

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollViewHeight = scrollView.frame.size.height;
        let scrollContentSizeHeight = scrollView.contentSize.height;
        let scrollOffset = scrollView.contentOffset.y;
        
        if let atEnd = UIScrollView.atEndExtension.get(scrollView) {
            if (scrollOffset + scrollViewHeight == scrollContentSizeHeight)
            {
                atEnd()
            }
        }
    }

}
