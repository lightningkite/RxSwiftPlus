//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import UIKit
import RxSwift
import RxCocoa

internal func post(action: @escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.0001, execute: action)
}

fileprivate extension UICollectionViewCompositionalLayout {
    static let fractionalWidthExtension = ExtensionProperty<UICollectionViewCompositionalLayout, CGFloat?>()
    var fractionalWidth: CGFloat? {
        get { return UICollectionViewCompositionalLayout.fractionalWidthExtension.get(self) ?? nil }
        set(value) { UICollectionViewCompositionalLayout.fractionalWidthExtension.set(self, value) }
    }
    static let fractionalHeightExtension = ExtensionProperty<UICollectionViewCompositionalLayout, CGFloat?>()
    var fractionalHeight: CGFloat? {
        get { return UICollectionViewCompositionalLayout.fractionalHeightExtension.get(self) ?? nil }
        set(value) { UICollectionViewCompositionalLayout.fractionalHeightExtension.set(self, value) }
    }
}

internal class FixedLayout: UICollectionViewCompositionalLayout {
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        if let collectionView = collectionView {
            context.invalidateFlowLayoutDelegateMetrics = collectionView.bounds.size != newBounds.size
        }
        return context
    }
}

public class QuickCompositionalLayout {
    public static func list(vertical: Bool = true, reverse: Bool = false) -> UICollectionViewLayout {
        if vertical {
            let size = NSCollectionLayoutSize(
                widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
                heightDimension: NSCollectionLayoutDimension.estimated(45)
            )
            let item = NSCollectionLayoutItem(layoutSize: size)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)
            let section = NSCollectionLayoutSection(group: group)
            let result = UICollectionViewCompositionalLayout(section: section)
            result.fractionalWidth = 1
            return result
        } else {
            let size = NSCollectionLayoutSize(
                widthDimension: NSCollectionLayoutDimension.estimated(45),
                heightDimension: NSCollectionLayoutDimension.fractionalHeight(1)
            )
            let item = NSCollectionLayoutItem(layoutSize: size)
            let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitem: item, count: 1)
            let section = NSCollectionLayoutSection(group: group)
            let result = UICollectionViewCompositionalLayout(section: section)
            let config = result.configuration
            config.scrollDirection = .horizontal
            result.configuration = config
            result.fractionalHeight = 1
            return result
        }
    }
    public static func grid(orthogonalCount: Int, vertical: Bool = true) -> UICollectionViewLayout {
        if vertical {
            let size = NSCollectionLayoutSize(
                widthDimension: NSCollectionLayoutDimension.fractionalWidth(1.0),
                heightDimension: NSCollectionLayoutDimension.estimated(100)
            )
            let item = NSCollectionLayoutItem(layoutSize: size)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: orthogonalCount)
            let section = NSCollectionLayoutSection(group: group)
            let result = UICollectionViewCompositionalLayout(section: section)
            result.fractionalWidth = 1.0/CGFloat(orthogonalCount)
            return result
        } else {
            let size = NSCollectionLayoutSize(
                widthDimension: NSCollectionLayoutDimension.estimated(100),
                heightDimension: NSCollectionLayoutDimension.fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: size)
            let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitem: item, count: orthogonalCount)
            let section = NSCollectionLayoutSection(group: group)
            let result = UICollectionViewCompositionalLayout(section: section)
            let config = result.configuration
            config.scrollDirection = .horizontal
            result.configuration = config
            result.fractionalHeight = 1.0/CGFloat(orthogonalCount)
            return result
        }
    }
}

//--- RecyclerView.whenScrolledToEnd(()->Unit)
public extension UICollectionView {
    fileprivate static let itemsToReloadSoon = ExtensionProperty<UICollectionView, Set<IndexPath>>()
    fileprivate var itemsToReloadSoon: Set<IndexPath> {
        get {
            return UICollectionView.itemsToReloadSoon.get(self) ?? []
        }
        set(value) {
            UICollectionView.itemsToReloadSoon.set(self, value)
        }
    }
    fileprivate func reloadItemsSoon(_ items: Set<IndexPath>) {
        if itemsToReloadSoon.isEmpty {
            post {
                let itemsToReload = self.itemsToReloadSoon.filter { $0.section < self.numberOfSections && $0.row < self.numberOfItems(inSection: $0.section) }
                //                 print(itemsToReload)
                self.reloadItems(at: Array(itemsToReload))
                self.itemsToReloadSoon = []
            }
        }
        for i in items {
            itemsToReloadSoon.insert(i)
        }
    }
    
