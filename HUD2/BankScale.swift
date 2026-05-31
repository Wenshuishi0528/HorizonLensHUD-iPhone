//
//  BankScale.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//

import SwiftUI

struct BankScale: View {
    let roll: Double  // 横滚角（度）

    var body: some View {
        ZStack {
            BankArc()                               // 固定在屏幕上
                .stroke(style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                .opacity(0.95)

            // 指示三角形：随 roll 旋转
            Triangle()
                .frame(width: 12, height: 8)
                .rotationEffect(.degrees(roll))
                .offset(y: -46) // 放在弧线上
        }
        .frame(height: 120)
        .allowsHitTesting(false)
    }
}

private struct BankArc: Shape {
    // 画 ±60° 主刻度，±45/30/15 副刻度
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.maxY - 10)
        let radius: CGFloat = 70
        func pt(_ deg: CGFloat) -> CGPoint {
            let rad = (deg - 90) * .pi / 180
            return CGPoint(x: c.x + radius * cos(rad), y: c.y + radius * sin(rad))
        }
        // 弧
        p.addArc(center: c, radius: radius, startAngle: .degrees(240), endAngle: .degrees(-60), clockwise: true)
        // 刻度
        let majors: [CGFloat] = [-60,-30,0,30,60]
        let minors: [CGFloat] = [-45,-15,15,45]
        for a in majors {
            let o1 = pt(a); let o2 = CGPoint(x: o1.x, y: o1.y - 10)
            p.move(to: o1); p.addLine(to: o2)
        }
        for a in minors {
            let o1 = pt(a); let o2 = CGPoint(x: o1.x, y: o1.y - 6)
            p.move(to: o1); p.addLine(to: o2)
        }
        return p
    }
}

