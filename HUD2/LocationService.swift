//
//  LocationService.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//

import Foundation
import CoreLocation
import Combine

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var speedMS: Double = 0
    @Published var altitudeMSL: Double = 0

    @Published var lastCoordinate: CLLocationCoordinate2D?
    @Published var horizontalAccuracy: CLLocationDistance?
    @Published var track: [CLLocationCoordinate2D] = []

    override init() {
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 2  // 2 米记录一次轨迹
        manager.delegate = self
    }

    func start() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        // 速度（m/s），低速抖动清零
        speedMS = max(0, loc.speed.isFinite ? loc.speed : 0)
        altitudeMSL = loc.altitude
        lastCoordinate = loc.coordinate
        horizontalAccuracy = loc.horizontalAccuracy.isFinite ? loc.horizontalAccuracy : nil

        if track.last.map({ distance(from: $0, to: loc.coordinate) > 1.5 }) ?? true {
            track.append(loc.coordinate)
            if track.count > 2000 { track.removeFirst(track.count - 2000) } // 防爆
        }
    }

    private func distance(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> CLLocationDistance {
        let la = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let lb = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return la.distance(from: lb)
    }
}

