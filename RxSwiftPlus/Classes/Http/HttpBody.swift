import Foundation
import RxSwift

//--- HttpBody
public struct HttpBody {
    public let mediaType: String?
    public let data: Data
    public init(mediaType: String, data: Data){
        self.mediaType = mediaType
        self.data = data
    }
}

//--- IsCodable.toJsonHttpBody()
public extension Encodable {
    func toJsonRequestBody() -> HttpBody {
        return HttpBody(mediaType: MediaTypes.JSON, data: self.toJsonData())
    }
}
public extension AltCodable {
    func toJsonRequestBody() -> HttpBody {
        return HttpBody(mediaType: MediaTypes.JSON, data: self.toJsonData())
    }
}

public extension Dictionary where Key == String, Value == Any {
    func toJsonRequestBody() -> HttpBody {
        return HttpBody(mediaType: MediaTypes.JSON, data: self.toJsonData())
    }
}
public extension Dictionary where Key == String, Value == Any? {
    func toJsonRequestBody() -> HttpBody {
        return HttpBody(mediaType: MediaTypes.JSON, data: self.toJsonData())
    }
}

//--- Data.toRequestBody(MediaType)
public extension Data {
    func toRequestBody(_ mediaType: MediaType) -> HttpBody {
        return HttpBody(mediaType: mediaType, data: self)
    }
    func toRequestBody(mediaType: MediaType) -> HttpBody {
        return toRequestBody(mediaType)
    }
}

//--- String.toRequestBody(MediaType)
public extension String {
    func toRequestBody(_ mediaType: MediaType) -> HttpBody {
        return HttpBody(mediaType: mediaType, data: self.data(using: .utf8)!)
    }
    func toRequestBody(mediaType: MediaType) -> HttpBody {
        return toRequestBody(mediaType)
    }
}

//--- Uri.toRequestBody()
public extension URL {
    func toRequestBody() -> Single<HttpBody> {
        return Single.create { (em) in
            URLSession.shared.dataTask(with: self, completionHandler: { data, response, error in
                DispatchQueue.main.async {
                    if let response = response as? HTTPURLResponse {
                        if response.statusCode / 100 == 2, let data = data {
                            let mediaType = response.mimeType ?? "application/octet-stream"
                            em.onSuccess(HttpBody(mediaType: mediaType, data: data))
                        } else if let error = error {
                            em.onFailure(error)
                        } else {
                            em.onFailure(HttpResponseException(HttpResponse(response: response, data: data ?? Data())))
                        }
                    } else if let response = response {
                        if let data = data {
                            let mediaType = response.mimeType ?? "application/octet-stream"
                            em.onSuccess(HttpBody(mediaType: mediaType, data: data))
                        } else if let error = error {
                            em.onFailure(error)
                        } else {
                            em.onFailure(HttpError.unknown)
                        }
                    } else {
                        em.onFailure(HttpError.unknown)
                    }
                }
            }).resume()
        }
    }
}

//--- Image.toRequestBody
fileprivate extension UIImage {
    func resize(maxDimension: Int) -> UIImage? {
        var newSize = CGSize.zero
        if self.size.width > self.size.height {
            newSize.width = CGFloat(maxDimension)
            newSize.height = CGFloat(maxDimension) * (self.size.height / self.size.width)
        } else {
            newSize.height = CGFloat(maxDimension)
            newSize.width = CGFloat(maxDimension) * (self.size.width / self.size.height)
        }
        UIGraphicsBeginImageContextWithOptions(
            /* size: */ newSize,
            /* opaque: */ false,
            /* scale: */ 1
        )
        defer { UIGraphicsEndImageContext() }

        self.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func toRequestBody(maxDimension: Int = 2048, maxBytes:Int = 10_000_000, format:MediaType) -> Single<HttpBody> {
        return Single.create { (em: SingleEmitter<HttpBody>) in
            
            var quality:CGFloat = 1.0
            var data:Data?
            var realDimension = min(max(self.size.height, self.size.width), CGFloat(maxDimension))
            var scaledBmp = self.resize(maxDimension: Int(realDimension))
            repeat{
                switch(format){
                case MediaTypes.JPEG:
                    data = scaledBmp?.jpegData(compressionQuality: quality)
                    quality -= 0.05
                default:
                    scaledBmp = self.resize(maxDimension: Int(realDimension))
                    data = scaledBmp?.pngData()
                    realDimension *= 0.95
                }
            }while (data == nil || data?.count ?? Int.max > maxBytes)

            if let rep = data {
                em.onSuccess(HttpBody(mediaType: format == MediaTypes.JPEG ? format : MediaTypes.PNG, data: rep))
            } else {
                em.onFailure(ImageLoadError.notImage)
            }
        }
    }
}

fileprivate func stringToMediaType(_ value:String) -> MediaType{
    switch(value){
    case "png":
        return MediaTypes.PNG
    case "jpg", "jpeg":
        return MediaTypes.JPEG
    case "webp":
        return MediaTypes.WEBP
    default:
        return MediaTypes.PNG
    }
}

public extension Image {
    func toRequestBody(maxDimension: Int = 2048, maxBytes:Int = 10_000_000) -> Single<HttpBody> {
        var type: MediaType
        switch(self){
        case let self as ImageLocalUrl:
            type = stringToMediaType(self.url.lastPathComponent.substringAfterLast(delimiter: "."))
        case let self as ImageRemoteUrl:
            type = stringToMediaType(self.url.lastPathComponent.substringAfterLast(delimiter: "."))
        default:
            type = MediaTypes.PNG
        }
        
        return self.load().flatMap { bmp in
            return bmp.toRequestBody(maxDimension: maxDimension, maxBytes: maxBytes, format: type)
        }
    }
    func toHttpBodyRaw() -> Single<HttpBody> {
        
        switch(self){
        case let self as ImageLocalUrl:
            return self.url.toRequestBody()
        case let self as ImageRaw:
            return Single.just(HttpBody(mediaType: MediaTypes.IMAGE_ANY, data: self.raw))
        case let self as ImageRemoteUrl:
            return self.url.toRequestBody()
        default:
            return self.load().map { uiImage in
                if let rep = uiImage.pngData() {
                    return HttpBody(mediaType: MediaTypes.PNG, data: rep)
                } else {
                    throw ImageLoadError.notImage
                }
            }
        }
    }
}


//--- HttpBodyPart
public enum MultipartBody {
    public enum Part {
        case file(name: String, filename: String?, body: HttpBody)
        case value(name: String, value: String)
    }
    
    public static func from(_ parts: Part...) -> HttpBody {
        return from(parts: parts)
    }
    
    public static func from(parts: Array<Part>) -> HttpBody {
        var body = Data()
        #if DEBUG
        var stringBody = ""
        #endif
        func emitText(_ string: String){
            #if DEBUG
            stringBody += string
            #endif
            body.append(string.data(using: .utf8)!)
        }
        let boundary = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        for part in parts {
            emitText("\r\n--" + boundary + "\r\n")
            switch part {
            case .file(let name, let filename, let subBody):
                emitText("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename ?? "file")\"\r\n")
                emitText("Content-Type: \(subBody.mediaType ?? "*/*")\r\n\r\n")
                body.append(subBody.data)
                #if DEBUG
                stringBody += "<binary data>"
                #endif
            case .value(let name, let value):
                emitText("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
                emitText(value)
            }
        }
        emitText("\r\n--" + boundary + "--\r\n")
        #if DEBUG
        #endif
        return HttpBody(mediaType: "multipart/form-data; boundary=\(boundary)", data: body)
    }
}
