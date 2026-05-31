//
//  AttitudeIndicator.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//

import SwiftUI

/// 人工地平线：俯仰上正下负；整块围绕屏幕中心随横滚旋转
struct AttitudeIndicator: View {
    @EnvironmentObject var appState: AppState
    let pitch: Double     // deg，上正下负
    let roll: Double      // deg，右正左负

    // 可按需要微调
    private let pxPerDeg: CGFloat = 4.0          // 每 1° 的像素位移
    private let baseTickLen: CGFloat = 60        // 普通刻度半长（左右各一半）
    private let majorEvery: Int = 10             // 每 10° 一条主刻度
    private let visibleRange: ClosedRange<Int> = -90...90
    private let labelPad: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let center = CGPoint(x: size.width/2, y: size.height/2)

            ZStack {
                // 中心水平虚线（跟随横滚旋转，但不受俯仰平移影响）
                Path { p in
                    p.move(to: CGPoint(x: 0, y: center.y))
                    p.addLine(to: CGPoint(x: size.width, y: center.y))
                }
                .stroke(
                    style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [6, 6])
                )
                .foregroundStyle(.white.opacity(0.9))
                .rotationEffect(.degrees(roll), anchor: .center)

                // 俯仰刻度梯（整体先随俯仰上下，再整体随横滚旋转）
                pitchLadder(in: size)
                    .rotationEffect(.degrees(roll), anchor: .center)
            }
        }
    }

    @ViewBuilder
    private func pitchLadder(in size: CGSize) -> some View {
        let centerY = size.height/2
        Canvas { ctx, sz in
            for deg in stride(from: visibleRange.lowerBound, through: visibleRange.upperBound, by: 5) {
                let y = centerY - CGFloat(deg) * pxPerDeg - CGFloat(pitch) * pxPerDeg
                if y < -30 || y > sz.height + 30 { continue }

                let isMajor = deg % majorEvery == 0
                let isZero  = deg == 0

                // 0° → 1.5×长度，2×粗细
                let len: CGFloat = isZero ? baseTickLen * 1.5 : (isMajor ? baseTickLen : baseTickLen * 0.6)
                let lw: CGFloat  = isZero ? 2.4 : (isMajor ? 1.6 : 1.0)

                var path = Path()
                let xL1 = sz.width/2 - len, xL2 = sz.width/2 - (isMajor ? len*0.55 : len*0.75)
                let xR1 = sz.width/2 + len, xR2 = sz.width/2 + (isMajor ? len*0.55 : len*0.75)
                path.move(to: CGPoint(x: xL1, y: y)); path.addLine(to: CGPoint(x: xL2, y: y))
                path.move(to: CGPoint(x: xR2, y: y)); path.addLine(to: CGPoint(x: xR1, y: y))
                ctx.stroke(path, with: .color(appState.hudTint.opacity(0.95)), lineWidth: lw)

                if isMajor && !isZero {
                    let txt = Text("\(abs(deg))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(appState.hudTint)
                    ctx.draw(txt, at: CGPoint(x: xL1 - labelPad, y: y))
                    ctx.draw(txt, at: CGPoint(x: xR1 + labelPad, y: y))
                }
            }
        }
    }
}






