//Package: com.lightningkite.butterfly.net
//Converted using Butterfly2

import Foundation
import RxSwift
import RxRelay



extension Single where Element == HttpResponse, Trait == SingleTrait {
    public func unsuccessfulAsError() -> Single<HttpResponse> {
        return self.map{ (it) in
            if it.isSuccessful {
                return it
            } else {
                throw HttpResponseException(response: it)
            }
        }
    }
}

extension PrimitiveSequence where Element == HttpResponse, Trait == SingleTrait {
    public func discard() -> Single<Void> {
        return self.flatMap { (it) in
            if it.isSuccessful {
                return it.discard()
            } else {
                return Single.error(HttpResponseException(response: it))
            }
        }
    }
    public func readJson<T: Codable>() -> Single<T> {
        return self.flatMap { (it) in
            if it.isSuccessful {
                return it.readJson()
            } else {
                return Single.error(HttpResponseException(response: it))
            }
        }
    }
    public func readJsonDebug<T: Codable>() -> Single<T> {
        return self.flatMap { (it) in
            if it.isSuccessful {
                return it.readJsonDebug()
            } else {
                return Single.error(HttpResponseException(response: it))
            }
        }
    }
    public func readJson<T: Codable>(serializer: T.Type) -> Single<T> {
        return readJson()
    }
    public func readJsonDebug<T: Codable>(serializer: T.Type) -> Single<T> {
        return readJson()
    }
    public func readJson<T: AltCodable>() -> Single<T> {
        return self.flatMap { (it) in
            if it.isSuccessful {
                return it.readJson()
            } else {
                return Single.error(HttpResponseException(response: it))
            }
        }
    }
    public func readJsonDebug<T: AltCodable>() -> Single<T> {
        return self.flatMap { (it) in
            if it.isSuccessful {
                return it.readJsonDebug()
            } else {
                return Single.error(HttpResponseException(response: it))
            }
        }
    }
    public func readJson<T: AltCodable>(serializer: T.Type) -> Single<T> {
        return readJson()
    }
    public func readJsonDebug<T: AltCodable>(serializer: T.Type) -> Single<T> {
        return readJson()
    }
    public func readText() -> Single<String> {
        return self.flatMap { (it) in
            if it.isSuccessful {
                return Single.just(String(data: it.data, encoding: .utf8)!)
            } else {
                return Single.error(HttpResponseException(response: it))
            }
        }
    }
    public func readData() -> Single<Data> {
        return self.flatMap { (it) in
            if it.isSuccessful {
                return Single.just(it.data)
            } else {
                return Single.error(HttpResponseException(response: it))
            }
        }
    }
}
