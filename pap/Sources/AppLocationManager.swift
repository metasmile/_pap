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
    
    private var locationManager: CLLocationManager?
    private lazy var locationQueue = DispatchQueue.main
    
    private var cachedLocations: [CLLocation]?
    var location: CLLocation? {
        return cachedLocations?.sorted { $0.horizontalAccuracy < $1.horizontalAccuracy }.first
    }
    private(set) var heading: CLHeading?
    
    override init() {
        super.init()
        
        locationQueue.async {
            self.locationManager = CLLocationManager()
            self.locationManager?.distanceFilter = kCLDistanceFilterNone
            self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        }
    }
    
    var disabledLocation: Bool {
        return CLLocationManager.authorizationStatus() == .denied || CLLocationManager.authorizationStatus() == .restricted
    }
    
    var updatingLocation: Bool {
        return locationManager?.delegate != nil
    }
    
    func startUpdatingLocation(completion: (() -> Void)? = nil) {
        locationQueue.async {
            if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
                self.locationManager?.requestWhenInUseAuthorization()
            }
            self.locationManager?.delegate = self
            self.locationManager?.startUpdatingLocation()
            if CLLocationManager.headingAvailable() {
                self.locationManager?.headingFilter = 5
                self.locationManager?.startUpdatingHeading()
            }
            completion?()
        }
    }
    
    func stopUpdatingLocation(completion: (() -> Void)? = nil) {
        locationQueue.async {
            self.locationManager?.delegate = nil
            self.locationManager?.stopUpdatingLocation()
            self.locationManager?.stopUpdatingHeading()
            self.cachedLocations = nil
            self.heading = nil
            
            completion?()
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationQueue.async {
            self.cachedLocations = locations
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationQueue.async {
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                self.locationManager?.startUpdatingLocation()
            } else {
                self.locationManager?.stopUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        locationQueue.async {
            self.heading = newHeading
        }
    }
}
