//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import UIKit
import RxSwift
import RxCocoa


//--- TabLayout.bind(List<String>, MutableProperty<Int>)
public extension UISegmentedControl {
    
    func bind<Subject: SubjectType>(
        tabs: Array<Subject.Element>,
        selected: Subject,
        allowReselect:Bool = false,
        toString: @escaping (Subject.Element) -> String
    ) -> Void where Subject.Observer.Element == Subject.Element, Subject.Element: Equatable {
        self.removeAllSegments()
        for entry in tabs {
            self.insertSegment(withTitle: toString(entry), at: self.numberOfSegments, animated: false)
        }
        if allowReselect {
            self.addAction(for: .valueChanged, action: { [weak self] in
                if let i = self?.selectedSegmentIndex, i >= 0, i < tabs.count {
                    selected.asObserver().onNext(tabs[i])
                }
            }).disposed(by: self.removed)
        }else{
            self.addAction(for: .valueChanged, action: { [weak self] in
                selected.asObserver().onNext(tabs[self?.selectedSegmentIndex ?? 0])
            }).disposed(by: self.removed)
        }
        selected.subscribe(onNext:  { value in
            self.selectedSegmentIndex = tabs.firstIndex(of: value) ?? 0
        }).disposed(by: self.removed)
    }
    
}
