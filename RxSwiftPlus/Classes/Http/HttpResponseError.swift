import Foundation

public struct HttpResponseException: Error {
    public let response: HttpResponse
}

public enum HttpError: Error {
    case unknown
    case cancelled
}
