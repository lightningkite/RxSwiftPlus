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

protocol HasAtPosition {
    var atPosition: (Int) -> Void { get set }
}

class SillyDataSource<T>: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, HasAtPosition {
    var reversedDirection: Bool = false
    
    var data: Array<T> = []
    let makeView: (T) -> UIView

    init(makeView: @escaping (T) -> UIView) {
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
        let cell: ObsUICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "main-cell", for: indexPath) as! ObsUICollectionViewCell
        for sub in cell.contentView.subviews {
            sub.removeFromSuperview()
        }
        let newView = makeView(data[indexPath.row])
        cell.contentView.addSubview(newView)
        newView.translatesAutoresizingMaskIntoConstraints = false
        newView.topAnchor.constraint(equalTo: cell.contentView.topAnchor).isActive = true
        newView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor).isActive = true
        newView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor).isActive = true
        newView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true
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
    func showIn(_ view: UICollectionView, showIndex: Subject<Int> = BehaviorSubject(value: 0), makeView: @escaping (Element) -> UIView) -> Self {
        view.collectionViewLayout = ViewPagerLayout()
        
        view.register(ObsUICollectionViewCell.self, forCellWithReuseIdentifier: "main-cell")
        let boundDataSource = SillyDataSource<Element>(makeView: makeView)
        boundDataSource.data = Array(self)
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

public extension ObservableType where Element: Collection {
    @discardableResult
    func showIn(_ view: UICollectionView, showIndex: Subject<Int> = BehaviorSubject(value: 0), makeView: @escaping (Observable<Element.Element>) -> UIView) -> Self {
        
        view.collectionViewLayout = ViewPagerLayout()
        
        view.register(ObsUICollectionViewCell.self, forCellWithReuseIdentifier: "main-cell")
        let boundDataSource = GeneralCollectionDelegate<Element.Element>(makeView: { a, b in makeView(a) })
        view.dataSource = boundDataSource
        view.delegate = boundDataSource
        view.retain(item: boundDataSource).disposed(by: view.removed)
        
        var suppress = false
        var positioned = false
        showIndex.subscribe(onNext: { value in
            guard !suppress else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
                view.scrollToItem(at: IndexPath(row: value, section: 0), at: .centeredHorizontally, animated: positioned)
                positioned = true
                print("Scrolling to \(value)")
            })
        }).disposed(by: view.removed)
        let observer = showIndex.asObserver()
        view.whenScrolled { newIndex in
            suppress = true
            print("Scrolled to \(newIndex)")
            observer.onNext(newIndex)
            suppress = false
        }
        var updateQueued = false
        self.subscribe(
            onNext: { it in
                guard !updateQueued else { return }
                updateQueued = true
                post {
                    updateQueued = false
                    boundDataSource.items = Array<Element.Element>(it)
                    view.refreshData()
                }
            },
            onError: nil,
            onCompleted: nil,
            onDisposed: nil
        ).disposed(by: view.removed)
        
        
        return self
    }
}

public class ViewPagerLayout: UICollectionViewFlowLayout {
    override public func prepare() {
        self.scrollDirection = .horizontal
        self.sectionInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        if #available(iOS 11.0, *) {
            self.sectionInsetReference = .fromSafeArea
        } else {
            // Fallback on earlier versions
        }
        
        guard let collectionView = collectionView else { return }
        let observer = collectionView.layer.observe(\.bounds) { [weak self] collectionView, _ in
            guard let self = self else { return }
            let newSize = CGSize(
                width: collectionView.bounds.width,
                height: collectionView.bounds.height
            )
            if newSize != self.itemSize {
                self.itemSize = newSize
            }
        }
        let newSize = CGSize(
            width: collectionView.bounds.width,
            height: collectionView.bounds.height
        )
        if newSize != self.itemSize {
            self.itemSize = newSize
        }
        collectionView.removed.insert(DisposableLambda { observer.invalidate() })
    }
    
    override public func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {

        guard let collectionView = self.collectionView else {
            let latestOffset = super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
            return latestOffset
        }

        // Page width used for estimating and calculating paging.
        let pageWidth = self.itemSize.width + self.minimumInteritemSpacing

        // Make an estimation of the current page position.
        let approximatePage = collectionView.contentOffset.x/pageWidth

        // Determine the current page based on velocity.
        let currentPage = velocity.x == 0 ? round(approximatePage) : (velocity.x < 0.0 ? floor(approximatePage) : ceil(approximatePage))

        // Create custom flickVelocity.
        let flickVelocity = velocity.x * 0.3

        // Check how many pages the user flicked, if <= 1 then flickedPages should return 0.
        let flickedPages = (abs(round(flickVelocity)) <= 1) ? 0 : round(flickVelocity)

        // Calculate newHorizontalOffset.
        let newHorizontalOffset = ((currentPage + flickedPages) * pageWidth) - collectionView.contentInset.left

        return CGPoint(x: newHorizontalOffset, y: proposedContentOffset.y)
    }
}
