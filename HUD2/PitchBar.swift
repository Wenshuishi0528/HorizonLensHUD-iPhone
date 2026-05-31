import SwiftUI

struct PitchBar: View {
    let pitchDeg: Double
    let fontScale: CGFloat
    private func clamp(_ v: Double, _ lim: Double = 45) -> Double { max(-lim, min(lim, v)) }
    var body: some View {
        VStack(spacing: 6) {
            Text(String(format: "PITCH %.0f°", pitchDeg)).font(.system(size: 12*fontScale, weight: .bold)).padding(.horizontal,6).padding(.vertical,2).background(.thinMaterial, in: Capsule())
            GeometryReader { geo in
                let h = geo.size.height
                let w = geo.size.width
                let lim: Double = 45
                let p = clamp(pitchDeg, lim)
                let frac = (p + lim) / (2*lim)
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 6).fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 6).fill(.primary.opacity(0.9)).frame(height: h * frac).animation(.easeOut(duration: 0.12), value: frac)
                    Rectangle().fill(.primary.opacity(0.2)).frame(height: 1).position(x: w/2, y: h/2)
                }
            }.frame(width: 20*fontScale, height: 140*fontScale)
        }.padding(8).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
