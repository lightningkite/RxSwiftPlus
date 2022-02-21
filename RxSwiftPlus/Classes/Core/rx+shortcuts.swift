//
//  rx+shortcuts.swift
//  RxSwiftPlus
//
//  Created by Joseph Ivie on 10/19/21.
//

import RxSwift
import RxCocoa


public extension ObservableType where Element: Equatable {
    static func ==(self: Self, other: Observable<Element>) -> Observable<Bool> { Observable.combineLatest(self, other) { (a, b) in a == b } }
    static func !=(self: Self, other: Observable<Element>) -> Observable<Bool> { Observable.combineLatest(self, other) { (a, b) in a != b } }
}
public extension ObservableType where Element: Collection, Element.Element: Equatable {
    func contains(_ other: Observable<Element.Element>) -> Observable<Bool> {
        Observable.combineLatest(self, other) { (a, b) in a.contains { $0 == b } }
    }
}
public extension SubjectType where Element: Equatable, Observer.Element == Element {
    static func ==(self: Self, const: Element) -> Subject<Bool> { self.map { $0 == const }.withWrite { if $0 { self.asObserver().onNext(const) } } }
    static func !=(self: Self, const: Element) -> Subject<Bool> { self.map { $0 != const }.withWrite { if !$0 { self.asObserver().onNext(const) } } }
}

public protocol CollectionWithAdd: Collection {
    static func +(_ self: Self, _ other: Element) -> Self
    static func -(_ self: Self, _ other: Element) -> Self
}

extension Array: CollectionWithAdd where Element: Equatable {
    public static func + (self: Array<Element>, other: Element) -> Array<Element> { return self + [other] }
    public static func - (self: Array<Element>, other: Element) -> Array<Element> { return self.filter { $0 != other } }
}
extension Set: CollectionWithAdd {
    public static func + (self: Set<Element>, other: Element) -> Set<Element> { return self.union([other]) }
    public static func - (self: Set<Element>, other: Element) -> Set<Element> { return self.subtracting([other]) }
}

public extension HasValueSubject where Element: CollectionWithAdd, Observer.Element.Element: Equatable {
    func contains(_ const: Element.Element) -> Subject<Bool> {
        return map { $0.contains { $0 == const } }.withWrite {
            if $0 { self.asObserver().onNext(self.value + const) }
            else { self.asObserver().onNext(self.value - const) }
        }
    }
    func doesNotContain(_ const: Element.Element) -> Subject<Bool> {
        return map { $0.contains { $0 == const } }.withWrite {
            if $0 { self.asObserver().onNext(self.value - const) }
            else { self.asObserver().onNext(self.value + const) }
        }
    }
}

public protocol OptionalType {
    associatedtype Wrapped
    func asOptional() -> Optional<Wrapped>
    init(_ value: Wrapped)
    init(nilLiteral: ())
}
extension Optional: OptionalType {
    public func asOptional() -> Optional<Wrapped> {
        return self
    }
}


public extension HasValueSubject {
    func get<SubElement>(_ path: ReferenceWritableKeyPath<Element, SubElement>) -> ValueSubjectDelegate<SubElement> {
        return self.mapWithExisting(
            read: { $0[keyPath: path] },
            write: {
                $0[keyPath: path] = $1
                return $0
            }
        )
    }
}

public extension SubjectType where Element: OptionalType, Element.Wrapped: Equatable, Observer.Element == Element {
    func isEqualToOrNull(_ const: Element) -> Subject<Bool> {
        return map { $0.asOptional() == const.asOptional() }.withWrite { if $0 { self.asObserver().onNext(const) } }
    }
    func notEqualToOrNull(_ const: Element) -> Subject<Bool> {
        return map { $0.asOptional() != const.asOptional() }.withWrite { if !$0 { self.asObserver().onNext(const) } }
    }
}

public extension ObservableType where Element == Bool {
    static func &&(self: Self, other: Observable<Element>) -> Observable<Bool> { Observable.combineLatest(self, other) { (a, b) in a && b } }
    static func ||(self: Self, other: Observable<Element>) -> Observable<Bool> { Observable.combineLatest(self, other) { (a, b) in a || b } }
}


public extension SubjectType where Element == Bool, Observer.Element == Element {
    static prefix func !(self: Self) -> ControlProperty<Bool> { self.map(read: {!$0}, write: {!$0}) }
}

public extension SubjectType where Element == Int, Observer.Element == Element {
    func toSubjectString() -> ControlProperty<String> { mapMaybeWrite(read: {String($0)}, write: {Int($0)}) }
}

