//
//  ViewControllerAccess.geocode.swift
//  RxSwiftPlus
//
//  Created by Joseph Ivie on 11/15/21.
//

import RxSwift
import CoreLocation

public extension ViewControllerAccess {
    func geocode(address:String, maxResults:Int = 1) -> Single<Array<CLPlacemark>> {
        if address.isEmpty {
            return Single.just(Array())
        }
        return Single.create ({(emitter: SingleEmitter<Array<CLPlacemark>>)in
            CLGeocoder().geocodeAddressString(address) { marks, error in
                emitter.onSuccess(marks ?? [])
            }
        })
    }
    
    func geocode(latitude: Double, longitude: Double) -> Single<Array<CLPlacemark>> {
        return Single.create ({(emitter: SingleEmitter<Array<CLPlacemark>>)in
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)){ marks, error in
                emitter.onSuccess(marks ?? [])
            }
        })
    }
}
