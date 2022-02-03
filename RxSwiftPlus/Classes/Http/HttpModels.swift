// Generated by Khrysalis Swift converter - this file will be overwritten.
// File: net/HttpModels.kt
// Package: com.lightningkite.butterfly.net
import Foundation

public enum HttpPhase: String, CaseIterable {
    case Connect
    case Write
    case Waiting
    case Read
    case Done
    
    public init(from decoder: Decoder) throws {
        self = try Self(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .Connect
    }
}

public class HttpProgress<T> {
    public var phase: HttpPhase
    public var ratio: Float
    public var response: T?
    public init(phase: HttpPhase, ratio: Float = 0.5, response: T? = nil) {
        self.phase = phase
        self.ratio = ratio
        self.response = response
        //Necessary properties should be initialized now
    }
    
    public var approximate: Float {
        get {
            switch self.phase {
                case HttpPhase.Connect:
                return 0
                case HttpPhase.Write:
                return 0.15 + 0.5 * self.ratio
                case HttpPhase.Waiting:
                return 0.65
                case HttpPhase.Read:
                return 0.7 + 0.3 * self.ratio
                case HttpPhase.Done:
                return 1
            }
        }
    }
}

public struct HttpOptions: Equatable, Hashable {
    public var callTimeout: Int?
    public var writeTimeout: Int?
    public var readTimeout: Int?
    public var connectTimeout: Int?
    public var cacheMode: HttpCacheMode
    public init(callTimeout: Int? = nil, writeTimeout: Int? = 10000, readTimeout: Int? = 10000, connectTimeout: Int? = 10000, cacheMode: HttpCacheMode = HttpCacheMode.Default) {
        self.callTimeout = callTimeout
        self.writeTimeout = writeTimeout
        self.readTimeout = readTimeout
        self.connectTimeout = connectTimeout
        self.cacheMode = cacheMode
        //Necessary properties should be initialized now
    }
}

public enum HttpCacheMode: String, CaseIterable {
    case Default
    case NoStore
    case Reload
    case NoCache
    case ForceCache
    case OnlyIfCached
    
    public init(from decoder: Decoder) throws {
        self = try Self(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .Default
    }
}