public extension SubjectType where Element : Numeric, Observer.Element == Element {
    static func + (self: Self, const: Element) -> ControlProperty<Element> { self.map(read: { $0 + const }, write: { $0 - const }) }
    static func - (self: Self, const: Element) -> ControlProperty<Element> { self.map(read: { $0 - const }, write: { $0 + const }) }
}

public extension SubjectType where Element : FixedWidthInteger, Observer.Element == Element {
    static func * (self: Self, const: Element) -> ControlProperty<Element> { self.map(read: { $0 * const }, write: { $0 / const }) }
    static func / (self: Self, const: Element) -> ControlProperty<Element> { self.map(read: { $0 / const }, write: { $0 * const }) }
}

public extension SubjectType where Element : FloatingPoint, Observer.Element == Element {
    static func * (self: Self, const: Element) -> ControlProperty<Element> { self.map(read: { $0 * const }, write: { $0 / const }) }
    static func / (self: Self, const: Element) -> ControlProperty<Element> { self.map(read: { $0 / const }, write: { $0 * const }) }
}

public extension SubjectType where Element == Float, Observer.Element == Element {
    func toSubjectString() -> ControlProperty<String> { mapMaybeWrite(read: {String($0)}, write: {Float($0)}) }
}

public extension SubjectType where Element == Double, Observer.Element == Element {
    func toSubjectString() -> ControlProperty<String> { mapMaybeWrite(read: {String($0)}, write: {Double($0)}) }
}

public extension SubjectType where Element == Optional<Int>, Observer.Element == Element {
    func toSubjectString() -> ControlProperty<String> { map(read: {$0.map{String($0)} ?? ""}, write: {Int($0)}) }
}

public extension SubjectType where Element == Optional<Float>, Observer.Element == Element {
    func toSubjectString() -> ControlProperty<String> { map(read: {$0.map{String($0)} ?? ""}, write: {Float($0)}) }
}

public extension SubjectType where Element == Optional<Double>, Observer.Element == Element {
    func toSubjectString() -> ControlProperty<String> { map(read: {$0.map{String($0)} ?? ""}, write: {Double($0)}) }
}

