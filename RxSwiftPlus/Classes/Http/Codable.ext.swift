//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation


//--- Codable
private extension Date {
    func iso8601() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return formatter.string(from: self)
    }
}

private extension StringProtocol {
    subscript(i: Int) -> Character {
        return self[index(startIndex, offsetBy: Int(i))]
    }

    func getOrNull(index: Int) -> Character? {
        if index >= count { return nil }
        return self[index]
    }
    func indexOf(string: Self, startIndex: Int = 0, ignoreCase: Bool = true) -> Int {
        if string.isEmpty { return 0 }
        var options: String.CompareOptions = [.literal]
        if ignoreCase {
            options = [.literal, .caseInsensitive]
        }
        if let index = range(of: string, options: options, range: self.index(self.startIndex, offsetBy: startIndex)..<self.endIndex)?.lowerBound {
            return Int(distance(from: self.startIndex, to: index))
        } else {
            return -1
        }
    }
    func lastIndexOf(string: Self, startIndex: Int = 0, ignoreCase: Bool = true) -> Int {
        if string.isEmpty { return 0 }
        var options: String.CompareOptions = [.literal, .backwards]
        if ignoreCase {
            options = [.literal, .caseInsensitive, .backwards]
        }
        if let index = range(of: string, options: options, range: self.index(self.startIndex, offsetBy: startIndex)..<self.endIndex)?.lowerBound {
            return Int(distance(from: self.startIndex, to: index))
        } else {
            return -1
        }
    }
}

private extension String {
    func substring(_ startIndex: Int, _ endIndex: Int? = nil) -> String {
        if startIndex > self.count { return "" }
        if let endIndex = endIndex, startIndex >= endIndex { return "" }
        let s = self.index(self.startIndex, offsetBy: Int(startIndex))
        let e = self.index(self.startIndex, offsetBy: Int(endIndex ?? self.count))
        return String(self[s..<e])
    }
    func substring(startIndex: Int, endIndex: Int? = nil) -> String {
        return substring(startIndex, endIndex)
    }
    func substringBefore(delimiter: String, missingDelimiterValue: String? = nil) -> String {
        let index = self.indexOf(string: delimiter)
        if index != -1 {
            return substring(0, index)
        } else {
            return missingDelimiterValue ?? self
        }
    }

    func substringAfter(delimiter: String, missingDelimiterValue: String? = nil) -> String {
        let index = self.indexOf(string: delimiter)
        if index != -1 {
            return substring(index + delimiter.count)
        } else {
            return missingDelimiterValue ?? self
        }
    }

    func substringBeforeLast(delimiter: String, missingDelimiterValue: String? = nil) -> String {
        let index = self.lastIndexOf(string: delimiter)
        if index != -1 {
            return substring(0, index)
        } else {
            return missingDelimiterValue ?? self
        }
    }

    func substringAfterLast(delimiter: String, missingDelimiterValue: String? = nil) -> String {
        let index = self.lastIndexOf(string: delimiter)
        if index != -1 {
            return substring(index + delimiter.count)
        } else {
            return missingDelimiterValue ?? self
        }
    }
}

private extension Array {
    func getOrNull(index: Int) -> Element? {
        if index >= count { return nil }
        return self[index]
    }
}
private extension Character{
    func isDigit()->Bool{
        return self.isNumber
    }
}

private func dateFromIso(iso8601: String) -> Date? {
    //2020-12-17T22:35:25.727503
    let dateParts = iso8601.substringBefore(delimiter: "T").split(separator: "-")
    let timeParts = iso8601.substringAfter(delimiter: "T").split(separator: ":")
    let secondPart = (timeParts.getOrNull(index: 2)?.prefix(while: { $0.isDigit() || $0 == "." })).flatMap { Double($0) }
    let components = DateComponents(
        year: Int(dateParts[0]),
        month: Int(dateParts[1]),
        day: Int(dateParts[2]),
        hour: Int(timeParts[0]),
        minute: Int(timeParts[1]),
        second: secondPart.map { Int($0) },
        nanosecond: secondPart.map { Int($0.truncatingRemainder(dividingBy: 1.0) / 0.000000001) }
    )
    var cal = Calendar(identifier: .iso8601)
    cal.timeZone = TimeZone(secondsFromGMT: 0)!
    return cal.date(from: components)
}


