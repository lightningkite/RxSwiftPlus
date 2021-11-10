import RxSwift
import RxCocoa

extension ControlProperty: SubjectType {}

public class ValueSubjectDelegate<Element>: HasValueSubject<Element> {
    private let delegatedToObserver: Observer
    private let delegatedToObservable: Observable<Element>
    private let onGet: ()->Element
    private let onSet: (Element)->Void
    public override var value: Element {
        get {
            return onGet()
        }
        set(value) {
            onSet(value)
        }
    }
    public typealias Observer = AnyObserver<Element>
    public override func subscribe<Observer>(_ observer: Observer) -> Disposable where Observer : ObserverType, Element == Observer.Element {
        return delegatedToObservable.subscribe(observer)
    }
    
    public init(
        values: Observable<Element>,
        valueSink: Observer,
        onGet: @escaping ()->Element,
        onSet: @escaping (Element)->Void
    ) {
        self.delegatedToObserver = valueSink
        self.delegatedToObservable = values
        self.onGet = onGet
        self.onSet = onSet
        super.init()
    }
}

open class HasValueSubject<Element>: Subject<Element> {
    open var value: Element { get { fatalError() } set { fatalError() }}
    override public init() { super.init() }
}

public class ValueSubject<Element> : HasValueSubject<Element> {
    public let behaviorSubject: BehaviorSubject<Element>
    public override func on(_ event: Event<Element>) {
        behaviorSubject.on(event)
    }
    public override var value: Element {
        get {
            return try! behaviorSubject.value()
        }
        set(value) {
            behaviorSubject.onNext(value)
        }
    }
    public typealias Observer = AnyObserver<Element>
    public override func subscribe<Observer>(_ observer: Observer) -> Disposable where Observer : ObserverType, Element == Observer.Element {
        return behaviorSubject.subscribe(observer)
    }
    
    public init(_ value: Element) {
        self.behaviorSubject = BehaviorSubject(value: value)
        super.init()
    }
}

public extension SubjectType where Observer.Element == Element {
    func map<B>(read: @escaping (Element) -> B, write : @escaping (B) throws -> Element) -> ControlProperty<B>{
        return ControlProperty(values: map(read), valueSink: asObserver().mapObserver(write))
    }
    func mapMaybeWrite<B>(read: @escaping (Element) -> B, write : @escaping (B) -> Element?) -> ControlProperty<B>{
        return ControlProperty(values: map(read), valueSink: NextOnlyObserver { input in
            if let x = write(input) {
                self.asObserver().onNext(x)
            }
        })
    }
}

public extension HasValueSubject {
    func map<B>(read: @escaping (Element) -> B, write : @escaping (B) -> Element) -> ValueSubjectDelegate<B>{
        return ValueSubjectDelegate(
            values: map(read),
            valueSink: asObserver().mapObserver { write($0) },
            onGet: { read(self.value) },
            onSet: { self.asObserver().onNext( write($0)) }
        )
    }
    func mapMaybeWrite<B>(read: @escaping (Element) -> B, write : @escaping (B) -> Element?) -> ValueSubjectDelegate<B>{
        return ValueSubjectDelegate(
            values: map(read),
            valueSink: NextOnlyObserver { input in
                if let x = write(input) {
                    self.asObserver().onNext(x)
                }
            }.asObserver(),
            onGet: { read(self.value) },
            onSet: { if let x = write($0) { self.value = x } }
        )
    }
    func mapWithExisting<B>(read: @escaping (Element) throws -> B, write : @escaping (Element, B) -> Element) -> ValueSubjectDelegate<B> {
        return ValueSubjectDelegate(
            values: map(read),
            valueSink: asObserver().mapObserver { write(self.value, $0) },
            onGet: { try! read(self.value) },
            onSet: { self.asObserver().onNext(write(self.value, $0)) }
        )
    }
}

public extension ObservableType {
    func withWrite(onWrite: @escaping (Element)->Void) -> ControlProperty<Element> {
        return ControlProperty(
            values: self,
            valueSink: NextOnlyObserver(onWrite)
        )
    }
}

private class NextOnlyObserver<Element>: ObserverType {
    func on(_ event: Event<Element>) {
        switch event {
        case let .next(e):
            onNext(e)
        default: break
        }
    }
    
    let onNext: (Element)->Void
    init(_ onNext: @escaping (Element)->Void) {
        self.onNext = onNext
    }
}
