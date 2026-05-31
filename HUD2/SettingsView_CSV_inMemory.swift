//
//  SettingsView.swift
//  HUD2
//
//  + Head zero offset (0° / ±90° / ±180°) in “姿态基线与微调”.
//  + Composite │G│ meter: show toggle (reuse appState.showGMeter) & allow-drag toggle (@AppStorage).
//

import SwiftUI

struct SettingsView: View {
    @State private var showShare = false
    @State private var shareURL: URL? = nil
    @ObservedObject var appState: AppState
    @ObservedObject var camera: CameraService
    @ObservedObject var heading: HeadingService

    @State private var lens: CamLens = .wide
    @State private var fps: CamFPS = .fps60
    @State private var headingModeIndex: Int = 0
    @State private var resolution: VideoResolution = .res1080p   // ← 已有

    // 航向零点偏移（0/±90/±180），持久化到 UserDefaults
    @AppStorage("headingZeroOffsetDeg") private var headZeroOffsetDeg: Int = 0

    // 新增：综合G拖拽开关
    @AppStorage("gCompositeAllowDrag") private var gCompositeAllowDrag: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                // 布局
                Section(header: Text(loc("布局"))) {
                    Toggle(loc("开启布局编辑（可拖拽组件）"), isOn: $appState.layoutEditingEnabled)
                    Toggle(loc("显示：人工地平线"), isOn: $appState.showAttitude)
                    Toggle(loc("显示：翻滚刻度弧"), isOn: $appState.showBankScale)
                    Toggle(loc("显示：航向带"), isOn: $appState.showHeadingTape)
                    Toggle(loc("显示：速度带"), isOn: $appState.showSpeedTape)
                    Toggle(loc("显示：高度带"), isOn: $appState.showAltitudeTape)
                    Toggle(loc("显示：横滚水平仪"), isOn: $appState.showRollLevel)
                    Toggle(loc("显示：垂直速度梯"), isOn: $appState.showVSTape)
                    Toggle(loc("显示：V/S 数值"), isOn: $appState.showVSBadge)        // ← 已有
                    Toggle(loc("显示：底部数据条"), isOn: $appState.showDataStrip)
                    Toggle(loc("显示：音量电平"), isOn: $appState.showAudioLevel)
                    // 将原“G-Meter（加速度）”改为综合│G│显示
                    Toggle(loc("显示：综合G（│G│）"), isOn: $appState.showGMeter)
                    Toggle(loc("允许拖拽：综合G"), isOn: $gCompositeAllowDrag)
                    Toggle(loc("启用 CSV 日志记录"), isOn: $appState.enableCSVLog)
                    Toggle(loc("显示：小地图"), isOn: $appState.showMiniMap)
                    Toggle(loc("显示：录像按钮"), isOn: $appState.showRecordButton)
                    Toggle(loc("显示：拍照按钮"), isOn: $appState.showPhotoButton)
                    Toggle(loc("显示：俯仰条"), isOn: $appState.showPitchBar)
                    Button(role: .destructive) { appState.overlayPositions = [:] } label: {
                        Text(loc("重置布局到默认位置"))
                    }
                }