public extension SubjectType where Element == Int8, Observer.Element == Element {
    func toSubjectInt8() -> ControlProperty<Int8> { map(read: {Int8($0)}, write: {Element($0)}) }
    func toSubjectInt16() -> ControlProperty<Int16> { map(read: {Int16($0)}, write: {Element($0)}) }
    func toSubjectInt32() -> ControlProperty<Int32> { map(read: {Int32($0)}, write: {Element($0)}) }
    func toSubjectInt64() -> ControlProperty<Int64> { map(read: {Int64($0)}, write: {Element($0)}) }
    func toSubjectInt() -> ControlProperty<Int> { map(read: {Int($0)}, write: {Element($0)}) }
    func toSubjectFloat() -> ControlProperty<Float> { map(read: {Float($0)}, write: {Element($0)}) }
    func toSubjectDouble() -> ControlProperty<Double> { map(read: {Double($0)}, write: {Element($0)}) }
}
public extension SubjectType where Element == Int16, Observer.Element == Element {
    func toSubjectInt8() -> ControlProperty<Int8> { map(read: {Int8($0)}, write: {Element($0)}) }
    func toSubjectInt16() -> ControlProperty<Int16> { map(read: {Int16($0)}, write: {Element($0)}) }
    func toSubjectInt32() -> ControlProperty<Int32> { map(read: {Int32($0)}, write: {Element($0)}) }
    func toSubjectInt64() -> ControlProperty<Int64> { map(read: {Int64($0)}, write: {Element($0)}) }
    func toSubjectInt() -> ControlProperty<Int> { map(read: {Int($0)}, write: {Element($0)}) }
    func toSubjectFloat() -> ControlProperty<Float> { map(read: {Float($0)}, write: {Element($0)}) }
    func toSubjectDouble() -> ControlProperty<Double> { map(read: {Double($0)}, write: {Element($0)}) }
}
public extension SubjectType where Element == Int32, Observer.Element == Element {
    func toSubjectInt8() -> ControlProperty<Int8> { map(read: {Int8($0)}, write: {Element($0)}) }
    func toSubjectInt16() -> ControlProperty<Int16> { map(read: {Int16($0)}, write: {Element($0)}) }
    func toSubjectInt32() -> ControlProperty<Int32> { map(read: {Int32($0)}, write: {Element($0)}) }
    func toSubjectInt64() -> ControlProperty<Int64> { map(read: {Int64($0)}, write: {Element($0)}) }
    func toSubjectInt() -> ControlProperty<Int> { map(read: {Int($0)}, write: {Element($0)}) }
    func toSubjectFloat() -> ControlProperty<Float> { map(read: {Float($0)}, write: {Element($0)}) }
    func toSubjectDouble() -> ControlProperty<Double> { map(read: {Double($0)}, write: {Element($0)}) }
}
public extension SubjectType where Element == Int64, Observer.Element == Element {
    func toSubjectInt8() -> ControlProperty<Int8> { map(read: {Int8($0)}, write: {Element($0)}) }
    func toSubjectInt16() -> ControlProperty<Int16> { map(read: {Int16($0)}, write: {Element($0)}) }
    func toSubjectInt32() -> ControlProperty<Int32> { map(read: {Int32($0)}, write: {Element($0)}) }
    func toSubjectInt64() -> ControlProperty<Int64> { map(read: {Int64($0)}, write: {Element($0)}) }
    func toSubjectInt() -> ControlProperty<Int> { map(read: {Int($0)}, write: {Element($0)}) }
    func toSubjectFloat() -> ControlProperty<Float> { map(read: {Float($0)}, write: {Element($0)}) }
    func toSubjectDouble() -> ControlProperty<Double> { map(read: {Double($0)}, write: {Element($0)}) }
}
public extension SubjectType where Element == Int, Observer.Element == Element {
    func toSubjectInt8() -> ControlProperty<Int8> { map(read: {Int8($0)}, write: {Element($0)}) }
    func toSubjectInt16() -> ControlProperty<Int16> { map(read: {Int16($0)}, write: {Element($0)}) }
    func toSubjectInt32() -> ControlProperty<Int32> { map(read: {Int32($0)}, write: {Element($0)}) }
    func toSubjectInt64() -> ControlProperty<Int64> { map(read: {Int64($0)}, write: {Element($0)}) }
    func toSubjectInt() -> ControlProperty<Int> { map(read: {Int($0)}, write: {Element($0)}) }
    func toSubjectFloat() -> ControlProperty<Float> { map(read: {Float($0)}, write: {Element($0)}) }
    func toSubjectDouble() -> ControlProperty<Double> { map(read: {Double($0)}, write: {Element($0)}) }
}
public extension SubjectType where Element == Float, Observer.Element == Element {
    func toSubjectInt8() -> ControlProperty<Int8> { map(read: {Int8($0)}, write: {Element($0)}) }
    func toSubjectInt16() -> ControlProperty<Int16> { map(read: {Int16($0)}, write: {Element($0)}) }
    func toSubjectInt32() -> ControlProperty<Int32> { map(read: {Int32($0)}, write: {Element($0)}) }
    func toSubjectInt64() -> ControlProperty<Int64> { map(read: {Int64($0)}, write: {Element($0)}) }
    func toSubjectInt() -> ControlProperty<Int> { map(read: {Int($0)}, write: {Element($0)}) }
    func toSubjectFloat() -> ControlProperty<Float> { map(read: {Float($0)}, write: {Element($0)}) }
    func toSubjectDouble() -> ControlProperty<Double> { map(read: {Double($0)}, write: {Element($0)}) }
}
public extension SubjectType where Element == Double, Observer.Element == Element {
    func toSubjectInt8() -> ControlProperty<Int8> { map(read: {Int8($0)}, write: {Element($0)}) }
    func toSubjectInt16() -> ControlProperty<Int16> { map(read: {Int16($0)}, write: {Element($0)}) }
    func toSubjectInt32() -> ControlProperty<Int32> { map(read: {Int32($0)}, write: {Element($0)}) }
    func toSubjectInt64() -> ControlProperty<Int64> { map(read: {Int64($0)}, write: {Element($0)}) }
    func toSubjectInt() -> ControlProperty<Int> { map(read: {Int($0)}, write: {Element($0)}) }
    func toSubjectFloat() -> ControlProperty<Float> { map(read: {Float($0)}, write: {Element($0)}) }
    func toSubjectDouble() -> ControlProperty<Double> { map(read: {Double($0)}, write: {Element($0)}) }
}

