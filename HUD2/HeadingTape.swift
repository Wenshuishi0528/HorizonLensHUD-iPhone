//
//  HeadingTape.swift
//  v60: 60 Hz redraw + no baseline + emphasized readout lower position
//
//  - Applies Head Zero Offset (0/±90/±180) via @AppStorage("headingZeroOffsetDeg")
//  - Window: ±20° (5° ticks), N/E/S/W at 0/90/180/270
//  - Uses TimelineView(.animation(minimumInterval: 1/60)) to refresh at ~60 Hz
//
import SwiftUI

struct HeadingTape: View {
    let heading: Double          // raw 0~360 from sensors
    let mode: String             // "T" / "M"

    @AppStorage("headingZeroOffsetDeg") private var headZeroOffsetDeg: Int = 0

    private let tickSpacing: CGFloat = 12    // px per 5°
    private let windowHalfSpanDeg: Int = 20
    private let height: CGFloat = 60         // more vertical room for highlighted number

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/60.0)) { _ in
            GeometryReader { geo in
                let centerX = geo.size.width / 2
                let adjusted = Self.wrap(heading + Double(headZeroOffsetDeg))   // ← apply zero-offset
                let base5 = Int(round(adjusted / 5.0)) * 5

                ZStack {
                    // ticks & labels (no long dashed baseline)
                    ForEach(Array(stride(from: -windowHalfSpanDeg, through: windowHalfSpanDeg, by: 5)), id: \.self) { off in
                        let deg = Self.wrap(Double(base5 + off))
                        let dx = CGFloat(off) / 5.0 * tickSpacing
                        let x = centerX + dx

                        if Int(deg) % 10 == 0 {       // major every 10°
                            Path { p in
                                p.move(to: CGPoint(x: x, y: 6))
                                p.addLine(to: CGPoint(x: x, y: 28))
                            }.stroke(lineWidth: 1.3)
                            Text(Self.label(for: Int(deg)))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .position(x: x, y: 30)
                        } else {                      // minor every 5°
                            Path { p in
                                p.move(to: CGPoint(x: x, y: 12))
                                p.addLine(to: CGPoint(x: x, y: 22))
                            }.stroke(lineWidth: 1.0)
                        }
                    }

                    // center caret (inline path, no Triangle type)
                    Path { p in
                        let w: CGFloat = 8, h: CGFloat = 6
                        let y: CGFloat = 4
                        p.move(to: CGPoint(x: centerX, y: y))
                        p.addLine(to: CGPoint(x: centerX + w/2, y: y + h))
                        p.addLine(to: CGPoint(x: centerX - w/2, y: y + h))
                        p.closeSubpath()
                    }
                    .fill(.primary)

                    // highlighted numeric readout — move further down and pop it
                    let display = Int(round(adjusted)) % 360
                    HStack(spacing: 6) {
                        Text("\(display)°")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text(mode)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
                    .shadow(radius: 1, y: 0.5)
                    .position(x: centerX, y: geo.size.height - 8)   // push further down
                }
            }
            .frame(height: height)
        }
        .accessibilityLabel("Heading \(Int(round(Self.wrap(heading + Double(headZeroOffsetDeg))))) degrees \(mode)")
    }

    private static func wrap(_ v: Double) -> Double {
        var x = v.truncatingRemainder(dividingBy: 360)
        if x < 0 { x += 360 }
        return x
    }
    private static func label(for v: Int) -> String {
        switch ((v % 360) + 360) % 360 {
        case 0: return "N"
        case 90: return "E"
        case 180: return "S"
        case 270: return "W"
        default: return "\(v)"
        }
    }
}
