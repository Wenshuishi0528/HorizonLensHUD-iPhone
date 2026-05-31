
//  CameraService.swift
//  HUD2

import AVFoundation
import UIKit
import Combine
import Photos

// —— 相机选项 —— //
enum CamLens: String, CaseIterable { case wide = "Wide", ultraWide = "UltraWide", tele = "Tele" }
enum CamFPS: Int, CaseIterable { case fps30 = 30, fps60 = 60, fps120 = 120 }
enum VideoResolution: String, CaseIterable {
    case res720p = "720p", res1080p = "1080p", res4k = "4K"
    var preset: AVCaptureSession.Preset {
        switch self {
        case .res720p:   return .hd1280x720
        case .res1080p:  return .hd1920x1080
        case .res4k:     return .hd4K3840x2160
        }
    }
    var displayName: String {
        switch self {
        case .res720p: return "1280×720 (720p)"
        case .res1080p: return "1920×1080 (1080p)"
        case .res4k: return "3840×2160 (4K)"
        }
    }
}

// —— CameraService —— //
final class CameraService: NSObject, ObservableObject {

    // 基本会话
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    private var videoDeviceInput: AVCaptureDeviceInput?
    private var audioDeviceInput: AVCaptureDeviceInput?
    private weak var previewLayer: AVCaptureVideoPreviewLayer?
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?

    // 录制 & 拍照
    private var fileOutput: AVCaptureMovieFileOutput?
    private let photoOutput = AVCapturePhotoOutput()
    @Published var isRecording: Bool = false

