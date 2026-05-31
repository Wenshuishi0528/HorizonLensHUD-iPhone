//
//  ScreenRecorder.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//

import Foundation
import ReplayKit
import Photos

final class ScreenRecorder: NSObject, ObservableObject {
    @Published var isRecording: Bool = false

    func start() {
        let rec = RPScreenRecorder.shared()
        rec.isMicrophoneEnabled = true
        rec.startRecording { err in
            DispatchQueue.main.async { self.isRecording = (err == nil) }
            if let e = err { print("❌ ScreenRecord start error:", e) }
        }
    }

    func stop() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("HUD_\(Self.ts()).mp4")
        RPScreenRecorder.shared().stopRecording(withOutput: url) { err in
            DispatchQueue.main.async { self.isRecording = false }
            if let e = err { print("❌ ScreenRecord stop error:", e); return }
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { st in
                guard st == .authorized || st == .limited else { return }
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                })
            }
        }
    }

    private static func ts() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyyMMdd_HHmmss"; return f.string(from: .now)
    }
}