                Section(header: Text(loc("数据与导出"))) {
                    Button(loc("导出 CSV 到“文件”")) {
                        let header = "timeISO,lat,lon,acc_m,speed_ms,alt_m,vs_ms,heading_deg,pitch_deg,roll_deg,pressure_hpa,audio_dbfs"
                        let csvString: String
                        if appState.csvRows.isEmpty {
                            // 即使没有数据，也导出表头，防止空文件
                            csvString = header + "\n"
                        } else {
                            csvString = ([header] + appState.csvRows).joined(separator: "\n") + "\n"
                        }
                        let fm = FileManager.default
                        if let dir = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyyMMdd_HHmmss"
                            let name = "HUD_\(formatter.string(from: .now)).csv"
                            let url = dir.appendingPathComponent(name)
                            do {
                                try csvString.write(to: url, atomically: true, encoding: .utf8)
                                shareURL = url
                                showShare = true
                            } catch {
                                print("❌ CSV export write failed:", error)
                            }
                        }
                    }
                    .disabled(appState.csvRows.isEmpty)
                    Text(loc("说明：选择“存储到“文件””可保存到 iCloud Drive 或本机“文件”。"))
                        .font(.footnote).foregroundStyle(.secondary)
                }

                // 外观
                Section(header: Text(loc("外观"))) {
                    Picker(loc("字号"), selection: $appState.fontSize) {
                        Text(loc("小")).tag(HUDSize.small)
                        Text(loc("中")).tag(HUDSize.medium)
                        Text(loc("大")).tag(HUDSize.large)
                    }
                    Picker(loc("单位"), selection: $appState.unitSystem) {
                        Text("Metric / 公制").tag(UnitSystem.metric)
                        Text("Imperial / 英制").tag(UnitSystem.imperial)
                        Text("Aviation / 航空").tag(UnitSystem.aviation)
                    }
                    if appState.unitSystem == .metric {                            // ← 仅公制时显示
                        Picker(loc("速度单位（公制）"), selection: $appState.speedMetricUnit) {
                            Text("m/s").tag(SpeedMetricUnit.ms)
                            Text("km/h").tag(SpeedMetricUnit.kmh)
                        }
                    }
                    Picker(loc("语言"), selection: $appState.language) {
                        Text(loc("跟随系统")).tag(HUDLanguage.system)
                        Text("中文").tag(HUDLanguage.zh)
                        Text("English").tag(HUDLanguage.en)
                    }
                    Picker(loc("HUD 颜色"), selection: $appState.hudColor) {
                        Text(loc("红色")).tag(HUDColorScheme.red)
                        Text(loc("绿色")).tag(HUDColorScheme.green)
                        Text(loc("白色")).tag(HUDColorScheme.white)
                    }
                    .pickerStyle(.segmented)

                }

                // 姿态基线与微调
                Section(header: Text(loc("姿态基线与微调"))) {
                    Picker(loc("俯仰零点"), selection: $appState.pitchZeroMode) {
                        Text(loc("地心为零")).tag(PitchZeroMode.earthCenter)
                        Text(loc("水平为零")).tag(PitchZeroMode.horizon)
                        Text(loc("天空为零")).tag(PitchZeroMode.sky)
                    }
                    HStack { Text(loc("航向微调")); Spacer()
                        Stepper(value: $appState.yawTrimDeg, in: -30...30, step: 0.5) {
                            Text(String(format: "%+.1f°", appState.yawTrimDeg))
                        }
                    }

                    // 航向零点偏移（0/±90/±180）
                    Picker(loc("航向零点偏移"), selection: $headZeroOffsetDeg) {
                        Text("0°").tag(0)
                        Text("−90°").tag(-90)
                        Text("+90°").tag(90)
                        Text("−180°").tag(-180)
                        Text("+180°").tag(180)
                    }
                    .pickerStyle(.segmented)

                    HStack { Text(loc("俯仰微调")); Spacer()
                        Stepper(value: $appState.pitchTrimDeg, in: -30...30, step: 0.5) {
                            Text(String(format: "%+.1f°", appState.pitchTrimDeg))
                        }
                    }
                    HStack { Text(loc("横滚微调")); Spacer()
                        Stepper(value: $appState.rollTrimDeg, in: -30...30, step: 0.5) {
                            Text(String(format: "%+.1f°", appState.rollTrimDeg))
                        }
                    }
                    Picker(loc("横滚零度偏移"), selection: $appState.rollZeroOffset) {
                        Text("0°").tag(RollZeroOffset.deg0)
                        Text("90°").tag(RollZeroOffset.deg90)
                        Text("180°").tag(RollZeroOffset.deg180)
                        Text("270°").tag(RollZeroOffset.deg270)
                    }
                }

                // 相机与航向
                Section(header: Text(loc("相机与航向"))) {
                    Picker(loc("屏幕方向"), selection: $appState.orientationLock) {
                        Text(loc("跟随系统")).tag(OrientationLock.system)
                        Text(loc("竖屏固定")).tag(OrientationLock.portrait)
                        Text(loc("横屏固定（右）")).tag(OrientationLock.landscapeRight)
                    }
                    .pickerStyle(.segmented)

                    Picker(loc("镜头"), selection: $lens) {
                        ForEach(CamLens.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    Picker(loc("帧率"), selection: $fps) {
                        ForEach(CamFPS.allCases, id: \.self) { Text("\($0.rawValue) fps").tag($0) }
                    }
                    Picker(loc("分辨率"), selection: $resolution) {                 // ← 已有
                        ForEach(VideoResolution.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }

                    Picker(loc("航向基准"), selection: $headingModeIndex) {
                        Text(loc("自动")).tag(0)
                        Text("True (T)").tag(1)
                        Text("Magnetic (M)").tag(2)
                    }
                }
            }
            .navigationTitle(loc("设置"))
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(loc("完成")) { appState.showSettings = false } } }
            .sheet(isPresented: $showShare) {
                if let url = shareURL { ShareSheet(items: [url]) }
            }
        }
        .onAppear {
            lens = camera.selectedLens
            fps  = camera.selectedFPS
            resolution = camera.selectedResolution
            switch heading.mode { case .auto: headingModeIndex = 0; case .trueNorth: headingModeIndex = 1; case .magnetic: headingModeIndex = 2 }
        }
        .onChange(of: lens) { _, v in camera.switchLens(to: v) }
        .onChange(of: fps) { _, v in camera.setFPS(v) }
        .onChange(of: resolution) { _, v in camera.setResolution(v) }    // ← 已有
        .onChange(of: headingModeIndex) { _, v in heading.setMode([.auto, .trueNorth, .magnetic][v]) }
    }

    // 保持你的本地化结构，补上新增文案
    private func loc(_ s: String) -> String {
        switch appState.language {
        case .zh:
            return s
        case .en:
            return en(s)
        case .system:
            let isZh = Locale.current.language.languageCode?.identifier == "zh"
            return isZh ? s : en(s)
        }
    }

    // 英文映射表
    private func en(_ s: String) -> String {
        switch s {
        case "布局": return "Layout"
        case "开启布局编辑（可拖拽组件）": return "Enable layout edit (drag overlays)"
        case "显示：人工地平线": return "Show: Attitude Indicator"
        case "显示：翻滚刻度弧": return "Show: Bank Scale"
        case "显示：航向带": return "Show: Heading Tape"
        case "显示：速度带": return "Show: Speed Tape"
        case "显示：高度带": return "Show: Altitude Tape"
        case "显示：垂直速度梯": return "Show: V/S Ladder"
        case "显示：V/S 数值": return "Show: V/S Badge"
        case "速度单位（公制）": return "Speed Unit (Metric)"
        case "显示：底部数据条": return "Show: Bottom Data Strip"
        case "显示：小地图": return "Show: Mini Map"
        case "重置布局到默认位置": return "Reset layout to defaults"
        case "显示：横滚水平仪": return "Show: Roll Level"
        case "外观": return "Appearance"
        case "字号": return "Font Size"
        case "单位": return "Units"
        case "语言": return "Language"
        case "跟随系统": return "System"
        case "小": return "Small"
        case "中": return "Medium"
        case "大": return "Large"
        case "姿态基线与微调": return "Attitude Baseline & Trim"
        case "显示：音量电平": return "Show: Audio Level"
        case "启用 CSV 日志记录": return "Enable CSV Logging"
        case "显示：综合G（│G│）": return "Show: |G| Composite"
        case "允许拖拽：综合G": return "Allow Drag: |G| Composite"
        case "俯仰零点": return "Pitch Zero"
        case "地心为零": return "Earth-centered 0"
        case "水平为零": return "Horizon 0"
        case "天空为零": return "Sky 0"
        case "航向微调": return "Heading Trim"
        case "航向零点偏移": return "Head zero offset"
        case "俯仰微调": return "Pitch Trim"
        case "横滚微调": return "Roll Trim"
        case "横滚零度偏移": return "Roll Zero Offset"
        case "0°": return "0°"
        case "90°": return "90°"
        case "180°": return "180°"
        case "270°": return "270°"
        case "相机与航向": return "Camera & Heading"
        case "屏幕方向": return "Screen Orientation"
        case "竖屏固定": return "Portrait Lock"
        case "横屏固定（右）": return "Landscape Right Lock"
        case "镜头": return "Lens"
        case "帧率": return "FPS"
        case "分辨率": return "Resolution"
        case "航向基准": return "Heading Mode"
        case "自动": return "Auto"
        case "设置": return "Settings"
        case "完成": return "Done"
        case "数据与导出": return "Data & Export"
        case "导出 CSV 到“文件”": return "Export CSV to Files"
        case "说明：选择“存储到“文件””可保存到 iCloud Drive 或本机“文件”。": return "Tip: Choose \"Save to Files\" to store in iCloud Drive or On My iPhone."
        case "显示：录像按钮": return "Show: Record Button"
        case "显示：拍照按钮": return "Show: Photo Button"
        case "显示：俯仰条": return "Show: Pitch Bar"
        default: return s
        }
    }

    // 你的实现里已有 CSV 输出，这里仅占位，保持文件可独立编译
    private func latestCSVURL() -> URL? { nil }
}
