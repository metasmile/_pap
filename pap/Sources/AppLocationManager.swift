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
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        return locationManager
    }()
    
    private var cachedLocations: [CLLocation]?
    var location: CLLocation? {
        return cachedLocations?.sorted { $0.horizontalAccuracy < $1.horizontalAccuracy }.first
    }
    private(set) var heading: CLHeading?
    
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
        if CLLocationManager.headingAvailable() {
            locationManager.headingFilter = 5
            locationManager.startUpdatingHeading()
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.delegate = nil
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        cachedLocations = nil
        heading = nil
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }
}
