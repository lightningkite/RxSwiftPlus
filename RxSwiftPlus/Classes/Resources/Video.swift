// Generated by Khrysalis Swift converter - this file will be overwritten.
// File: Video.kt
// Package: com.lightningkite.butterfly
import UIKit
import RxSwift
import AVKit

public enum VideoLoadError: Error {
    case requestError
    case notImage
}

public enum Video {
    case localUrl(_ url: URL)
    case remoteUrl(_ url: URL)
    
    public func thumbnail(timeMs: Int64 = 2000, size: CGPoint? = nil) -> Single<Image> {
        return Single.create { (em: SingleEmitter<Image>) in
            let vid: AVAsset
            switch self {
            case .localUrl(url: let url):
                vid = AVAsset(url: url)
            case .remoteUrl(url: let url):
                vid = AVAsset(url: url)
            }
            let imageGenerator = AVAssetImageGenerator(asset: vid)
            imageGenerator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: Double(timeMs) / 1000.0, preferredTimescale: 600)
            let times = [NSValue(time: time)]
            imageGenerator.generateCGImagesAsynchronously(forTimes: times, completionHandler: { _, image, _, _, _ in
                if let image = image {
                    em.on(.success(Image.ui(UIImage(cgImage: image))))
                } else {
                    em.on(.failure(VideoLoadError.requestError))
                }
            })
        }.subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background)).observe(on: MainScheduler.instance)
    }
}

public extension ContainerView {
    func setVideo(_ video: Video, playWhenReady: Bool = false){
        if let controller = self.contained as? AVPlayerViewController {
            controller.setVideo(video, playWhenReady: playWhenReady)
        } else {
            let controller = AVPlayerViewController()
            self.contained = controller
            controller.setVideo(video, playWhenReady: playWhenReady)
        }
    }
}
public extension AVPlayerViewController {
    func setVideo(_ video: Video, playWhenReady: Bool = false){
        var player: AVPlayer;
        switch video {
        case .localUrl(url: let url):
            player = AVPlayer(url: url)
        case .remoteUrl(url: let url):
            player = AVPlayer(url: url)
        }
        self.player = player
        if playWhenReady {
            player.play()
        }
    }
}
