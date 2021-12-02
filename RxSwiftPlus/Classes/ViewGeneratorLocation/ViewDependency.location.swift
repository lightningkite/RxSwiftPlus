//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import RxSwift
import RxCoreLocation
import CoreLocation

public enum LocationError: Error {
    case notFound, notAccepted
}

public extension ViewControllerAccess {
    func requestLocation(accuracyBetterThanMeters: Double = 10.0) -> Single<CLLocation> {
        let manager = CLLocationManager()
        var startStatus: CLAuthorizationStatus = .notDetermined
        if #available(iOS 14.0, *) {
            startStatus = manager.authorizationStatus
        } else {
            startStatus = CLLocationManager.authorizationStatus()
        }
        return manager.rx.didChangeAuthorization
            .asObservable()
            .map { $0.status }
            .startWith(startStatus)
            .map {
                if $0 == .notDetermined {
                    manager.requestWhenInUseAuthorization()
                    return false
                } else if $0 == .authorizedAlways || $0 == .authorizedWhenInUse {
                    return true
                } else {
                    throw LocationError.notAccepted
                }
            }
            .filter { $0 }
            .take(1)
            .asSingle()
            .flatMap { _ in
                manager.rx.location.take(1).asSingle()
            }
            .map { it in
                if let it = it { return it }
                else { throw LocationError.notFound }
            }
    }
}
