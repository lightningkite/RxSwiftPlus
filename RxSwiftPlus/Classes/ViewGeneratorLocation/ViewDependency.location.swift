//Stub file made with Butterfly 2 (by Lightning Kite)
import Foundation
import RxSwift
import RxCoreLocation
import CoreLocation

public enum LocationError: Error {
    case notFound
}

public extension ViewControllerAccess {
    func requestLocation(accuracyBetterThanMeters: Double = 10.0) -> Single<CLLocation> {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
        return manager.rx.location.asSingle().map { it in
            if let it = it { return it }
            else { throw LocationError.notFound }
        }
    }
}
