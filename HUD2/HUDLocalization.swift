//
//  HUDLocalization.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//

import Foundation

// 简易“当前语言”供子视图调用（从 AppState 注入）
struct HUDLangProvider {
    static var current: HUDLangProvider = HUDLangProvider()
    let lang: HUDLanguage
    init(lang: HUDLanguage = .system) { self.lang = lang }
}

struct HUDStrings {
    // (标题, 数值格式化闭包, 单位)
    let spd: (String, (Double) -> String, String)
    let alt: (String, (Double) -> String, String)
    let vs:  (String, (Double) -> String, String)
    let pres:(String, (Double) -> String, String)

    static func make(language: HUDLangProvider) -> HUDStrings {
        // 选择语言：系统 -> 按 Locale
        let isZh: Bool = {
            switch language.lang {
            case .zh: return true
            case .en: return false
            case .system: return Locale.current.language.languageCode?.identifier == "zh"
            }
        }()
        let tSPD = isZh ? "速度" : "SPD"
        let tALT = isZh ? "高度" : "ALT"
        let tVS  = isZh ? "垂速" : "V/S"
        let tP   = isZh ? "气压" : "PRES"

        // 默认公制；实际单位由各视图决定，下面给 strip 提供公制的格式函数，也可改造为根据 UnitSystem 生成
        let spdFmt: (Double) -> String = { vMS in String(format: "%.0f", max(0, vMS * 3.6)) }
        let altFmt: (Double) -> String = { vM in String(format: "%.0f", vM) }
        let vsFmt:  (Double) -> String = { vMS in String(format: "%+.1f", vMS) }
        let pFmt:   (Double) -> String = { vHPA in String(format: "%.0f", vHPA) }

        return HUDStrings(
            spd: (tSPD, spdFmt, "km/h"),
            alt: (tALT, altFmt, "m"),
            vs:  (tVS,  vsFmt,  "m/s"),
            pres:(tP,   pFmt,   "hPa")
        )
    }
}
