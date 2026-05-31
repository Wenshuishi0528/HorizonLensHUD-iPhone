//
//  VSTape.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//
import SwiftUI

struct VSTape: View {
    let vsMS: Double
    let isLandscape: Bool
    let units: UnitSystem
    let fontScale: CGFloat

    private struct Spec { let factor: Double; let step: Double; let label: String; let maxAbs: Double }
    private var spec: Spec {
        switch units {
        case .metric:   return .init(factor: 1.0,     step: 1,   label: "m/s",  maxAbs: 10)
        case .imperial: return .init(factor: 196.8504, step: 200, label: "fpm", maxAbs: 2000)
        case .aviation: return .init(factor: 196.8504, step: 200, label: "fpm", maxAbs: 2000)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let centerY = size.height/2
            let pxPerStep: CGFloat = 16 * fontScale
            let value = vsMS * spec.factor
            let clampV = max(-spec.maxAbs, min(spec.maxAbs, value))

            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial)

                // 刻度
                let steps = Int((spec.maxAbs/spec.step).rounded(.up))
                ForEach(-steps...steps, id: \.self) { i in
                    let val = Double(i) * spec.step
                    let dy = CGFloat(-val/spec.step) * pxPerStep
                    if abs(dy) < size.height/2 - 6 {
                        Path { p in
                            p.move(to: CGPoint(x: size.width*0.25, y: centerY + dy))
                            p.addLine(to: CGPoint(x: size.width*0.75, y: centerY + dy))
                        }.stroke(lineWidth: (i % 5 == 0 ? 2 : 1))
                        if i % 2 == 0 {
                            Text("\(Int(val))")
                                .font(.system(size: 10 * fontScale, weight: .semibold))
                                .position(x: size.width - 12, y: centerY + dy)
                        }
                    }
                }

                // 指示菱形 + 数字
                let dy = CGFloat(-clampV/spec.step) * pxPerStep
                Diamond().stroke(lineWidth: 2)
                    .frame(width: 16 * fontScale, height: 16 * fontScale)
                    .position(x: size.width/2, y: centerY + dy)

                Text(String(format: "%+.1f %@", value, spec.label))
                    .font(.system(size: 12 * fontScale, weight: .semibold))
                    .position(x: size.width/2, y: centerY - 18 * fontScale)
            }
        }
        .frame(width: isLandscape ? 64 : 64, height: (isLandscape ? 180 : 280) * fontScale)
    }
}

private struct Diamond: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}