    fileprivate static let refreshQueued = ExtensionProperty<UICollectionView, Bool>()
    fileprivate func refreshDataDelayed() {
        if !(UICollectionView.refreshQueued.get(self) ?? false) {
            UICollectionView.refreshQueued.set(self, true)
            post {
                self.refreshData()
                UICollectionView.refreshQueued.set(self, false)
            }
        }
    }
    internal func refreshData(){
        self.retainPositionTargetIndex {
            self.reloadData()
        }
    }
    
    fileprivate static let refreshSizeQueued = ExtensionProperty<UICollectionView, Bool>()
    internal func refreshSizes() {
        if !(UICollectionView.refreshSizeQueued.get(self) ?? false) {
            UICollectionView.refreshSizeQueued.set(self, true)
            
            guard let centerId = self.indexPathForItem(at: CGPoint(x: self.contentOffset.x + self.frame.midX, y: self.contentOffset.y)) else { return }
            guard let oldCenterPos = self.collectionViewLayout.layoutAttributesForItem(at: centerId)?.frame.origin else { return }
            let oldScreenY = oldCenterPos.y - self.contentOffset.y
            
            post {
                self.collectionViewLayout.invalidateLayout()
                self.layoutIfNeeded()
                self.collectionViewLayout.invalidateLayout()
                self.layoutIfNeeded()
                var lastDiff: CGFloat = 10000.0
                while true {
                    let newCenterPos = self.collectionViewLayout.layoutAttributesForItem(at: centerId)?.frame.origin ?? oldCenterPos
                    let newScreenY = newCenterPos.y - self.contentOffset.y
                    let offset = newScreenY - oldScreenY
                    if lastDiff == offset {
                        break
                    }
                    lastDiff = offset
                    self.contentOffset.y += offset
                    self.layoutIfNeeded()
                    if abs(offset) < 4 { break }
                }
                UICollectionView.refreshSizeQueued.set(self, false)
            }
        }
    }
    
    func scrollToItemSafe(at: IndexPath, at pos: ScrollPosition = .centeredVertically, animated: Bool = false){
        if at.section >= 0, at.row >= 0, at.section < self.numberOfSections, at.row < self.numberOfItems(inSection: at.section) {
            scrollToItem(at: at, at: pos, animated: animated)
        }
    }
    fileprivate func retainPositionTargetIndex(around: ()->Void) {
        guard let centerId = self.indexPathForItem(at: CGPoint(x: self.contentOffset.x + self.frame.midX, y: self.contentOffset.y)) else { around(); return }
        guard let oldCenterPos = self.collectionViewLayout.layoutAttributesForItem(at: centerId)?.frame.origin else { around(); return }
        let oldScreenY = oldCenterPos.y - self.contentOffset.y
        //         print("Cell \(centerId) was at \(oldScreenY)")
        around()
        while true {
            let newCenterPos = self.collectionViewLayout.layoutAttributesForItem(at: centerId)?.frame.origin ?? oldCenterPos
            let newScreenY = newCenterPos.y - self.contentOffset.y
            let offset = newScreenY - oldScreenY
            self.contentOffset.y += offset
            self.layoutIfNeeded()
            //             print("Cell \(centerId) is now at \(newScreenY) after moving \(offset)")
            if abs(offset) < 4 { break }
        }
        post {
            let newCenterPos = self.collectionViewLayout.layoutAttributesForItem(at: centerId)?.frame.origin ?? oldCenterPos
            let newScreenY = newCenterPos.y - self.contentOffset.y
            //             print("Cell \(centerId) is now at \(newScreenY) after a post")
        }
    }
    
    //--- RecyclerView.bind(Property<List<T>>, T, (Property<T>)->UIView)
    fileprivate func setupDefault() {
        let current = self.collectionViewLayout
        if current is UICollectionViewFlowLayout {
            self.collectionViewLayout = QuickCompositionalLayout.list()
        }
        if let current = current as? UICollectionViewCompositionalLayout {
            current.configuration.interSectionSpacing = max(self.contentInset.top, self.contentInset.bottom)
        }
    }
    
}


