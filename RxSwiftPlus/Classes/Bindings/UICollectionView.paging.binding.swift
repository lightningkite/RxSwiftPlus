//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import UIKit
import RxSwift
import RxCocoa

//--- ViewPager.bind(List<T>, MutableProperty<Int>, (T)->UIView)
public extension UICollectionView {

    //--- RecyclerView.bindRefresh(Property<Boolean>, ()->Unit)
    func bindRefresh(loading: Observable<Bool>, refresh: @escaping () -> Void) -> Void {
        let control = UIRefreshControl()
        control.addAction(for: .valueChanged, action: refresh).disposed(by: self.removed)
        if #available(iOS 10.0, *) {
            refreshControl = control
        } else {
            addSubview(control)
        }
        loading.subscribe(
            onNext: { (value) in
                if value {
                    control.beginRefreshing()
                } else {
                    control.endRefreshing()
                }
            }
        ).disposed(by: removed)
    }
    
    var currentIndex: Int? {
        return self.indexPathForItem(at: CGPoint(x: self.contentOffset.x + self.bounds.size.width / 2, y: self.contentOffset.y + self.bounds.size.height / 2))?.row
    }

    func whenScrolled(action: @escaping (_ index: Int)->Void) {
        if var delegate = delegate as? HasAtPosition {
            delegate.atPosition = action
        }
    }
}

class CustomUICollectionViewCell: UICollectionViewCell {
    var obs: Any?
    var spacing: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = self.bounds.insetBy(dx: spacing, dy: spacing)
        for child in contentView.subviews {
            child.frame = contentView.bounds
            child.layoutSubviews()
        }
    }
}

protocol HasAtPosition {
    var atPosition: (Int) -> Void { get set }
}

class SillyDataSource<T>: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, HasAtPosition {
    var reversedDirection: Bool = false
    
    var data: Array<T> = []
    let makeView: (T) -> UIView
    let spacing: CGFloat

    init(spacing: CGFloat, makeView: @escaping (T) -> UIView) {
        self.spacing = spacing
        self.makeView = makeView
        super.init()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = data.count
        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row >= (data.count) - 1 {
            if let atEnd = UICollectionView.atEndExtension.get(collectionView) {
                atEnd()
            }
        }
        let cell: CustomUICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "main-cell", for: indexPath) as! CustomUICollectionViewCell
        cell.spacing = self.spacing
        for sub in cell.contentView.subviews {
            sub.removeFromSuperview()
        }
        cell.contentView.addSubview(makeView(data[indexPath.row]))
        return cell
    }

    var atPosition: (Int) -> Void = { _ in }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let collectionView = scrollView as! UICollectionView
        if let x = collectionView.currentIndex {
            atPosition(Int(x))
        }
    }
}


public extension Collection {
    @discardableResult
    func showIn<Subject: SubjectType>(_ view: UICollectionView, showIndex: Subject = BehaviorSubject(value: 0) as! Subject, makeView: @escaping (Element) -> UIView) -> Self where Subject.Element == Int, Subject.Observer.Element == Int {
        
        view.register(CustomUICollectionViewCell.self, forCellWithReuseIdentifier: "main-cell")
        let boundDataSource = SillyDataSource<Element>(spacing: 0, makeView: makeView)
        view.dataSource = boundDataSource
        view.delegate = boundDataSource
        view.retain(item: boundDataSource).disposed(by: view.removed)
        
        var suppress = false
        showIndex.subscribe(onNext: { value in
            guard !suppress else { return }
            view.scrollToItem(at: IndexPath(row: value, section: 0), at: .centeredHorizontally, animated: true)
        }).disposed(by: view.removed)
        let observer = showIndex.asObserver()
        view.whenScrolled { newIndex in
            suppress = true
            observer.onNext(newIndex)
            suppress = false
        }
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
//            view.scrollToItem(at: IndexPath(row: Int(showIndex.value), section: 0), at: .centeredHorizontally, animated: false)
//        })
        
        return self
    }
}
