import RxSwift
import RxCocoa

enum ObservableExtensionError: Error {
    case NoItemReceived
}

public extension Observable {

    static func create(_ action: @escaping (ObservableEmitter<Element>) -> Void) -> RxSwift.Observable<Element> {
        return Observable.create { (it: AnyObserver<Element>) in
            let emitter = ObservableEmitter(basedOn: it)
            action(emitter)
            return emitter.disposable ?? Disposables.create { }
        }
    }

    static func just(_ items: Element...) -> RxSwift.Observable<Element> {
        return RxSwift.Observable<Element>.from(items)
    }
    
    func firstOrError() -> Single<Element> {
        return self.first().map { x in
            if let x = x {
                return x
            } else {
                throw ObservableExtensionError.NoItemReceived
            }
        }
    }
}

public extension Completable {
    func toObservable<T>() -> RxSwift.Observable<T> {
        return self.asObservable().map { _ in fatalError() }
    }
    func startWith<T: ObservableType>(_ value: T) -> RxSwift.Observable<T.Element> {
        return Observable.concat(
            value.asObservable(),
            self.toObservable()
        )
    }
}

public class ObservableEmitter<Element>: ObserverType {
    public func on(_ event: RxSwift.Event<Element>) {
        basedOn.on(event)
    }
    public func onNext(_ event: Element) {
        basedOn.on(RxSwift.Event<Element>.next(event))
    }
    public func onFailure(_ error: Error) {
        basedOn.on(RxSwift.Event<Element>.error(error))
    }
    public func onCompleted() {
        basedOn.on(RxSwift.Event<Element>.completed)
    }

    public var basedOn: AnyObserver<Element>
    public init(basedOn: AnyObserver<Element>) {
        self.basedOn = basedOn
    }

    public var disposable: Disposable? = nil
    public func setDisposable(_ disposable: Disposable?) {
        self.disposable = disposable
    }
    public var isDisposed: Bool = false
}

public extension PrimitiveSequenceType where Trait == SingleTrait {

    static func create(_ action: @escaping (SingleEmitter<Element>) -> Void) -> Single<Element> {
        return Single.create { (callback) -> Disposable in
            let emitter = SingleEmitter<Element>(basedOn: callback)
            action(emitter)
            return emitter.disposable ?? Disposables.create { }
        }
    }

    func cache() -> Single<Self.Element> {
        return self.primitiveSequence.asObservable().share(replay: 1, scope: .forever).asSingle()
    }
}

public class SingleEmitter<Element> {
    public func on(_ event: RxSwift.SingleEvent<Element>) {
        basedOn(event)
    }
    public func onSuccess(_ event: Element) {
        basedOn(.success(event))
    }
    public func onFailure(_ error: Error) {
        basedOn(.failure(error))
    }

    public var basedOn: (RxSwift.SingleEvent<Element>)->Void
    public init(basedOn: @escaping (RxSwift.SingleEvent<Element>)->Void) {
        self.basedOn = basedOn
    }

    public var disposable: Disposable? = nil
    public func setDisposable(_ disposable: Disposable?) {
        self.disposable = disposable
    }
    public var isDisposed: Bool = false
}

extension Observable {
    public func distinct<T: Hashable>(_ by: @escaping (Element)->T) -> RxSwift.Observable<Element> {
         var cache = Set<T>()
         return flatMap { element -> RxSwift.Observable<Element> in
             if cache.contains(by(element)) {
                 return RxSwift.Observable<Element>.empty()
             } else {
                 cache.insert(by(element))
                 return RxSwift.Observable<Element>.just(element)
             }
         }
     }
}

extension Observable where Element: Hashable {
    /**
     Suppress duplicate items emitted by an Observable
     - seealso: [distinct operator on reactivex.io](http://reactivex.io/documentation/operators/distinct.html)
     - returns: An observable sequence only containing the distinct contiguous elements, based on equality operator, from the source sequence.
     */
     public func distinct() -> RxSwift.Observable<Element> {
         var cache = Set<Element>()
         return flatMap { element -> RxSwift.Observable<Element> in
             if cache.contains(element) {
                 return RxSwift.Observable<Element>.empty()
             } else {
                 cache.insert(element)
                 return RxSwift.Observable<Element>.just(element)
             }
         }
     }
}

