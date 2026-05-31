//
//  AppState.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//

import SwiftUI
import CoreGraphics

enum HUDColorScheme: String, CaseIterable {
    case red, green, white
    var color: Color {
        switch self {
        case .red: return .red
        case .green: return .green
        case .white: return .white
        }
    }
}


enum OrientationLock: String, CaseIterable {
    case system, portrait, landscapeRight
}
enum HUDLanguage: String, CaseIterable { case system, zh, en }
enum HUDSize: String, CaseIterable { case small, medium, large
    var scale: CGFloat { switch self { case .small: 0.9; case .medium: 1.0; case .large: 1.15 } }
}
enum PitchZeroMode: String, CaseIterable { case earthCenter, horizon, sky }
enum RollZeroOffset: Double, CaseIterable { case deg0 = 0, deg90 = 90, deg180 = 180, deg270 = 270 }
enum UnitSystem: String, CaseIterable { case metric, imperial, aviation }
enum SpeedMetricUnit: String, CaseIterable { case ms, kmh }   // ← 新增


final class AppState: ObservableObject {
    @Published var hudColor: HUDColorScheme = .green

    @Published var isSessionRunning: Bool = false
    @Published var showSettings: Bool = false

    // 布局编辑 & 显示项
    @Published var layoutEditingEnabled: Bool = false
    @Published var showAttitude: Bool = true
    @Published var showBankScale: Bool = true
    @Published var showHeadingTape: Bool = true
    @Published var showSpeedTape: Bool = true
    @Published var showAltitudeTape: Bool = true
    @Published var showVSTape: Bool = true
    @Published var showVSBadge: Bool = true                     // ← 新增：V/S 数值开关

    // 屏幕方向锁定：system/portrait/landscapeRight
    @Published var orientationLock: OrientationLock = .system

    @Published var showDataStrip: Bool = false
    @Published var showRecordButton: Bool = true
    @Published var showPhotoButton: Bool = true
    @Published var showPitchBar: Bool = false
    @Published var showMiniMap: Bool = true          // ← 新增：小地图
    
    @Published var enableCSVLog: Bool = false           // 记录 CSV 开关
    @Published var csvRows: [String] = []              // 当前会话的 CSV 行
    @Published var showAudioLevel: Bool = true

    @Published var showGMeter: Bool = false   // 显示 G-Meter          // 显示音量电平徽章


    // 外观与国际化
    @Published var fontSize: HUDSize = .medium
    @Published var unitSystem: UnitSystem = .metric
    @Published var language: HUDLanguage = .system
    @Published var speedMetricUnit: SpeedMetricUnit = .kmh      // ← 新增（仅在公制下生效）

    @Published var showRollLevel: Bool = true   // ← 新增：横滚水平仪开关

    // 零点与微调
    @Published var pitchZeroMode: PitchZeroMode = .horizon
    @Published var yawTrimDeg: Double = 0
    @Published var pitchTrimDeg: Double = 0
    @Published var rollTrimDeg: Double = 0
    @Published var rollZeroOffset: RollZeroOffset = .deg0

    // 相对坐标(0~1)
    @Published var overlayPositions: [String: CGPoint] = [:]

    func position(for key: String, default p: CGPoint) -> CGPoint {
        overlayPositions[key] ?? p
    }
    func setPosition(_ p: CGPoint, for key: String) {
        overlayPositions[key] = CGPoint(x: min(max(p.x, 0), 1), y: min(max(p.y, 0), 1))
    }

    // 当前 HUD 颜色（供视图统一取色）
    var hudTint: Color { hudColor.color }
}
