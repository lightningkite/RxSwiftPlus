import Foundation

public struct HttpResponseException: Error {
    public let response: HttpResponse
    public init(_ response: HttpResponse){
        self.response = response
    }
}

public enum HttpError: Error {
    case unknown
    case cancelled
    case invalidUrl
}
