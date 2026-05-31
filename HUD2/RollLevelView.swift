//
//  RollLevelView.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//

import SwiftUI

/// 横滚水平仪（类似飞机“球”）：根据 rollDeg 在胶囊槽内左右移动
struct RollLevelView: View {
    @EnvironmentObject var appState: AppState
    let rollDeg: Double          // 横滚角（deg，右正左负）
    let scale: CGFloat           // 跟随字号缩放

    // 参数可调
    private var width: CGFloat { 200 * scale }
    private var height: CGFloat { 28 * scale }
    private var padding: CGFloat { 6 * scale }
    private var ballSize: CGFloat { 16 * scale }

    var body: some View {
        ZStack {
            // 槽体
            Capsule()
                .fill(.ultraThinMaterial)
                .frame(width: width, height: height)
                .overlay(Capsule().stroke(appState.hudTint.opacity(0.9), lineWidth: 1))

            // 中央刻线
            Rectangle()
                .fill(appState.hudTint.opacity(0.9))
                .frame(width: 2, height: height - 8)

            // 两侧刻线（±30°）
            HStack {
                Rectangle().fill(appState.hudTint.opacity(0.7)).frame(width: 1, height: height - 12)
                Spacer()
                Rectangle().fill(appState.hudTint.opacity(0.7)).frame(width: 1, height: height - 12)
            }
            .padding(.horizontal, width * 0.25)

            // 小球（随横滚角移动；±30°饱和）
            Circle()
                .fill(appState.hudTint)
                .frame(width: ballSize, height: ballSize)
                .shadow(radius: 1.5)
                .offset(x: ballOffsetX(), y: 0)
                .animation(.easeOut(duration: 0.12), value: rollDeg)
        }
        .frame(width: width, height: height)
    }

    // 将 roll 映射为 [-1, 1] 再映射为水平偏移
    private func ballOffsetX() -> CGFloat {
        let clampRoll = max(-30, min(30, rollDeg))
        let t = clampRoll / 30.0               // -1…1
        let usable = (width/2 - padding - ballSize/2)
        return CGFloat(t) * usable
    }
}
