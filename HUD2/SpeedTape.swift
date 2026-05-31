//
//  SpeedTape.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//
import SwiftUI

struct SpeedTape: View {
    let speedMS: Double
    let isLandscape: Bool
    let units: UnitSystem
    let speedMetricUnit: SpeedMetricUnit   // ← 新增
    let fontScale: CGFloat

    private struct Spec { let factor: Double; let step: Double; let label: String }
    private var spec: Spec {
        switch units {
        case .metric:
                    if speedMetricUnit == .ms {
                        return .init(factor: 1.0, step: 2, label: "m/s")
                    } else {
                        return .init(factor: 3.6, step: 10, label: "km/h")
                    }
        case .imperial: return .init(factor: 2.23694, step: 10,  label: "mph")
        case .aviation: return .init(factor: 1.94384, step: 10,  label: "kt")
        }
    }

    var body: some View {
        let v = max(0, speedMS * spec.factor)
        let s = strings()
        tape(value: v,
             step: spec.step,
             label: s.spd.0,                  // ← 只传标题（String）
             unit: spec.label)
        .frame(width: isLandscape ? 80 : 60,
               height: (isLandscape ? 180 : 280) * fontScale)
    }

    private func tape(value: Double, step: Double, label: String, unit: String) -> some View {
        GeometryReader { geo in
            let size = geo.size
            let centerY = size.height/2
            let pxPerStep: CGFloat = 10 * fontScale
            let base   = (value/step).rounded(.towardZero)
            let range  = -15...15

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial)

                ForEach(range, id: \.self) { i in
                    let val = (base + Double(i)) * step
                    let dy  = CGFloat(-Double(i)) * pxPerStep
                    if abs(dy) < size.height/2 + 20 {
                        Path { p in
                            let tickStart: CGFloat = 10
                            let tickEndOrig: CGFloat = size.width - 54
                            let tickEnd: CGFloat = tickStart + (tickEndOrig - tickStart) * 0.5
                            p.move(to: CGPoint(x: tickStart, y: centerY + dy))
                            p.addLine(to: CGPoint(x: tickEnd, y: centerY + dy))
                        }.stroke(lineWidth: (Int(val) % Int(step*5) == 0) ? 2 : 1)

                        if Int(val) % Int(step*2) == 0 {
                            Text("\(Int(val))")
                                .font(.system(size: 12 * fontScale, weight: .semibold))
                                .position(x: min((10 + (size.width - 54 - 10) * 0.5) + 14, size.width - 12), y: centerY + dy)
                        }
                    }
                }

                // 中央读数窗
                HStack(spacing: 8) {
                    VStack(spacing: 2) {
                        Text(label)
                        Text(unit)
                    }
                    .font(.system(size: 10 * fontScale, weight: .semibold))
                    .opacity(0.85)
                    Text("\(Int(round(value)))")
                        .font(.system(size: 18 * fontScale, weight: .bold))
                }
                .padding(6)
                .background(.thinMaterial, in: Capsule())
                .position(x: size.width/2, y: centerY)
            }
        }
    }

    private func strings() -> HUDStrings { HUDStrings.make(language: HUDLangProvider.current) }
}
