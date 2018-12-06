//
//  AppLocationManager.swift
//  pap
//
//  Created by HYOJIN MO on 07/12/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import UIKit
import CoreLocation

class LocationManager: NSObject {
    static var shared: LocationManager = LocationManager()
    
    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
//        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.headingFilter = 5.0
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        return locationManager
    }()
    
    private var cachedLocations: [CLLocation]?
    var location: CLLocation? {
        return cachedLocations?.sorted { $0.horizontalAccuracy < $1.horizontalAccuracy }.first
    }
    
    override init() {
        super.init()
    }
    
    var disabledLocation: Bool {
        return CLLocationManager.authorizationStatus() == .denied || CLLocationManager.authorizationStatus() == .restricted
    }
    
    var updatingLocation: Bool {
        return locationManager.delegate != nil
    }
    
    func startUpdatingLocation() {
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.delegate = nil
        locationManager.stopUpdatingLocation()
        cachedLocations = nil
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        cachedLocations = locations
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.stopUpdatingLocation()
        }
    }
}
