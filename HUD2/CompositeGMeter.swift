//
//  CompositeGMeter.swift
//  Single-value |G| meter (fighter-jet style).
//  - Shows magnitude of userAcceleration (|a|) in G units.
//  - 60 Hz deviceMotion sampling with EMA smoothing; UI publishes throttled to 15 Hz to avoid jank.
//  - Draggable position persisted via @AppStorage("gCompositePosX"/"gCompositePosY").
//  - Visibility and dragging enabled by @AppStorage("showGComposite") / @AppStorage("gCompositeAllowDrag").
//
import SwiftUI
import CoreMotion

@MainActor
final class CompositeGMeterModel: ObservableObject {
    @Published var g: Double = 0.0

    private let mgr = CMMotionManager()
    private let queue = OperationQueue()

    // smoothing & throttle
    private var lastSmoothed: Double = 0.0
    private let alpha: Double = 0.25
    private var lastPublish: CFTimeInterval = 0
    private let publishInterval: CFTimeInterval = 1.0/15.0   // 15 Hz to UI

    func start() {
        guard mgr.isDeviceMotionAvailable else { return }
        mgr.deviceMotionUpdateInterval = 1.0 / 60.0
        mgr.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] dm, _ in
            guard let self, let dm = dm else { return }
            // userAcceleration already excludes gravity; units ~ g
            let ax = dm.userAcceleration.x, ay = dm.userAcceleration.y, az = dm.userAcceleration.z
            var mag = sqrt(ax*ax + ay*ay + az*az)
            if !mag.isFinite { mag = 0 }

            let smoothed = self.alpha * mag + (1 - self.alpha) * self.lastSmoothed
            self.lastSmoothed = smoothed

            let now = CACurrentMediaTime()
            if now - self.lastPublish >= self.publishInterval {
                self.lastPublish = now
                let q = (smoothed * 100).rounded() / 100.0   // quantize to 0.01G
                Task { @MainActor in self.g = q }
            }
        }
    }

    func stop() { mgr.stopDeviceMotionUpdates() }
}

public struct GMeterBadge: View {
    @StateObject private var model = CompositeGMeterModel()

    public init() {}

    public var body: some View {
        Text(String(format: "│G│ %.2f", model.g))
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .monospacedDigit()
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
            .shadow(radius: 1, y: 0.5)
            .allowsHitTesting(false)
            .onAppear { model.start() }
            .onDisappear { model.stop() }
            .accessibilityLabel("综合G值")
    }
}

// Draggable wrapper with persisted position; reads toggles from @AppStorage
public struct GMeterOverlay: View {
    @AppStorage("showGComposite") private var show = false
    @AppStorage("gCompositeAllowDrag") private var allowDrag = false
    @AppStorage("gCompositePosX") private var posX: Double = 80
    @AppStorage("gCompositePosY") private var posY: Double = 80

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if show {
                    GMeterBadge()
                        .position(x: clamp(CGFloat(posX), 40, max(40, geo.size.width-40)),
                                  y: clamp(CGFloat(posY), 20, max(20, geo.size.height-20)))
                        .gesture(allowDrag ? dragGesture(in: geo.size) : nil)
                }
            }
            .ignoresSafeArea()
        }
    }

    private func clamp(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat { min(hi, max(lo, v)) }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                posX = Double(clamp(value.location.x, 40, max(40, size.width-40)))
                posY = Double(clamp(value.location.y, 20, max(20, size.height-20)))
            }
    }
}
