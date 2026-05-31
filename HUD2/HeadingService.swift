//
//  HeadingService.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//

import Foundation
import CoreLocation
import Combine
import UIKit

enum HeadingMode { case magnetic, trueNorth, auto }

final class HeadingService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let lm = CLLocationManager()

    @Published var headingDeg: Double? = nil       // 平滑后的 0~360
    @Published var modeLabel: String? = nil        // "T"/"M"
    var mode: HeadingMode = .auto
    var speedThresholdForCourse: CLLocationSpeed = 2.5  // m/s

    // 向量化 EMA 平滑
    private var vx: Double = 1, vy: Double = 0
    private let alpha: Double = 0.18

    private var lastSpeed: CLLocationSpeed = 0

    override init() {
        super.init()
        lm.delegate = self
        lm.desiredAccuracy = kCLLocationAccuracyBest
        lm.headingFilter = 1
        lm.requestWhenInUseAuthorization()
    }

    func start() {
        if CLLocationManager.headingAvailable() { lm.startUpdatingHeading() }
        lm.startUpdatingLocation()
        updateHeadingOrientation()
    }

    func stop() {
        lm.stopUpdatingHeading()
        lm.stopUpdatingLocation()
    }

    func setMode(_ m: HeadingMode) { mode = m }

    // 与 UI/相机方向保持一致（横屏锁定时可强制设定）
    func updateHeadingOrientation(lockedLandscapeRight: Bool = false) {
        lm.headingOrientation = lockedLandscapeRight ? .landscapeRight : .portrait
    }

    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastSpeed = locations.last?.speed ?? 0
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool { true }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0, newHeading.headingAccuracy <= 25 else { return }

        var useCourse = false
        var raw: Double?

        // 选择真/磁/自动
        switch mode {
        case .trueNorth:
            if newHeading.trueHeading >= 0 {
                raw = newHeading.trueHeading
                modeLabel = "T"
            } else { useCourse = true }
        case .magnetic:
            raw = newHeading.magneticHeading
            modeLabel = "M"
        case .auto:
            if newHeading.trueHeading >= 0 {
                raw = newHeading.trueHeading; modeLabel = "T"
            } else {
                raw = newHeading.magneticHeading; modeLabel = "M"
            }
        }

        if raw == nil || useCourse {
            // 原 heading 不可用，且速度足够时回退到 course
            if lastSpeed >= speedThresholdForCourse, let c = manager.location?.course, c >= 0 {
                raw = c
                // modeLabel 保持当前，不改变
            } else {
                return
            }
        }

        guard let angle = raw else { return }
        smoothAngle(angle)
    }

    // 圆角向量 EMA
    private func smoothAngle(_ deg: Double) {
        let r = deg * .pi / 180
        let cx = cos(r), sy = sin(r)
        vx = vx * (1 - alpha) + cx * alpha
        vy = vy * (1 - alpha) + sy * alpha
        let ang = atan2(vy, vx) * 180 / .pi
        headingDeg = (ang < 0) ? (ang + 360) : ang
    }
}
