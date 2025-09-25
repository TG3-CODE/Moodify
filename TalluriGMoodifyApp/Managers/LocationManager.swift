//
//  LocationManager.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI
import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100
        checkLocationStatus()
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = Constants.locationErrorMessage
            print("❌ Location access denied or restricted")
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            print("⚠️ Unknown location authorization status")
        }
    }
    
    private func checkLocationStatus() {
        authorizationStatus = locationManager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startLocationUpdates()
        }
    }
    
    private func startLocationUpdates() {
        guard CLLocationManager.locationServicesEnabled() else {
            errorMessage = "Location services are disabled"
            return
        }
        
        locationManager.startUpdatingLocation()
        print("📍 Started location updates")
    }
    
    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        print("📍 Stopped location updates")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        if let currentLocation = location {
            let distance = newLocation.distance(from: currentLocation)
            guard distance > 50 else { return }
        }
        
        DispatchQueue.main.async {
            self.location = newLocation
            self.errorMessage = nil
        }
        
        print("📍 Location updated: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
            errorMessage = nil
        case .denied, .restricted:
            stopLocationUpdates()
            errorMessage = Constants.locationErrorMessage
        case .notDetermined:
            break
        @unknown default:
            break
        }
        
        print("📍 Location authorization changed: \(status.rawValue)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Failed to get location: \(error.localizedDescription)"
        }
        print("❌ Location error: \(error)")
    }
}
