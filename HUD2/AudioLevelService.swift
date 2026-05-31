//
//  AudioLevelService.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//

import AVFoundation

final class AudioLevelService: NSObject, ObservableObject {
    private let engine = AVAudioEngine()
    @Published var dbFS: Double = -120.0  // 0 为满刻度，负值越小越安静

    func start() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try? session.setActive(true)

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let ch = buffer.floatChannelData?[0] else { return }
            let n = Int(buffer.frameLength)
            if n == 0 { return }
            var sum: Float = 0
            for i in 0..<n { let v = ch[i]; sum += v * v }
            let rms = sqrt(sum / Float(n))
            let db = 20.0 * log10(Double(max(rms, 1e-7))) // 防 -inf
            DispatchQueue.main.async { self?.dbFS = db }
        }

        do { try engine.start() } catch { print("❌ Audio engine start:", error) }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }
}
