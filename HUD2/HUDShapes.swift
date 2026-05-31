//
//  HUDShapes.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//

import SwiftUI

// 小三角指示器（公共复用）
struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
