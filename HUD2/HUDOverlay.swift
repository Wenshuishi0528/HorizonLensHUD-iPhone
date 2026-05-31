//
//  HUDOverlay.swift
//  HUD2
//
//  + Composite │G│ badge (based on gLong & gLat), supports per-widget drag toggle via @AppStorage.
//

import SwiftUI
import CoreLocation

struct HUDOverlay: View {
    // 数据
    let pitch: Double
    let roll: Double
    let heading: Double?
    let headingModeLabel: String?
    let speedMS: Double
    let altitudeMSL: Double
    let verticalSpeedMS: Double
    let pressureHPA: Double
    let gLong: Double
    let gLat: Double
    let isLandscape: Bool
    let audioDBFS: Double   // 新增参数

    // 小地图需要的定位数据
    let userCoord: CLLocationCoordinate2D?
    let userAccuracy: CLLocationDistance?
    let track: [CLLocationCoordinate2D]

    @EnvironmentObject var appState: AppState

    // 允许针对综合G单独开启拖拽
    @AppStorage("gCompositeAllowDrag") private var gCompositeAllowDrag: Bool = false

    private enum Key {
        static let bank = "bankScale"
        static let heading = "headingTape"
        static let attitude = "attitude"
        static let speed = "speedTape"
        static let alt = "altitudeTape"
        static let vs = "vsTape"
        static let vsBadge = "vsBadge"
        static let data = "dataStrip"
        static let rollLevel = "rollLevel"
        static let mini = "miniMap"
        static let audio = "audioLevel"
        static let gmeter = "gMeter"
    }