public var encoder: JSONEncoder = {
    let e = JSONEncoder()
    e.dateEncodingStrategy = JSONEncoder.DateEncodingStrategy.custom { (date, encoder) in
        var container = encoder.singleValueContainer()
        try container.encode(date.iso8601())
    }
    return e
}()
public var decoder: JSONDecoder = {
    let d = JSONDecoder()
    d.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.custom { (decoder) in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        if let d = dateFromIso(iso8601: string) {
            return d
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")    }
    return d
}()

public extension KeyedDecodingContainer {
    
    func decodeDoubleIfPresent(forKey key: KeyedDecodingContainer<K>.Key) throws -> Double? {
        if let result = try? decodeIfPresent(Double.self, forKey: key) {
            return result
        } else if let stringOrNil = try? decodeIfPresent(String.self, forKey: key) {
            return Double(stringOrNil)
        } else {
            return nil
        }
    }
    func decodeDouble(forKey key: KeyedDecodingContainer<K>.Key) throws -> Double {
        if let result = try? decode(Double.self, forKey: key) {
            return result
        }
        let string = try decode(String.self, forKey: key)
        return Double(string) ?? 0
    }
    func decodeDoubleOrNull(forKey key: KeyedDecodingContainer<K>.Key) throws -> Double? {
        if let result = try? decode(Double?.self, forKey: key) {
            return result
        }
        if let string = try decode(String?.self, forKey: key) {
            return Double(string)
        }
        return nil
    }
}


//--- IsCodable
public typealias IsCodable = Codable

//--- JsonList
public typealias JsonList = NSArray

//--- JsonMap
public typealias JsonMap = NSDictionary

//--- IsCodable?.toJsonString()
public extension Encodable {
    func toJsonData(coder: JSONEncoder = encoder) -> Data {
        if let result = try? coder.encode(self) {
            return result
        }
        let result = try? coder.encode([self])
        let string = String(data: result!, encoding: .utf8)!
        return string.substring(1, string.count - 1).data(using: .utf8)!
    }
    func toJsonString(coder: JSONEncoder = encoder) -> String {
        let data = toJsonData(coder: coder)
        if let stringRep = String(data: data, encoding: .utf8) {
            return stringRep
        } else {
            return ""
        }
    }
    func toJsonString(serializer: Self.Type, coder: JSONEncoder = encoder) -> String {
        return toJsonString(coder: coder)
    }
}
public extension AltCodable {
    func toJsonData(coder: JSONEncoder = encoder) -> Data {
        if let result = try? coder.encode(self) {
            return result
        }
        let result = try? coder.encode([self])
        let string = String(data: result!, encoding: .utf8)!
        return string.substring(1, string.count - 1).data(using: .utf8)!
    }
    func toJsonString(coder: JSONEncoder = encoder) -> String {
        let data = toJsonData(coder: coder)
        if let stringRep = String(data: data, encoding: .utf8) {
            return stringRep
        } else {
            return ""
        }
    }
    func toJsonString(serializer: Self.Type, coder: JSONEncoder = encoder) -> String {
        return toJsonString(coder: coder)
    }
}

public extension Dictionary where Key == String, Value == Any {
    func toJsonData(coder: JSONEncoder = encoder) -> Data { PrimitiveCodableBox(self).toJsonData() }
    func toJsonString(coder: JSONEncoder = encoder) -> String { PrimitiveCodableBox(self).toJsonString() }
}
public extension Dictionary where Key == String, Value == Any? {
    func toJsonData(coder: JSONEncoder = encoder) -> Data { PrimitiveCodableBox(self).toJsonData() }
    func toJsonString(coder: JSONEncoder = encoder) -> String { PrimitiveCodableBox(self).toJsonString() }
}


//--- String.fromJsonString()
//--- String.fromJsonStringUntyped()
public extension String {
    func fromJsonStringUntyped() -> Any? {
        let obj = try? JSONSerialization.jsonObject(with: self.data(using: .utf8)!, options: .allowFragments)
        return obj
    }
    func fromJsonString<T>(serializer: T.Type) -> T? where T : Decodable {
        return fromJsonString()
    }
    func fromJsonString<T>() -> T? where T : Decodable {
        if let data = self.data(using: .utf8) {
            var err: Error? = nil
            do {
                let result = try decoder.decode(T.self, from: data)
                return result
            } catch {
                //Check error here
                err = error
            }
            let dataString = String(data: data, encoding: .utf8)!
            let fixedData = ("[" + dataString + "]").data(using: .utf8)!
            do {
                let result = try decoder.decode(Array<T>.self, from: fixedData)
                return result[0]
            } catch {
                err = error
            }
            if let err = err {
                print("Error decoding JSON into \(T.self): \(err)")
            }
            return nil
        }
        print("Error reading JSON into UTF8")
        return nil
    }
    func fromJsonString<T>(serializer: T.Type) -> T? where T : AltCodable {
        return fromJsonString()
    }
    func fromJsonString<T>() -> T? where T : AltCodable {
        if let data = self.data(using: .utf8) {
            var err: Error? = nil
            do {
                let result = try decoder.decode(T.self, from: data)
                return result
            } catch {
                //Check error here
                err = error
            }
            let dataString = String(data: data, encoding: .utf8)!
            let fixedData = ("[" + dataString + "]").data(using: .utf8)!
            do {
                let result = try decoder.decode(Array<T>.self, from: fixedData)
                return result[0]
            } catch {
                err = error
            }
            if let err = err {
                print("Error decoding JSON into \(T.self): \(err)")
            }
            return nil
        }
        print("Error reading JSON into UTF8")
        return nil
    }
}


public enum DecodingError2: Error { case wrongFormat }

public extension Decodable {
    static func fromJsonData(_ data: Data, coder: JSONDecoder = decoder) throws -> Self {
        var err: Error? = nil
        do {
            let result = try decoder.decode(Self.self, from: data)
            return result
        } catch {
            //Check error here
            err = error
        }
        let dataString = String(data: data, encoding: .utf8)!
        let fixedData = ("[" + dataString + "]").data(using: .utf8)!
        let result = try decoder.decode(Array<Self>.self, from: fixedData)
        return result[0]
    }
    static func fromJsonString(_ string: String, coder: JSONDecoder = decoder) throws -> Self {
        if let data = string.data(using: .utf8) {
            var err: Error? = nil
            do {
                let result = try decoder.decode(Self.self, from: data)
                return result
            } catch {
                //Check error here
                err = error
            }
            let dataString = String(data: data, encoding: .utf8)!
            let fixedData = ("[" + dataString + "]").data(using: .utf8)!
            let result = try decoder.decode(Array<Self>.self, from: fixedData)
            return result[0]
        }
        throw DecodingError2.wrongFormat
    }
}

public extension AltCodable {
    static func fromJsonData(_ data: Data, coder: JSONDecoder = decoder) throws -> Self {
        var err: Error? = nil
        do {
            let result = try decoder.decode(Self.self, from: data)
            return result
        } catch {
            //Check error here
            err = error
        }
        let dataString = String(data: data, encoding: .utf8)!
        let fixedData = ("[" + dataString + "]").data(using: .utf8)!
        let result = try decoder.decode(Array<Self>.self, from: fixedData)
        return result[0]
    }
    static func fromJsonString(_ string: String, coder: JSONDecoder = decoder) throws -> Self {
        if let data = string.data(using: .utf8) {
            var err: Error? = nil
            do {
                let result = try decoder.decode(Self.self, from: data)
                return result
            } catch {
                //Check error here
                err = error
            }
            let dataString = String(data: data, encoding: .utf8)!
            let fixedData = ("[" + dataString + "]").data(using: .utf8)!
            let result = try decoder.decode(Array<Self>.self, from: fixedData)
            return result[0]
        }
        throw DecodingError2.wrongFormat
    }
}

private struct PrimitiveCodableBox: Codable {
    var value: Any?
    init(_ value: Any?) {
        self.value = value
    }
    
    struct StringKey: CodingKey {
        var stringValue: String
        
        init(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int? = nil
        
        init?(intValue: Int) {
            self.stringValue = String(intValue)
        }
        
    }
    
    init(from decoder: Decoder) throws {
        do {
            let values = try decoder.singleValueContainer()
            do { self.init(try values.decode(Int8.self)) } catch {
            do { self.init(try values.decode(Int16.self)) } catch {
            do { self.init(try values.decode(Int32.self)) } catch {
            do { self.init(try values.decode(Int64.self)) } catch {
            do { self.init(try values.decode(UInt8.self)) } catch {
            do { self.init(try values.decode(UInt16.self)) } catch {
            do { self.init(try values.decode(UInt32.self)) } catch {
            do { self.init(try values.decode(UInt64.self)) } catch {
            do { self.init(try values.decode(Float.self)) } catch {
            do { self.init(try values.decode(Double.self)) } catch {
            do { self.init(try values.decode(Int.self)) } catch {
            do { self.init(try values.decode(Bool.self)) } catch {
            do { self.init(try values.decode(String.self)) } catch {
            do { self.init(try values.decode(Array<PrimitiveCodableBox>.self)) } catch {
            do { self.init(try values.decode(Dictionary<String, PrimitiveCodableBox>.self)) } catch {
            self.init(nil)
                }}}}}}}}}}}}}}}} catch {
           self.init(nil)
           }
    }
    
    
    func encode(to encoder: Encoder) throws {
        if let v = self.value as? Codable {
            try v.encode(to: encoder)
        } else if let v = self.value as? Dictionary<String, Any?> {
            var container = encoder.container(keyedBy: StringKey.self)
            for (key, value) in v {
                try container.encode(PrimitiveCodableBox(value), forKey: StringKey(stringValue: key))
            }
        } else {
            var svc = encoder.singleValueContainer()
            try svc.encodeNil()
        }
    }
}


public protocol AltCodable {
    static func encode(_ value: Self, to encoder: Encoder) throws
    static func decode(from decoder: Decoder) throws -> Self
}

extension Array: AltCodable where Element: AltCodable {
    public static func encode(_ value: Array<Element>, to encoder: Encoder) throws {
        try value.map { AltCodableWrapper(value: $0) }.encode(to: encoder)
    }
    
    public static func decode(from decoder: Decoder) throws -> Array<Element> {
        return try Array<AltCodableWrapper<Element>>(from: decoder).map { $0.value }
    }
}

extension Dictionary: AltCodable where Key: Codable, Value: AltCodable {
    public static func encode(_ value: Dictionary<Key, Value>, to encoder: Encoder) throws {
        try value.mapValues { AltCodableWrapper(value: $0) }.encode(to: encoder)
    }
    
    public static func decode(from decoder: Decoder) throws -> Dictionary<Key, Value> {
        return try Dictionary<Key, AltCodableWrapper<Value>>(from: decoder).mapValues { $0.value }
    }
}

fileprivate struct AltCodableWrapper<T: AltCodable>: Codable {
    var value: T
    init(value: T) { self.value = value }
    init(from decoder: Decoder) throws {
        self.value = try T.decode(from: decoder)
    }
    func encode(to encoder: Encoder) throws {
        try T.encode(self.value, to: encoder)
    }
}

public extension JSONDecoder {
    func decode<T: AltCodable>(_ type: T.Type, from: Data) throws -> T {
        return try self.decode(AltCodableWrapper<T>.self, from: from).value
    }
}

public extension JSONEncoder {
    func encode<T: AltCodable>(_ value: T) throws -> Data {
        return try self.encode(AltCodableWrapper(value: value))
    }
    func encodeAlt<T: AltCodable>(_ value: T) throws -> Data {
        return try self.encode(value)
    }
    func encodeCodable<T: Encodable>(_ value: T) throws -> Data {
        return try self.encode(value)
    }
}

public extension KeyedEncodingContainer {
    mutating func encode<T: AltCodable>(_ value: T, forKey key: KeyedEncodingContainer<K>.Key) throws {
        try self.encode(AltCodableWrapper(value: value), forKey: key)
    }
    mutating func encodeCodable<T: Encodable>(_ value: T, forKey key: KeyedEncodingContainer<K>.Key) throws {
        try self.encode(value, forKey: key)
    }
    mutating func encodeAlt<T: AltCodable>(_ value: T, forKey key: KeyedEncodingContainer<K>.Key) throws {
        try self.encode(value, forKey: key)
    }
}

public extension KeyedDecodingContainer {
    func decode<T: AltCodable>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T {
        return try self.decode(AltCodableWrapper<T>.self, forKey: key).value
    }
    func decodeIfPresent<T: AltCodable>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T? {
        return try self.decodeIfPresent(AltCodableWrapper<T>.self, forKey: key)?.value
    }
    func decodeAlt<T: AltCodable>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T {
        return try self.decode(T.self, forKey: key)
    }
    func decodeIfPresentAlt<T: AltCodable>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T? {
        return try self.decodeIfPresent(T.self, forKey: key)
    }
    func decodeCodable<T: Decodable>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T {
        return try self.decode(T.self, forKey: key)
    }
    func decodeIfPresentCodable<T: Decodable>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T? {
        return try self.decodeIfPresent(T.self, forKey: key)
    }
}

public extension UnkeyedEncodingContainer {
    mutating func encode<T: AltCodable>(_ value: T) throws {
        try self.encode(AltCodableWrapper(value: value))
    }
    mutating func encodeAlt<T: AltCodable>(_ value: T) throws {
        try self.encode(value)
    }
    mutating func encodeCodable<T: Encodable>(_ value: T) throws {
        try self.encode(value)
    }
}
public extension UnkeyedDecodingContainer {
    mutating func decode<T: AltCodable>(_ type: T.Type) throws -> T {
        return try self.decode(AltCodableWrapper<T>.self).value
    }
    mutating func decodeIfPresent<T: AltCodable>(_ type: T.Type) throws -> T? {
        return try self.decodeIfPresent(AltCodableWrapper<T>.self)?.value
    }
    mutating func decodeAlt<T: AltCodable>(_ type: T.Type) throws -> T {
        return try self.decode(T.self)
    }
    mutating func decodeIfPresentAlt<T: AltCodable>(_ type: T.Type) throws -> T? {
        return try self.decodeIfPresent(T.self)
    }
    mutating func decodeCodable<T: Decodable>(_ type: T.Type) throws -> T {
        return try self.decode(T.self)
    }
    mutating func decodeIfPresentCodable<T: Decodable>(_ type: T.Type) throws -> T? {
        return try self.decodeIfPresent(T.self)
    }
}
