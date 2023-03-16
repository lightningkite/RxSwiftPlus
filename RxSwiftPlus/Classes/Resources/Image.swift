// Generated by Khrysalis Swift converter - this file will be overwritten.
// File: Image.kt
// Package: com.lightningkite.butterfly
import Foundation
import RxSwift
import UIKit

public protocol Image { func load() -> Single<UIImage> }
public struct ImageLocalUrl: Image, Hashable {
    public var url: URL
    public init(_ url: URL) { self.url = url }
    public func load() -> Single<UIImage> {
        if let image = UIImage(fileURLWithPath: url) {
            return Single.just(image)
        } else {
            return Single.error(ImageLoadError.requestError)
        }
    }
}
public struct ImageUI: Image, Hashable {
    public var uiImage: UIImage
    public init(_ uiImage: UIImage) { self.uiImage = uiImage }
    public func load() -> Single<UIImage> { Single.just(uiImage) }
}
public struct ImageRaw: Image, Hashable {
    public var raw: Data
    public init(_ raw: Data) { self.raw = raw }
    public func load() -> Single<UIImage> { UIImage(data: raw).map { Single.just($0) } ?? Single.error(ImageLoadError.notImage) }
}
public struct ImageRemoteUrl: Image, Hashable {
    public var url: URL
    public init(_ url: URL) { self.url = url }
    public func load() -> Single<UIImage> { loadImage(uri: url) }
}
public struct ImageLayer: Image, Hashable {
    public static func == (lhs: ImageLayer, rhs: ImageLayer) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    public var identifier = arc4random()
    public var maker: () -> CALayer
    public init(_ maker: @escaping () -> CALayer) { self.maker = maker }
    public init(_ color: UIColor) { self.maker = {
        let newLayer = CALayer()
        newLayer.backgroundColor = color.cgColor
        return newLayer
    } }
    public func load() -> Single<UIImage> { maker().toImage().map { Single.just($0) } ?? Single.error(ImageLoadError.notImage) }
}

public enum ImageLoadError: Error {
    case requestError
    case notImage
}

private extension CALayer {
    func toImage() -> UIImage? {
        if CFGetTypeID(self.contents as CFTypeRef) == CGImage.typeID {
            return UIImage(cgImage: self.contents as! CGImage)
        } else {
            UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
            guard let ctx = UIGraphicsGetCurrentContext() else {
                print("WARNING!  NO CURRENT CONTEXT!")
                UIGraphicsEndImageContext()
                return nil
            }
            self.render(in: ctx)
            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            setNeedsDisplay()
            return img
        }
    }
}

private func loadImage(uri: URL, maxDimension: Int32 = 2048) -> Single<UIImage> {
    return Single.create { em in
        URLSession.shared.dataTask(with: uri, completionHandler: { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    if let img = UIImage(data: data) {
                        em.on(.success(img))
                    } else {
                        em.on(.failure(ImageLoadError.notImage))
                    }
                } else if let error = error {
                    em.on(.failure(error))
                } else {
                    em.on(.failure(ImageLoadError.requestError))
                }
            }
        }).resume()
    }
}

public extension UIImageView {
    private static let lastLoad = ExtensionProperty<UIImageView, UUID>()
    private static let loadAiv = ExtensionProperty<UIImageView, UIActivityIndicatorView>()
    func setImage(_ image: Image?) {
        self.image = nil
        let loadId = UUID()
        UIImageView.lastLoad.set(self, loadId)
        UIImageView.loadAiv.get(self)?.removeFromSuperview()
        if let image = image {
            switch image {
            case let image as ImageLocalUrl:
                setImageFromLocalUrl(url: image.url)
            case let image as ImageUI:
                self.image = image.uiImage
            case let image as ImageRemoteUrl:
                setImageFromRemoteUrl(url: image.url, loadId: loadId)
            default:
                let activityIndicatorView = UIActivityIndicatorView(style: .gray)
                activityIndicatorView.startAnimating()
                activityIndicatorView.center.x = self.frame.size.width / 2
                activityIndicatorView.center.y = self.frame.size.height / 2
                self.addSubview(activityIndicatorView)
                UIImageView.loadAiv.set(self, activityIndicatorView)
                weak var weakAIV = activityIndicatorView
                image.load()
                    .do(
                        onSuccess: {
                            if UIImageView.lastLoad.get(self) == loadId {
                                self.image = $0
                            }
                        },
                        onSubscribe: {  },
                        onDispose: {
                            if let it = weakAIV, weakAIV?.superview != nil {
                                it.removeFromSuperview()
                            }
                        }
                    )
                    .subscribe()
                    .disposed(by: self.removed)
            }
        }
    }
    func setImages(images: Array<Image>) {
        self.image = nil
        let loadId = UUID()
        UIImageView.lastLoad.set(self, loadId)
        UIImageView.loadAiv.get(self)?.removeFromSuperview()
        var currentLoadIndex = -1
        var currentIndex = 0
        for image in images {
            let index = currentIndex
            switch image {
            case let image as ImageLocalUrl:
                setImageFromLocalUrl(url: image.url)
            case let image as ImageUI:
                self.image = image.uiImage
            case let image as ImageRemoteUrl:
                setImageFromRemoteUrl(url: image.url, loadId: loadId)
            default:
                image.load()
                    .do(
                        onSuccess: {
                            if UIImageView.lastLoad.get(self) == loadId, index >= currentLoadIndex {
                                currentLoadIndex = index
                                self.image = $0
                            }
                        },
                        onSubscribe: {  },
                        onDispose: {
                        }
                    )
                    .subscribe()
                    .disposed(by: self.removed)
            }
            currentIndex += 1
        }
    }
    
    private func setImageFromLocalUrl(url: URL) {
        self.image = UIImage(fileURLWithPath: url)
    }
    
    private func setImageFromRemoteUrl(url: URL, loadId: UUID) {
        let activityIndicatorView = UIActivityIndicatorView(style: .gray)
        activityIndicatorView.startAnimating()
        activityIndicatorView.center.x = self.frame.size.width / 2
        activityIndicatorView.center.y = self.frame.size.height / 2
        self.addSubview(activityIndicatorView)
        UIImageView.loadAiv.set(self, activityIndicatorView)
        weak var weakAIV = activityIndicatorView
        let req = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
            else {
                DispatchQueue.main.async() {
                    if let it = weakAIV, weakAIV?.superview != nil {
                        it.removeFromSuperview()
                    }
                }
                return
            }
            if let response = response {
                URLCache.shared.storeCachedResponse(CachedURLResponse(response: response, data: data), for: req)
            }
            DispatchQueue.main.async() { [weak self] in
                guard let self else { return }
                if let it = weakAIV, weakAIV?.superview != nil {
                    it.removeFromSuperview()
                }
                if UIImageView.lastLoad.get(self) == loadId {
                    self.image = image
                }
            }
        }.resume()
    }
}


// load from path

extension UIImage {
    convenience init?(fileURLWithPath url: URL, scale: CGFloat = 1.0) {
        do {
            let data = try Data(contentsOf: url)
            self.init(data: data, scale: scale)
        } catch {
            print("-- Error: \(error)")
            return nil
        }
    }
}