    var body: some View {
        GeometryReader { geo in
            let sz = geo.size
            let scale = appState.fontSize.scale

            ZStack {
                if appState.showBankScale {
                    draggable(id: Key.bank, in: sz, defaultXY: CGPoint(x: 0.5, y: 0.08)) {
                        BankScale(roll: roll).frame(height: 110 * scale)
                    }
                }

                if appState.showHeadingTape, let hdg = heading, let mode = headingModeLabel {
                    draggable(id: Key.heading, in: sz, defaultXY: CGPoint(x: 0.5, y: 0.14)) {
                        HeadingTape(heading: hdg, mode: mode).padding(.top, -18)
                    }
                }

                if appState.showAttitude {
                    draggable(id: Key.attitude, in: sz, defaultXY: CGPoint(x: 0.5, y: 0.5)) {
                        AttitudeIndicator(pitch: pitch, roll: roll).opacity(0.98)
                    }
                }

                if appState.showSpeedTape {
                    draggable(id: Key.speed, in: sz, defaultXY: CGPoint(x: 0.17, y: 0.50)) {
                        SpeedTape(speedMS: speedMS,
                                  isLandscape: isLandscape,
                                  units: appState.unitSystem,
                                  speedMetricUnit: appState.speedMetricUnit,
                                  fontScale: scale)
                    }
                }

                if appState.showAltitudeTape {
                    draggable(id: Key.alt, in: sz, defaultXY: CGPoint(x: 0.83, y: 0.50)) {
                        AltitudeTape(altitudeM: altitudeMSL, isLandscape: isLandscape,
                                     units: appState.unitSystem, fontScale: scale)
                    }
                }

                if appState.showVSTape {
                    draggable(id: Key.vs, in: sz, defaultXY: CGPoint(x: 0.5, y: 0.5)) {
                        VSTape(vsMS: verticalSpeedMS, isLandscape: isLandscape,
                               units: appState.unitSystem, fontScale: scale)
                    }
                }

                if appState.showDataStrip {
                    draggable(id: Key.data, in: sz,
                              defaultXY: CGPoint(x: 0.5, y: isLandscape ? 0.88 : 0.93)) {
                        FlightDataStrip(speedMS: speedMS,
                                        altitudeMSL: altitudeMSL,
                                        vsMS: verticalSpeedMS,
                                        pressureHPA: pressureHPA,
                                        units: appState.unitSystem,
                                        lang: appState.language,
                                        fontScale: scale,
                                        speedMetricUnit: appState.speedMetricUnit)
                    }
                }

                // 综合│G│（基于 gLong/gLat 合成，单位 g）
                if appState.showGMeter {
                    draggable(id: Key.gmeter, in: sz,
                              defaultXY: CGPoint(x: 0.86, y: isLandscape ? 0.86 : 0.90),
                              forceDraggable: gCompositeAllowDrag) {
                        let gAbs = sqrt(gLong * gLong + gLat * gLat)
                        GCompositeBadge(gAbs: gAbs, scale: scale)
                    }
                }

                // 小地图
                if appState.showMiniMap {
                    draggable(id: Key.mini, in: sz,
                              defaultXY: CGPoint(x: 0.14, y: isLandscape ? 0.86 : 0.90)) {
                        MiniMapView(center: userCoord,
                                    track: track,
                                    accuracy: userAccuracy,
                                    side: 120 * scale)
                    }
                }

                if appState.showVSBadge {
                    draggable(id: Key.vsBadge, in: sz, defaultXY: CGPoint(x: 0.5, y: 0.62)) {
                        VSBadge(vsMS: verticalSpeedMS, units: appState.unitSystem, scale: scale)
                    }
                }

                // 横滚水平仪（默认在顶端偏下，可拖拽）
                if appState.showRollLevel {
                    draggable(id: Key.rollLevel, in: sz, defaultXY: CGPoint(x: 0.5, y: 0.20)) {
                        RollLevelView(rollDeg: roll, scale: scale)
                    }
                }

                if appState.showAudioLevel {
                    draggable(id: Key.audio, in: sz, defaultXY: CGPoint(x: 0.86, y: isLandscape ? 0.82 : 0.88)) {
                        AudioBadge(db: audioDBFS, scale: scale)
                    }
                }

                // 固定底部横滚读数
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        rollBadgeText(rollDeg: roll, scale: scale).padding(.bottom, 8)
                        Spacer()
                    }
                }
                .allowsHitTesting(false)
            }
            .allowsHitTesting(appState.layoutEditingEnabled)
        }
    }

    // — 常量横滚数值显示 —
    @ViewBuilder
    private func rollBadgeText(rollDeg: Double, scale: CGFloat) -> some View {
        let title: String = {
            switch appState.language {
            case .zh: return "横滚"
            case .en: return "ROLL"
            case .system:
                let isZh = Locale.current.language.languageCode?.identifier == "zh"
                return isZh ? "横滚" : "ROLL"
            }
        }()
        Text("\(title) \(String(format: "%+.1f°", rollDeg))")
            .font(.system(size: 14 * scale, weight: .semibold, design: .rounded))
            .padding(.horizontal, 10 * scale)
            .padding(.vertical, 6 * scale)
            .background(.ultraThinMaterial, in: Capsule())
    }

    // — 拖拽封装 —
    @ViewBuilder
    private func draggable<Content: View>(
        id: String, in container: CGSize, defaultXY: CGPoint,
        forceDraggable: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let posNorm = appState.position(for: id, default: defaultXY)
        let posAbs = CGPoint(x: posNorm.x * container.width, y: posNorm.y * container.height)

        content()
            .position(posAbs)
            .gesture(
                DragGesture().onChanged { value in
                    guard appState.layoutEditingEnabled || forceDraggable else { return }
                    let p = CGPoint(x: value.location.x / container.width,
                                    y: value.location.y / container.height)
                    appState.setPosition(p, for: id)
                }
            )
            .overlay(alignment: .topLeading) {
                if appState.layoutEditingEnabled {
                    Text(id).font(.caption2).padding(4)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
    }

    private struct AudioBadge: View {
        let db: Double
        let scale: CGFloat
        var body: some View {
            Text(String(format: "VOL %.1f dB", db))
                .font(.system(size: 12 * scale, weight: .semibold, design: .rounded))
                .padding(.horizontal, 10 * scale)
                .padding(.vertical, 6 * scale)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private struct VSBadge: View {
        let vsMS: Double
        let units: UnitSystem
        let scale: CGFloat
        var body: some View {
            let value: Double
            let unit: String
            switch units {
            case .metric:   value = vsMS;                 unit = "m/s"
            case .imperial, .aviation: value = vsMS * 196.85039; unit = "fpm"
            }
            return Text("V/S \(String(format: "%+.1f", value)) \(unit)")
                .font(.system(size: 14 * scale, weight: .semibold, design: .rounded))
                .padding(.horizontal, 10 * scale).padding(.vertical, 6 * scale)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private struct GCompositeBadge: View {
        let gAbs: Double
        let scale: CGFloat
        var body: some View {
            Text(String(format: "│G│ %.2f", gAbs))
                .font(.system(size: 14 * scale, weight: .bold, design: .rounded))
                .monospacedDigit()
                .padding(.horizontal, 10 * scale)
                .padding(.vertical, 6 * scale)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}
