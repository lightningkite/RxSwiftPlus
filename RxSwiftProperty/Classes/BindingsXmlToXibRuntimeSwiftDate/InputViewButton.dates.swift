//Stub file made with Butterfly 2 (by Lightning Kite)
import XmlToXibRuntime
import RxSwift
import RxCocoa
import SwiftDate

//
//public extension SubjectType where Observer.Element == Element, Element == Optional<LocalDateTime> {
//    @discardableResult
//    func bind(_ view: InputViewButton, formatter: DateFormatter? = nil, nullText:String) -> Self {
//        self.map(read: { $0.map { $0.toDate() } }, write: { $0.map { LocalDateTime($0) } })
//            .bind(view, .dateAndTime, formatter: formatter, nullText: nullText)
//        return self
//    }
//}
//
//public extension SubjectType where Observer.Element == Element, Element == LocalDateTime {
//    @discardableResult
//    func bind(_ view: InputViewButton, formatter: DateFormatter? = nil) -> Self {
//        self.map(read: { $0.toDate() }, write: { LocalDateTime($0) })
//            .bind(view, .dateAndTime, formatter: formatter)
//        return self
//    }
//}
//
//public extension SubjectType where Observer.Element == Element, Element == Optional<LocalDate> {
//    @discardableResult
//    func bind(_ view: InputViewButton, formatter: DateFormatter? = nil, nullText:String) -> Self {
//        self.map(read: { $0.map { $0.toDate() } }, write: { $0.map { LocalDate($0) } })
//            .bind(view, .date, formatter: formatter, nullText: nullText)
//        return self
//    }
//}
//
//public extension SubjectType where Observer.Element == Element, Element == LocalDate {
//    @discardableResult
//    func bind(_ view: InputViewButton, formatter: DateFormatter? = nil) -> Self {
//        self.map(read: { $0.toDate() }, write: { LocalDate($0) })
//            .bind(view, .date, formatter: formatter)
//        return self
//    }
//}
//
//public extension SubjectType where Observer.Element == Element, Element == Optional<LocalTime> {
//    @discardableResult
//    func bind(_ view: InputViewButton, formatter: DateFormatter? = nil, nullText:String) -> Self {
//        self.map(read: { $0.map { $0.toDate() } }, write: { $0.map { LocalTime($0) } })
//            .bind(view, .date, formatter: formatter, nullText: nullText)
//        return self
//    }
//}
//
//public extension SubjectType where Observer.Element == Element, Element == LocalTime {
//    @discardableResult
//    func bind(_ view: InputViewButton, formatter: DateFormatter? = nil) -> Self {
//        self.map(read: { $0.toDate() }, write: { LocalTime($0) })
//            .bind(view, .date, formatter: formatter)
//        return self
//    }
//}

private func test() {
    let dca = DateComponents()
    let dcb = DateComponents()
    DateComponents(year: dca.year, month: dca.month, day: dca.day, hour: dcb.hour, minute: dcb.minute, second: dcb.second, nanosecond: dcb.nanosecond)
}
