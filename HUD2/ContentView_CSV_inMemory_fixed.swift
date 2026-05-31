import SwiftUI
import AVFoundation
import CoreLocation
import UIKit

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    @StateObject private var camera = CameraService()
    @StateObject private var motion = MotionService()
    @StateObject private var headingSvc = HeadingService()
    @StateObject private var loc = LocationService()
    @StateObject private var alt = AltimeterService()
    @StateObject private var orientation = OrientationWatcher()
    @StateObject private var screenRec = ScreenRecorder()   // 录“屏幕”，成片包含 HUD
    @StateObject private var audio = AudioLevelService()
    @State private var csvTimer: Timer?

    var body: some View {
        ZStack {
            // 相机预览
            CameraPreviewView(session: camera.session) { layer in
                camera.attachPreviewLayer(layer)
            }
            .ignoresSafeArea()

            // HUD 叠加
            HUDOverlay(
                pitch: adjustedPitchDeg(),
                roll: adjustedRollDeg(),
                heading: adjustedHeadingDeg(),
                headingModeLabel: headingSvc.modeLabel,
                speedMS: loc.speedMS,
                altitudeMSL: loc.altitudeMSL,
                verticalSpeedMS: alt.verticalSpeedMS,
                pressureHPA: alt.pressureHPA,
                gLong: motion.gLong,
                gLat: motion.gLat,
                isLandscape: orientation.isLandscape,
                audioDBFS: audio.dbFS,
                userCoord: loc.lastCoordinate,
                userAccuracy: loc.horizontalAccuracy,
                track: loc.track
            )
            .environmentObject(appState)
            .foregroundStyle(appState.hudTint)
            .foregroundColor(appState.hudTint)
            .tint(appState.hudTint)
            .ignoresSafeArea()

            // 右上角：设置
            VStack {
                HStack {
                    Spacer()
                    Button { appState.showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .bold))
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding([.top, .trailing], 12)
                }
                Spacer()
            }

            // 右下角：录制按钮（录屏，含 HUD 和麦克风）
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    RecordButton(isRecording: screenRec.isRecording) {
                        screenRec.isRecording ? screenRec.stop() : screenRec.start()
                    }
                    .padding(.trailing, 14)
                    .padding(.bottom, 16)
                }
            }
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView(appState: appState, camera: camera, heading: headingSvc)
        }
        .onAppear {
            applyOrientationLock(appState.orientationLock)
            startSensors()
            audio.start()
            ensureCameraRunning()
            headingSvc.updateHeadingOrientation(lockedLandscapeRight: camera.lockedLandscapeRight)
            if appState.enableCSVLog {
                appState.csvRows.removeAll()
                startCSVTimer()
            }
        }
        .onDisappear {
            stopSensors()
            audio.stop()
            stopCSVTimer()
        }
        .onChange(of: camera.lockedLandscapeRight) { _, v in
            headingSvc.updateHeadingOrientation(lockedLandscapeRight: v)
        }
        .onChange(of: orientation.isLandscape) { _, _ in
            headingSvc.updateHeadingOrientation(lockedLandscapeRight: camera.lockedLandscapeRight)
        }
        .onChange(of: appState.orientationLock) { _, newLock in
            applyOrientationLock(newLock)
        }
        .onChange(of: appState.enableCSVLog) { _, enabled in
            if enabled {
                appState.csvRows.removeAll()
                startCSVTimer()
            } else {
                stopCSVTimer()
            }
        }
    }

    // MARK: - 姿态/航向修正（在结构体内部）
    private func adjustedPitchDeg() -> Double {
        // 俯仰上正下负；零点模式在设置中切换
        let raw = motion.rollDeg
        let zeroOffset: Double = {
            switch appState.pitchZeroMode {
            case .horizon: return 0
            case .earthCenter: return -90
            case .sky: return 90
            }
        }()
        return raw - zeroOffset + appState.pitchTrimDeg
    }

    private func adjustedRollDeg() -> Double {
        let raw = motion.pitchDeg
        let zero = appState.rollZeroOffset.rawValue
        return raw - zero + appState.rollTrimDeg
    }

    private func adjustedHeadingDeg() -> Double? {
        guard var h = headingSvc.headingDeg else { return nil }
        h += appState.yawTrimDeg
        while h < 0 { h += 360 }
        while h >= 360 { h -= 360 }
        return h
    }

    // MARK: - 传感器与相机会话（在结构体内部）
    private func startSensors() {
        motion.start()
        headingSvc.start()
        loc.start()
        alt.start()
    }

    private func stopSensors() {
        motion.stop()
        headingSvc.stop()
        loc.stop()
        alt.stop()
    }

    private func ensureCameraRunning() {
        guard !appState.isSessionRunning else { return }
        AVCaptureDevice.requestAccess(for: .video) { granted in
            AVAudioSession.sharedInstance().requestRecordPermission { _ in
                DispatchQueue.main.async {
                    guard granted else { return }
                    camera.configureSession()
                    camera.start()
                    appState.isSessionRunning = true
                }
            }
        }
    }

    // MARK: - CSV 定时器（在结构体内部）
    private func appendOneCSVRow() {
        let iso = ISO8601DateFormatter().string(from: .now)
        let latV = self.loc.lastCoordinate?.latitude ?? .nan
        let lonV = self.loc.lastCoordinate?.longitude ?? .nan
        let acc  = self.loc.horizontalAccuracy ?? .nan
        let spd  = self.loc.speedMS
        let altM = self.loc.altitudeMSL
        let vs   = self.alt.verticalSpeedMS
        let hdg  = self.adjustedHeadingDeg() ?? .nan
        let pit  = self.adjustedPitchDeg()
        let rol  = self.adjustedRollDeg()
        let pres = self.alt.pressureHPA
        let adb  = self.audio.dbFS

        let row = "\(iso),\(latV),\(lonV),\(acc),\(spd),\(altM),\(vs),\(hdg),\(pit),\(rol),\(pres),\(adb)"
        appState.csvRows.append(row)
    }

    private func startCSVTimer() {
        // 确保不重复启动
        stopCSVTimer()
        guard appState.enableCSVLog else { return }

        // 打开记录时立即写一行
        appendOneCSVRow()

        let timer = Timer(timeInterval: 1.0, repeats: true) { _ in
            appendOneCSVRow()
        }
        csvTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopCSVTimer() {
        csvTimer?.invalidate()
        csvTimer = nil
    }


    private func applyOrientationLock(_ lock: OrientationLock) {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
    switch lock {
    case .system:
        try? scene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
        camera.lockedLandscapeRight = false
    case .portrait:
        try? scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        camera.lockedLandscapeRight = false
    case .landscapeRight:
        try? scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
        camera.lockedLandscapeRight = true
    }
    camera.updatePreviewRotationAngle()
    headingSvc.updateHeadingOrientation(lockedLandscapeRight: camera.lockedLandscapeRight)
}
}

// MARK: - 录制按钮样式
private struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(.white.opacity(0.9), lineWidth: 2)
                    .frame(width: 54, height: 54)
                if isRecording {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.red)
                        .frame(width: 24, height: 24)
                } else {
                    Circle().fill(.red).frame(width: 20, height: 20)
                }
            }
            .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRecording ? "停止录制" : "开始录制")
    }
}
