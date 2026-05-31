//  GCompositeView.swift
//  HUD2
//
//  仅显示综合加速度 |G| 的数值徽章
//
import SwiftUI

struct GCompositeView: View {
    let gTotal: Double
    let fontScale: CGFloat

    var body: some View {
        let value = max(0, gTotal)
        HStack(spacing: 6) {
            Text("|G|")
                .font(.system(size: 12 * fontScale, weight: .bold, design: .rounded))
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(.thinMaterial, in: Capsule())
            Text(String(format: "%.2f", value))
                .font(.system(size: 16 * fontScale, weight: .bold))
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
