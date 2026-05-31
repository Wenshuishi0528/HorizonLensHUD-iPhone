//
//  AltimeterService.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//

import Foundation
import CoreMotion
import Combine

final class AltimeterService: ObservableObject {
    private let alt = CMAltimeter()
    @Published var relAltM: Double = 0        // 相对高度（以启动时为零）
    @Published var pressureHPA: Double = 0    // 百帕
    @Published var verticalSpeedMS: Double = 0 // 垂直速度 m/s（相对高的导数）

    private var lastTime: TimeInterval?
    private var lastRel: Double = 0
    private let alpha: Double = 0.25          // EMA 平滑

    func start() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        alt.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            guard let self, let d = data else { return }
            // pressure 单位是 kPa
            let kPa = d.pressure.doubleValue
            pressureHPA = kPa * 10.0

            let rel = d.relativeAltitude.doubleValue   // meters
            relAltM = rel

            let t = Date().timeIntervalSince1970
            if let lastT = lastTime {
                let dt = max(0.02, t - lastT)
                let rawVS = (rel - lastRel) / dt
                verticalSpeedMS = verticalSpeedMS * (1 - alpha) + rawVS * alpha
            }
            lastTime = t
            lastRel = rel
        }
    }

    func stop() { alt.stopRelativeAltitudeUpdates() }
    func resetZero() { lastRel = 0; relAltM = 0 } // 可加：手动归零
}
