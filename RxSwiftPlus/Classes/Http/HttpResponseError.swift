import Foundation

public enum HttpError: Error {
    case response(response: HttpResponse)
    case unknown
    case cancelled
}
