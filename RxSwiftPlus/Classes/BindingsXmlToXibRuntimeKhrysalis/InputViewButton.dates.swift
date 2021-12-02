//Stub file made with Butterfly 2 (by Lightning Kite)
import XmlToXibRuntime
import RxSwift
import RxCocoa
import KhrysalisRuntime

public extension HasValueSubject where Element == ZonedDateTime {
    func toSubjectLocalDate() -> HasValueSubject<LocalDate> {
        return self.mapWithExisting { $0.toLocalDate() } write: { $0.with($1) }
    }
    func toSubjectLocalTime() -> HasValueSubject<LocalTime> {
        return self.mapWithExisting { $0.toLocalTime() } write: { $0.with($1) }
    }
    func toSubjectLocalDateTime() -> HasValueSubject<LocalDateTime> {
        return self.mapWithExisting { $0.toLocalDateTime() } write: { $0.with($1) }
    }
    func toSubjectDate() -> HasValueSubject<Date> {
        return self.map { $0.toDate() } write: { $0.atZone() }
    }
}

public extension SubjectType where Observer.Element == Element, Element: OptionalConvertible, Element.Wrapped: HasDateComponents {
    @discardableResult
    func bind(_ view: UIButton, mode: UIDatePicker.Mode, formatter: DateFormatter? = nil, nullText:String) -> Self {
        self.map(read: { $0.asOptional.map { Calendar.current.date(from: $0.dateComponents)! } }, write: { $0.map { Element.Wrapped(from: $0) } as! Self.Element })
            .bind(view, .dateAndTime, formatter: formatter, nullText: nullText)
        return self
    }
}

public extension SubjectType where Observer.Element == Element, Element: HasDateComponents {
    @discardableResult
    func bind(_ view: UIButton, mode: UIDatePicker.Mode, formatter: DateFormatter? = nil) -> Self {
        self.map(read: { Calendar.current.date(from: $0.dateComponents)! }, write: { Element(from: $0) })
            .bind(view, mode, formatter: formatter)
        return self
    }
}

public extension SubjectType where Observer.Element == Element, Element == Optional<LocalDate> {
    @discardableResult
    func bind(_ view: UIButton, formatter: DateFormatter? = nil, nullText:String) -> Self { bind(view, mode: .date, formatter: formatter, nullText: nullText) }
}

public extension SubjectType where Observer.Element == Element, Element == LocalDate {
    @discardableResult
    func bind(_ view: UIButton, formatter: DateFormatter? = nil) -> Self { bind(view, mode: .date, formatter: formatter) }
}

public extension SubjectType where Observer.Element == Element, Element == Optional<LocalTime> {
    @discardableResult
    func bind(_ view: UIButton, formatter: DateFormatter? = nil, nullText:String) -> Self { bind(view, mode: .time, formatter: formatter, nullText: nullText) }
}

public extension SubjectType where Observer.Element == Element, Element == LocalTime {
    @discardableResult
    func bind(_ view: UIButton, formatter: DateFormatter? = nil) -> Self { bind(view, mode: .time, formatter: formatter) }
}

public extension SubjectType where Observer.Element == Element, Element == Optional<LocalDateTime> {
    @discardableResult
    func bind(_ view: UIButton, formatter: DateFormatter? = nil, nullText:String) -> Self { bind(view, mode: .dateAndTime, formatter: formatter, nullText: nullText) }
}

public extension SubjectType where Observer.Element == Element, Element == LocalDateTime {
    @discardableResult
    func bind(_ view: UIButton, formatter: DateFormatter? = nil) -> Self { bind(view, mode: .dateAndTime, formatter: formatter) }
}

public extension SubjectType where Observer.Element == Element, Element == Optional<ZonedDateTime> {
    @discardableResult
    func bind(_ view: UIButton, formatter: DateFormatter? = nil, nullText:String) -> Self { bind(view, mode: .dateAndTime, formatter: formatter, nullText: nullText) }
}

public extension SubjectType where Observer.Element == Element, Element == ZonedDateTime {
    @discardableResult
    func bind(_ view: UIButton, formatter: DateFormatter? = nil) -> Self { bind(view, mode: .dateAndTime, formatter: formatter) }
}

