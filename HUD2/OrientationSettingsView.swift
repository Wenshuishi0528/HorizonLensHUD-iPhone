import SwiftUI

/// “设置 → 屏幕方向”页面（可从任意设置入口或按钮打开）
struct OrientationSettingsView: View {
    @ObservedObject var settings: OrientationSettings
    
    var body: some View {
        Form {
            Section {
                Picker("固定屏幕方向", selection: $settings.lockMode) {
                    ForEach(OrientationSettings.LockMode.allCases) { mode in
                        Text(mode.localizedTitle).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 6)
                
                Text(tipText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            } header: {
                Text("屏幕方向")
            } footer: {
                Text("横屏固定时，UI 与相机都会以横屏（向右）显示。竖屏固定时，强制竖屏显示。跟随系统时，不做额外旋转。")
            }
        }
        .navigationTitle("屏幕方向")
    }
    
    private var tipText: String {
        switch settings.lockMode {
        case .free: return "当前：跟随系统"
        case .portrait: return "当前：竖屏固定"
        case .landscape: return "当前：横屏固定（统一为向右）"
        }
    }
}