class GeneralCollectionDelegate<T>: ScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, HasAtPosition {
    var items: Array<T> = []
    let makeView: (Observable<T>, Int) -> UIView
    let getType: (T) -> Int
    var atPosition: (Int) -> Void = { _ in }
    private var lastReportedScroll = -1
    private var recentlyScrolled = false
    
    init(
        makeView: @escaping (Observable<T>, Int) -> UIView,
        getType: @escaping (T) -> Int = { _ in 0 },
        atPosition: @escaping (Int) -> Void = { _ in }
    ) {
        self.makeView = makeView
        self.getType = getType
        self.atPosition = atPosition
    }
    
    fileprivate var registered: Set<Int> = []
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = items[indexPath.row]
        let type = getType(item)
        if registered.insert(type).inserted {
            collectionView.register(ObsUICollectionViewCell.self, forCellWithReuseIdentifier: String(type))
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(type), for: indexPath) as! ObsUICollectionViewCell
        cell.indexPath = indexPath
        //        cell.resizeEnabled = false
        if collectionView.reverseDirection {
            cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        } else {
            cell.contentView.transform = .identity
        }
        
        if cell.obs == nil {
            let obs = BehaviorSubject(value: item)
            let newView = makeView(obs, type)
            cell.contentView.addSubview(newView)
            newView.translatesAutoresizingMaskIntoConstraints = false
            newView.topAnchor.constraint(equalTo: cell.contentView.topAnchor).isActive = true
            newView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor).isActive = true
            newView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor).isActive = true
            newView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true
            cell.obs = obs
        }
        if let obs = cell.obs as? BehaviorSubject<T> {
            if cell.indexPath == indexPath {
                obs.onNext(item)
                cell.setNeedsLayout()
            } else {
                UIView.performWithoutAnimation {
                    obs.onNext(item)
                    cell.setNeedsLayout()
                    cell.layoutIfNeeded()
                }
            }
        } else {
            fatalError("Could not find cell observable")
        }
        //        cell.absorbCaps(collectionView: collectionView)
        //        cell.resizeEnabled = true
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let cell = cell as? ObsUICollectionViewCell {
            cell.indexPath = nil
        }
    }
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let collectionView = scrollView as! UICollectionView
        if let x = collectionView.currentIndex {
            if x != lastReportedScroll {
                recentlyScrolled = true
                atPosition(Int(x))
                lastReportedScroll = x
            }
        }
        
        let scrollViewHeight = scrollView.frame.size.height;
        let scrollContentSizeHeight = scrollView.contentSize.height;
        let scrollOffset = scrollView.contentOffset.y;
        
        if let atEnd = UIScrollView.atEndExtension.get(scrollView) {
            if (scrollOffset + scrollViewHeight == scrollContentSizeHeight && recentlyScrolled)
            {
                recentlyScrolled = false
                atEnd()
            }
        }
    }
}

class ObsUICollectionViewCell: UICollectionViewCell {
    
    weak var collectionView: UICollectionView?
    var obs: Any?
    //    var resizeEnabled = false
    var indexPath: IndexPath? = nil
    
