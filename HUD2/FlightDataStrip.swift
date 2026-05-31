//
//  FlightDataStrip.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//

import SwiftUI

struct FlightDataStrip: View {
    let speedMS: Double
    let altitudeMSL: Double
    let vsMS: Double
    let pressureHPA: Double
    let units: UnitSystem
    let lang: HUDLanguage
    let fontScale: CGFloat
    let speedMetricUnit: SpeedMetricUnit   // ← 新增
    
    private var spdValue: Double {
        switch units {
        case .metric:   return speedMS * (speedMetricUnit == .ms ? 1.0 : 3.6)
        case .imperial: return speedMS * 2.23694
        case .aviation: return speedMS * 1.94384
        }
    }
    private var spdUnit: String {
        switch units {
        case .metric:   return speedMetricUnit == .ms ? "m/s" : "km/h"
        case .imperial: return "mph"
        case .aviation: return "kt"
        }
    }
    private var vsValue: Double {
        switch units {
        case .metric:   return vsMS
        case .imperial, .aviation: return vsMS * 196.85039 // m/s → ft/min
        }
    }
    private var vsUnit: String { units == .metric ? "m/s" : "fpm" }

    var body: some View {
        HStack(spacing: 12) {
            datum(title: "SPD", value: String(format: "%.0f", max(0, spdValue)), unit: spdUnit)
            datum(title: "ALT", value: String(format: "%.0f", altitudeMSL), unit: units == .metric ? "m" : "ft")
            datum(title: "V/S", value: String(format: "%+.1f", vsValue), unit: vsUnit)
            datum(title: "PRES", value: String(format: "%.0f", pressureHPA), unit: "hPa")
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
        .font(.system(size: 14 * fontScale, weight: .semibold, design: .rounded))
    }

    private func datum(title: String, value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(title).opacity(0.8)
            HStack(spacing: 4) {
                Text(value).font(.system(size: 16 * fontScale, weight: .bold, design: .rounded))
                Text(unit).opacity(0.8)
            }
        }
        .frame(minWidth: 72, alignment: .center)
    }
}


