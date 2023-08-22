import RxSwift
import RxRelay
import Starscream

public protocol WebSocketInterface: Disposable {
    var write: AnyObserver<WebSocketFrame> { get }
    var read: Observable<WebSocketFrame> { get }
    var ownConnection: Observable<ConnectedWebSocket> { get }
}

public final class ConnectedWebSocket: WebSocketInterface, WebSocketDelegate, Disposable, ObserverType {
    
    public typealias Element = WebSocketFrame
    public var write: AnyObserver<WebSocketFrame> { return AnyObserver(self) }
    
    public var ownConnection: Observable<ConnectedWebSocket> {
        return _ownConnection
    }
    
    public func on(_ event: Event<WebSocketFrame>) {
        switch event {
        case let .next(value):
            if let text = value.text {
                underlyingSocket?.write(string: text, completion: nil)
            }
            if let binary = value.binary {
                underlyingSocket?.write(data: binary, completion: nil)
            }
        case .error(_):
            underlyingSocket?.disconnect(closeCode: 1011)
        case .completed:
            underlyingSocket?.disconnect(closeCode: 1000)
        }
    }
    

    private let _ownConnection = PublishSubject<ConnectedWebSocket>()
    var underlyingSocket: WebSocket?
    var url: String
    private let _read: PublishSubject<WebSocketFrame> = PublishSubject()
    public var read: Observable<WebSocketFrame> { return _read }

    init(url: String) {
        self.url = url
    }

    public func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
        switch event {
        case .binary(let data):
//            print("Socket to \(url) got binary message of length '\(data.count)'")
            _read.onNext(WebSocketFrame(binary: data))
            break
        case .text(let string):
//            print("Socket to \(url) got message '\(string)'")
            _read.onNext(WebSocketFrame(text: string))
            break
        case .connected(let headers):
//            print("Socket to \(url) opened successfully with \(headers).")
            _ownConnection.onNext(self)
            break
        case .disconnected(let reason, let code):
//            print("Socket to \(url) disconnecting with code \(code). Reason: \(reason)")
            _ownConnection.onCompleted()
            _read.onCompleted()
            break
        case .error(let error):
//            print("Socket to \(url) failed with error \(String(describing: error))")
            _ownConnection.onError(error ?? HttpError.unknown)
            _read.onError(error ?? HttpError.unknown)
            break
        case .cancelled:
//            print("Socket to \(url) cancelled")
            _ownConnection.onError(HttpError.cancelled)
            _read.onCompleted()
            break
        default:
            break
        }
    }
    
    public func dispose() {
//        print("Socket to \(url) was disposed, closing with OK code.")
        underlyingSocket?.disconnect(closeCode: 1000)
        _ownConnection.onCompleted()
        _read.onCompleted()
    }

}