    // 设置项（UI 观察）
    @Published var lockedLandscapeRight: Bool = false
    @Published var selectedLens: CamLens = .wide
    @Published var selectedFPS: CamFPS  = .fps60
    @Published var selectedResolution: VideoResolution = .res1080p

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updatePreviewRotationAngle),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    func attachPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        previewLayer = layer
        updatePreviewRotationAngle()
    }

    // MARK: - 配置会话
    func configureSession() {
        sessionQueue.sync {
            session.beginConfiguration()
            defer { session.commitConfiguration() }

            // 分辨率
            let preset = selectedResolution.preset
            if session.canSetSessionPreset(preset) { session.sessionPreset = preset }

            // 清空旧输入/输出
            if let input = videoDeviceInput { session.removeInput(input); videoDeviceInput = nil }
            if let ainput = audioDeviceInput { session.removeInput(ainput); audioDeviceInput = nil }
            if let out = fileOutput { session.removeOutput(out); fileOutput = nil }

            // 视频输入
            guard let device = deviceForSelectedLens() else { print("❌ 无可用相机"); return }
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) { session.addInput(input); videoDeviceInput = input }
                rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: nil)
                try setFrameRate(device: device, fps: selectedFPS.rawValue)
            } catch { print("❌ 配置相机失败：\(error)") }

            // 音频输入
            if let audioDev = AVCaptureDevice.default(for: .audio) {
                do {
                    let aIn = try AVCaptureDeviceInput(device: audioDev)
                    if session.canAddInput(aIn) { session.addInput(aIn); audioDeviceInput = aIn }
                } catch { print("❌ 音频输入失败：\(error)") }
            }

            // 录像输出（含音频）
            let out = AVCaptureMovieFileOutput()
            out.movieFragmentInterval = .invalid // 合并为单文件
            if session.canAddOutput(out) { session.addOutput(out); fileOutput = out }

            // 拍照输出
            if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        }
        updatePreviewRotationAngle()
    }

    func start() {
        sessionQueue.async { if !self.session.isRunning { self.session.startRunning() } }
        DispatchQueue.main.async { self.updatePreviewRotationAngle() }
    }

    func stop() {
        sessionQueue.async { if self.session.isRunning { self.session.stopRunning() } }
    }

    // MARK: - 控件操作
    func switchLens(to lens: CamLens) { selectedLens = lens; configureSession() }
    func setFPS(_ fps: CamFPS) {
        selectedFPS = fps
        if let dev = videoDeviceInput?.device { try? setFrameRate(device: dev, fps: fps.rawValue) }
    }
    func setLandscapeLock(_ locked: Bool) { lockedLandscapeRight = locked; updatePreviewRotationAngle() }
    func setResolution(_ res: VideoResolution) { selectedResolution = res; configureSession() }

    // MARK: - 旋转
    @objc func updatePreviewRotationAngle() {
        guard let layer = previewLayer, let connection = layer.connection else { return }

        // 1. 先根据「屏幕方向锁定」+ 当前界面方向，计算基础 videoOrientation
        var targetOrientation: AVCaptureVideoOrientation = .portrait

        if lockedLandscapeRight {
            // 在设置里选择了“横屏固定（右）”：不管手机怎么转，相机一律按照横屏右侧来渲染
            targetOrientation = .landscapeRight
        } else {
            // 未锁定为横屏时，跟随当前 UIWindowScene 的界面方向
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                switch scene.interfaceOrientation {
                case .landscapeLeft:
                    targetOrientation = .landscapeLeft
                case .landscapeRight:
                    targetOrientation = .landscapeRight
                case .portraitUpsideDown:
                    targetOrientation = .portraitUpsideDown
                default:
                    targetOrientation = .portrait
                }
            }
        }

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = targetOrientation
        }

        // 2. 针对 iOS 17+ 的 videoRotationAngle：
        //    - 未锁定横屏时，继续用 RotationCoordinator 做地平线校正
        //    - 锁定横屏时，不再额外旋转，避免“竖的数据塞进横屏”的情况
        if lockedLandscapeRight {
            if connection.isVideoRotationAngleSupported(0) {
                connection.videoRotationAngle = 0
            }
        } else if let rc = rotationCoordinator {
            let angle = rc.videoRotationAngleForHorizonLevelCapture
            if connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
        }
    }

    // MARK: - 录像控制
    func startRecording() {
        sessionQueue.async {
            guard let out = self.fileOutput, !out.isRecording else { return }

            // 麦克风权限 + 音频会话设置
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker])
                try audioSession.setActive(true)
            } catch { print("❌ 音频会话失败：\(error)") }

            let dir = FileManager.default.temporaryDirectory
            let url = dir.appendingPathComponent(self.timestamp() + ".mov")
            DispatchQueue.main.async { self.isRecording = true }
            out.startRecording(to: url, recordingDelegate: self)
        }
    }

    func stopRecording() {
        sessionQueue.async {
            guard let out = self.fileOutput, out.isRecording else { return }
            out.stopRecording()
        }
    }

    private func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f.string(from: .now)
    }

    // MARK: - Helpers
    private func deviceForSelectedLens() -> AVCaptureDevice? {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera],
            mediaType: .video, position: .back)
        switch selectedLens {
        case .wide:
            return discovery.devices.first(where: { $0.deviceType == .builtInWideAngleCamera }) ?? discovery.devices.first
        case .ultraWide:
            return discovery.devices.first(where: { $0.deviceType == .builtInUltraWideCamera })
                ?? discovery.devices.first(where: { $0.deviceType == .builtInWideAngleCamera })
        case .tele:
            return discovery.devices.first(where: { $0.deviceType == .builtInTelephotoCamera })
                ?? discovery.devices.first(where: { $0.deviceType == .builtInWideAngleCamera })
        }
    }

    private func setFrameRate(device: AVCaptureDevice, fps: Int) throws {
        try device.lockForConfiguration(); defer { device.unlockForConfiguration() }
        let desired = Double(fps)
        var matched: CMTimeScale? = nil
        for range in device.activeFormat.videoSupportedFrameRateRanges {
            if desired >= range.minFrameRate - 0.1 && desired <= range.maxFrameRate + 0.1 {
                matched = CMTimeScale(desired); break
            }
        }
        let target = matched ?? CMTimeScale(Int(device.activeFormat.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 30))
        let duration = CMTime(value: 1, timescale: target)
        device.activeVideoMinFrameDuration = duration
        device.activeVideoMaxFrameDuration = duration
    }
}

// —— 录像回调：保存到相册 —— //
extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        DispatchQueue.main.async { self.isRecording = false }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
            })
        }
    }
}

// MARK: - 拍照（放在扩展里，能访问 photoOutput 且可用 delegate: self）
extension CameraService {
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        if #available(iOS 16.0, *) {
            // iOS16+ 用 maxPhotoDimensions；避免 isHighResolutionPhotoEnabled 弃用警告
            settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        } else {
            settings.isHighResolutionPhotoEnabled = true
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), let img = UIImage(data: data) else {
            print("❌ 拍照失败:", error?.localizedDescription ?? "unknown"); return
        }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: img)
            })
        }
    }
}