public extension ObservableType where Element: OptionalType {
    func flatMapLatestNotNull<Source: ObservableConvertibleType>(_ selector: @escaping (Element.Wrapped) -> Source)
        -> Observable<Source.Element?> {
        return flatMapLatest { (wrapped: Element) -> Observable<Source.Element?> in
            if let x = wrapped.asOptional() {
                return selector(x).asObservable().map { Optional($0) }
            } else {
                return Observable.just(nil)
            }
        }
    }
    func flatMapLatestNotNull<Source: ObservableConvertibleType>(_ selector: @escaping (Element.Wrapped) -> Source?)
        -> Observable<Source.Element?> {
        return flatMapLatest { (wrapped: Element) -> Observable<Source.Element?> in
            if let x = wrapped.asOptional() {
                return selector(x)?.asObservable().map { Optional($0) } ?? Observable.just(nil)
            } else {
                return Observable.just(nil)
            }
        }
    }
    func flatMapNotNull<Source: ObservableConvertibleType>(_ selector: @escaping (Element.Wrapped) -> Source)
        -> Observable<Source.Element?> {
        return flatMap { (wrapped: Element) -> Observable<Source.Element?> in
            if let x = wrapped.asOptional() {
                return selector(x).asObservable().map { Optional($0) }
            } else {
                return Observable.just(nil)
            }
        }
    }
    func flatMapNotNull<Source: ObservableConvertibleType>(_ selector: @escaping (Element.Wrapped) -> Source?)
        -> Observable<Source.Element?> {
        return flatMap { (wrapped: Element) -> Observable<Source.Element?> in
            if let x = wrapped.asOptional() {
                return selector(x)?.asObservable().map { Optional($0) } ?? Observable.just(nil)
            } else {
                return Observable.just(nil)
            }
        }
    }
    func flatMapLatestNotNull2<Source: ObservableConvertibleType>(_ selector: @escaping (Element.Wrapped) -> Source)
    -> Observable<Source.Element.Wrapped?> where Source.Element: OptionalType {
        return flatMapLatest { (wrapped: Element) -> Observable<Source.Element.Wrapped?> in
            if let x = wrapped.asOptional() {
                return selector(x).asObservable().map { $0.asOptional() }
            } else {
                return Observable.just(nil)
            }
        }
    }
    func flatMapLatestNotNull2<Source: ObservableConvertibleType>(_ selector: @escaping (Element.Wrapped) -> Source?)
        -> Observable<Source.Element.Wrapped?> where Source.Element: OptionalType {
        return flatMapLatest { (wrapped: Element) -> Observable<Source.Element.Wrapped?> in
            if let x = wrapped.asOptional() {
                return selector(x)?.asObservable().map { $0.asOptional() } ?? Observable.just(nil)
            } else {
                return Observable.just(nil)
            }
        }
    }
    func flatMapNotNull2<Source: ObservableConvertibleType>(_ selector: @escaping (Element.Wrapped) -> Source)
        -> Observable<Source.Element.Wrapped?> where Source.Element: OptionalType {
        return flatMap { (wrapped: Element) -> Observable<Source.Element.Wrapped?> in
            if let x = wrapped.asOptional() {
                return selector(x).asObservable().map { $0.asOptional() }
            } else {
                return Observable.just(nil)
            }
        }
    }
    func flatMapNotNull2<Source: ObservableConvertibleType>(_ selector: @escaping (Element.Wrapped) -> Source?)
        -> Observable<Source.Element.Wrapped?> where Source.Element: OptionalType {
        return flatMap { (wrapped: Element) -> Observable<Source.Element.Wrapped?> in
            if let x = wrapped.asOptional() {
                return selector(x)?.asObservable().map { $0.asOptional() } ?? Observable.just(nil)
            } else {
                return Observable.just(nil)
            }
        }
    }
}

public extension PrimitiveSequenceType where Trait == SingleTrait {
    func working<Obs: ObserverType>(_ consumer: Obs) -> Single<Element> where Obs.Element == Bool {
        self.do(onSubscribe: { consumer.onNext(true) }, onDispose: { consumer.onNext(false) })
    }
}
public extension PrimitiveSequenceType where Trait == MaybeTrait {
    func working<Obs: ObserverType>(_ consumer: Obs) -> Maybe<Element> where Obs.Element == Bool {
        self.do(onSubscribe: { consumer.onNext(true) }, onDispose: { consumer.onNext(false) })
    }
}

public extension ObservableType where Element: OptionalType {
    func notNull() -> Observable<Element.Wrapped> {
        return self.compactMap { $0.asOptional() }
    }
}
