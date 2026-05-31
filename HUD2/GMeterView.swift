//  GMeterView.swift
//  HUD2
//
//  显示纵/横向加速度（g），数值与小条形指示
//
import SwiftUI

struct GMeterView: View {
    let gLong: Double   // 纵向（前+、后-）
    let gLat: Double    // 横向（右+、左-）
    let fontScale: CGFloat

    private func clamp(_ v: Double, _ lim: Double = 2.0) -> Double {
        return max(-lim, min(lim, v))
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let barW = w * 0.64
            let barH = max(6, 8 * fontScale)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("G")
                        .font(.system(size: 12 * fontScale, weight: .bold, design: .rounded))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.thinMaterial, in: Capsule())

                    Spacer(minLength: 0)
                    Text(String(format: "Long %.2f", gLong))
                        .font(.system(size: 12 * fontScale, weight: .semibold))
                    Text(String(format: "Lat %.2f", gLat))
                        .font(.system(size: 12 * fontScale, weight: .semibold))
                }

                // Longitudinal bar
                ZStack(alignment: .leading) {
                    Capsule().fill(.ultraThinMaterial)
                        .frame(width: barW, height: barH)
                    let p = (clamp(gLong) + 2.0) / 4.0 // map [-2,2] -> [0,1]
                    Capsule().fill(.primary.opacity(0.9))
                        .frame(width: barW * p, height: barH)
                }

                // Lateral bar (centered, left negative / right positive)
                ZStack {
                    Capsule().fill(.ultraThinMaterial)
                        .frame(width: barW, height: barH)
                    let p = clamp(gLat)
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.clear).frame(width: barW/2, height: barH)
                        Rectangle().fill(Color.clear).frame(width: barW/2, height: barH)
                    }
                    HStack(spacing: 0) {
                        let left = p < 0 ? abs(p)/2.0 : 0.0
                        let right = p > 0 ? p/2.0 : 0.0
                        Rectangle().fill(.primary.opacity(0.9)).frame(width: barW * left, height: barH, alignment: .trailing)
                        Rectangle().fill(.primary.opacity(0.9)).frame(width: barW * right, height: barH, alignment: .leading)
                    }
                }
            }
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(width: 180 * fontScale, height: 90 * fontScale)
    }
}