extension Observable where Element: Equatable {
    /**
     Suppress duplicate items emitted by an Observable
     - seealso: [distinct operator on reactivex.io](http://reactivex.io/documentation/operators/distinct.html)
     - returns: An observable sequence only containing the distinct contiguous elements, based on equality operator, from the source sequence.
     */
    public func distinct() -> RxSwift.Observable<Element> {
        var cache = [Element]()
        return flatMap { element -> RxSwift.Observable<Element> in
            if cache.contains(element) {
                return RxSwift.Observable<Element>.empty()
            } else {
                cache.append(element)
                return RxSwift.Observable<Element>.just(element)
            }
        }
    }
}

extension ObservableType {
    /**
    Merges the specified observable sequences into one observable sequence by using the selector function whenever any of the observable sequences produces an element.
    - seealso: [combineLatest operator on reactivex.io](http://reactivex.io/documentation/operators/combinelatest.html)
    - parameter resultSelector: Function to invoke whenever any of the sources produces an element.
    - returns: An observable sequence containing the result of combining elements of the sources using the specified result selector function.
    */
    public func combineLatest<O2: ObservableType, OUT>
        (_ observable: O2, _ function: @escaping (Element, O2.Element) throws -> OUT)
            -> RxSwift.Observable<OUT> {
                return RxSwift.Observable<OUT>.combineLatest(self, observable, resultSelector: function)
    }
}

public extension Observable {
    func mapNotNull<Destination>(transform: @escaping (Element) -> Destination?) -> RxSwift.Observable<Destination> {
        return self.flatMap { (it: Element) -> RxSwift.Observable<Destination> in
            if let result: Destination = transform(it) {
                return RxSwift.Observable<Destination>.just(result)
            } else {
                return RxSwift.Observable<Destination>.empty()
            }
        }
    }
}


public extension ConnectableObservableType {
    func autoConnect() -> RxSwift.Observable<Element> {
        var connected = false
        return self
            .do(onSubscribe: {
                if(!connected) {
                    connected = true
                    self.connect()
                }
            })
    }
}

extension SubjectType {
    func bind<Other: SubjectType>(_ other: Other) -> Disposable where Other.Observer.Element == Element, Other.Element == Observer.Element {
        var suppress = false
        return Disposables.create(
            self.subscribe(onNext: { it in
                if !suppress {
                    suppress = true
                    other.asObserver().onNext(it)
                    suppress = false
                }
            }),
            other.subscribe(onNext: { it in
                if !suppress {
                    suppress = true
                    self.asObserver().onNext(it)
                    suppress = false
                }
            })
        )
    }
}


// TODO: Find a way to remove the below
public extension Observable {

    func flatMapNR<Destination>(_ conversion: @escaping (Element)->RxSwift.Observable<Destination>) -> RxSwift.Observable<Destination> {
        return self.flatMap { (it: Element) -> RxSwift.Observable<Destination> in
            conversion(it)
        }
    }

    func switchMap<Destination>(_ conversion: @escaping (Element) -> RxSwift.Observable<Destination>) -> RxSwift.Observable<Destination> {
        return self.flatMapLatest { (it: Element) -> RxSwift.Observable<Destination> in
            conversion(it)
        }
    }

    func drop(_ count: Int) -> RxSwift.Observable<Element> {
        return self.skip(count)
    }

    func doOnComplete(_ action: @escaping () throws -> Void) -> RxSwift.Observable<Element> {
        return self.do(onCompleted: action)
    }
    func doOnError(_ action: @escaping (Error) throws -> Void) -> RxSwift.Observable<Element> {
        return self.do(onError: action)
    }
    func doOnNext(_ action: @escaping (Element) throws -> Void) -> RxSwift.Observable<Element> {
        return self.do(onNext: action)
    }
    func doOnTerminate(_ action: @escaping () -> Void) -> RxSwift.Observable<Element> {
        return self.do(onDispose: action)
    }