    //    var heightSetSize: CGFloat? = nil
    //    var widthSetSize: CGFloat? = nil
    //
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit(){
        self.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        ({ () -> Void in
            let c = contentView.topAnchor.constraint(equalTo: self.topAnchor)
            //            c.priority = UILayoutPriority(999)
            c.isActive = true
        })()
        ({ () -> Void in
            let c = contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor)
            //            c.priority = UILayoutPriority(999)
            c.isActive = true
        })()
        ({ () -> Void in
            let c = contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            //            c.priority = UILayoutPriority(999)
            c.isActive = true
        })()
        ({ () -> Void in
            let c = contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            //            c.priority = UILayoutPriority(999)
            c.isActive = true
        })()
    }
    //
    //    override func layoutSubviews() {
    //        contentView.frame = self.bounds
    //        for child in contentView.subviews {
    //            child.frame = contentView.bounds
    //        }
    //    }
    //
    //    func absorbCaps(collectionView: UICollectionView){
    //        self.collectionView = collectionView
    //        if let layout = collectionView.collectionViewLayout as? UICollectionViewCompositionalLayout {
    //            if let s = layout.fractionalWidth {
    //                widthSetSize = collectionView.frame.size.width * s
    //            }
    //            if let s = layout.fractionalHeight {
    //                heightSetSize = collectionView.frame.size.height * s
    //            }
    //        }
    //    }
    //
    //    var lastSize: CGSize = .zero
    //    private func internalMeasure(_ targetSize: CGSize) -> CGSize {
    //        var newTargetSize = targetSize
    //        if let widthSetSize = widthSetSize {
    //            newTargetSize.width = widthSetSize
    //        }
    //        if let heightSetSize = heightSetSize {
    //            newTargetSize.height = heightSetSize
    //        }
    //        var maxX: CGFloat = 0
    //        var maxY: CGFloat = 0
    //        for child in contentView.subviews {
    //            let childSize = child.systemLayoutSizeFitting(newTargetSize)
    //            if childSize.width > maxX { maxX = childSize.width }
    //            if childSize.height > maxY { maxY = childSize.height }
    //        }
    //        return CGSize(width: maxX, height: maxY)
    //    }
    //
    //    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
    //        let newSize = internalMeasure(targetSize)
    //        lastSize = newSize
    //        return newSize
    //    }
    //
    //    override func sizeThatFits(_ size: CGSize) -> CGSize {
    //        return systemLayoutSizeFitting(size)
    //    }
    //    override var intrinsicContentSize: CGSize {
    //        return systemLayoutSizeFitting(CGSize.zero)
    //    }
    //
    //    func childSizeUpdated(_ child: UIView) {
    //        guard resizeEnabled, lastSize != internalMeasure(.zero) else { return }
    //        self.setNeedsLayout()
    //        if let collectionView = collectionView {
    //            if self.indexPath != nil {
    //                collectionView.refreshSizes()
    //            }
    //        }
    //    }
    
    //    deinit {
    //        self.removedDeinitHandler()
    //    }
}

public extension UICollectionView {
    
    class ReversibleFlowLayout: UICollectionViewFlowLayout {}
    
    //--- RecyclerView.reverseDirection
    internal static let extensionReverse = ExtensionProperty<UICollectionView, Bool>()
    
    @objc
    var reverseDirection: Bool {
        get {
            return UICollectionView.extensionReverse.get(self) ?? false
        }
        set(value) {
            UICollectionView.extensionReverse.set(self, value)
            let transform = value ? CGAffineTransform(scaleX: 1, y: -1) : .identity
            self.transform = transform
            for cell in self.visibleCells {
                cell.contentView.transform = transform
                cell.setNeedsDisplay()
            }
        }
    }
}


public extension ObservableType where Element: Collection {
    
    @discardableResult
    func showIn(_ view: UICollectionView, makeView: @escaping (Observable<Element.Element>) -> UIView) -> Self{
        view.setupDefault()
        post {
            let dg = GeneralCollectionDelegate<Element.Element>(
                makeView: { (obs, _) in makeView(obs) }
            )
            view.retain(item: dg).disposed(by: view.removed)
            view.delegate = dg
            view.dataSource = dg
            
            var updateQueued = false
            var latestInQueue: Array<Element.Element> = []
            self.subscribe(
                onNext: { it in
                    latestInQueue = Array(it)
                    guard !updateQueued else { return }
                    updateQueued = true
                    post {
                        updateQueued = false
                        dg.items = latestInQueue
                        view.refreshData()
                    }
                },
                onError: nil,
                onCompleted: nil,
                onDisposed: nil
            ).disposed(by: view.removed)
        }
        return self
    }
    
    @discardableResult
    func showIn(_ view: UICollectionView, determineType: @escaping (Element.Element) -> Int, makeView: @escaping (Int, Observable<Element.Element>) -> UIView) -> Self {
        view.setupDefault()
        post {
            let dg = GeneralCollectionDelegate<Element.Element>(
                makeView: { (obs, type) in makeView(type, obs) },
                getType: determineType
            )
            view.retain(item: dg).disposed(by: view.removed)
            view.delegate = dg
            view.dataSource = dg
            var updateQueued = false
            var latestInQueue: Array<Element.Element> = []
            self.subscribe(
                onNext: { it in
                    latestInQueue = Array(it)
                    guard !updateQueued else { return }
                    updateQueued = true
                    post {
                        updateQueued = false
                        dg.items = latestInQueue
                        view.refreshData()
                    }
                },
                onError: nil,
                onCompleted: nil,
                onDisposed: nil
            ).disposed(by: view.removed)
        }
        return self
    }
    
}
