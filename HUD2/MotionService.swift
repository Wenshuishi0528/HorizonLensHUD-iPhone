//  MotionService.swift
//  HUD2

import Foundation
import CoreMotion
import Combine

final class MotionService: ObservableObject {
    private let manager = CMMotionManager()
    @Published var pitchDeg: Double = 0     // 俯仰：上正下负
    @Published var rollDeg: Double = 0      // 横滚：顺时针为正

    @Published var gLong: Double = 0        // 纵向加速度（g）：前+ 后-
    @Published var gLat: Double  = 0
        @Published var gTotal: Double = 0        // 横向加速度（g）：右+ 左-

    private var pFiltered: Double = 0
    private var rFiltered: Double = 0
    private var glFiltered: Double = 0
    private var gtFiltered: Double = 0
        private var gtotFiltered: Double = 0

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        let alpha = 0.2
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: .main) { [weak self] m, _ in
            guard let self, let m = m else { return }

            // 姿态（度）
            let pd =  m.attitude.pitch * 180.0 / .pi  // 上正下负
            let rd =  m.attitude.roll  * 180.0 / .pi  // 右下为正
            self.pFiltered = self.pFiltered * (1 - alpha) + pd * alpha
            self.rFiltered = self.rFiltered * (1 - alpha) + rd * alpha
            self.pitchDeg = self.pFiltered
            self.rollDeg  = self.rFiltered

            // 加速度（CoreMotion 的 userAcceleration 为以 g 为单位的去重力加速度）
            let ax = m.userAcceleration.x    // +X: 右
            let ay = m.userAcceleration.y    // +Y: 上
            let az = m.userAcceleration.z    // +Z: 朝向用户（屏外→屏内相反）

            // 简化定义：纵向取 -Z（向前为正），横向取 +X（向右为正）
            let gLong = -az
            let gLat  =  ax

            self.glFiltered = self.glFiltered * (1 - alpha) + gLong * alpha
            self.gtFiltered = self.gtFiltered * (1 - alpha) + gLat  * alpha

            self.gLong = self.glFiltered
            self.gLat  = self.gtFiltered

                let gtot = sqrt(ax*ax + ay*ay + az*az)
                self.gtotFiltered = self.gtotFiltered * (1 - alpha) + gtot * alpha
                self.gTotal = self.gtotFiltered
        }
    }
    func stop() { manager.stopDeviceMotionUpdates() }
}