    func doOnSubscribe(_ action: @escaping (Disposable) -> Void) -> RxSwift.Observable<Element> {
        return self.do(onSubscribe: { action(placeholderDisposable) })
    }
    func doOnDispose(_ action: @escaping () -> Void) -> RxSwift.Observable<Element> {
        return self.do(onDispose: action)
    }
}

private let placeholderDisposable = DisposableLambda {}

public extension PrimitiveSequenceType where Trait == SingleTrait {
    func toObservable() -> RxSwift.Observable<Element> {
        return self.primitiveSequence.asObservable()
    }

    func doOnSubscribe(_ action: @escaping (Disposable) -> Void) -> Single<Element> {
        return self.do(onSubscribe: { action(placeholderDisposable) })
    }

    func doFinally(_ action: @escaping () -> Void) -> Single<Element> {
        return self.do(onSuccess: { _ in action() }, onError: { _ in action() })
    }

    func doOnSuccess(_ action: @escaping (Element) -> Void) -> Single<Element> {
        return self.do(onSuccess: action)
    }

    func doOnError(_ action: @escaping (Swift.Error) -> Void) -> Single<Element> {
        return self.do(onError: action)
    }
    
    func onErrorComplete(_ action: @escaping (Swift.Error) -> Bool) -> Maybe<Element> {
        return self.asMaybe().catch { error in
            if action(error) {
                return Maybe.empty()
            } else {
                return Maybe.error(error)
            }
        }
    }
}
public extension PrimitiveSequenceType where Trait == MaybeTrait {
    func toObservable() -> RxSwift.Observable<Element> {
        return self.primitiveSequence.asObservable()
    }
    func doOnSubscribe(_ action: @escaping (Disposable) -> Void) -> Maybe<Element> {
        return self.do(onSubscribe: { action(placeholderDisposable) })
    }

    func doFinally(_ action: @escaping () -> Void) -> Maybe<Element> {
        return self.do(onCompleted: action)
    }

    func doOnSuccess(_ action: @escaping (Element) -> Void) -> Maybe<Element> {
        return self.do(onNext: action)
    }

    func doOnError(_ action: @escaping (Swift.Error) -> Void) -> Maybe<Element> {
        return self.do(onError: action)
    }
}
public typealias Scheduler = RxSwift.SchedulerType

public enum Schedulers {

    public static func newThread() -> Scheduler {
        return ConcurrentDispatchQueueScheduler(qos: .background)
    }

    public static func io() -> Scheduler {
        return ConcurrentDispatchQueueScheduler(qos: .background)
    }

}

public enum AndroidSchedulers {

    public static func mainThread() -> Scheduler {
        return MainScheduler.instance
    }

}

public extension BehaviorSubject {
    static func create(value: Element) -> BehaviorSubject<Element> {
        return BehaviorSubject(value: value)
    }
}
public extension PublishSubject {
    static func create() -> PublishSubject<Element> {
        return PublishSubject()
    }
}

//extension Observable where Observable.Element: OptionalConvertible {
//    func filterNotNull() -> RxSwift.Observable<Element.Wrapped> {
//        self.filter { $0.asOptional != nil }.map { $0.asOptional! }
//    }
//}

public func xListCombineLatest<IN, OUT>(
    _ self: Array<RxSwift.Observable<IN>>,
    combine: @escaping (Array<IN>) -> OUT
) -> RxSwift.Observable<OUT> {
    return Observable.combineLatest(self, resultSelector: combine)
}
public func xListCombineLatest<IN>(
    _ self: Array<RxSwift.Observable<IN>>
) -> RxSwift.Observable<Array<IN>> {
    return Observable.combineLatest(self)
}
public extension Array where Element: ObservableType {
    func combineLatest<OUT>(combine: @escaping (Array<Element.Element>)->OUT) -> RxSwift.Observable<OUT> {
        return Observable.combineLatest(self, resultSelector: combine)
    }
    func combineLatest() -> RxSwift.Observable<Array<Element.Element>> {
        return Observable.combineLatest(self)
    }
}
