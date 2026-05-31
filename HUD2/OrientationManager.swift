import SwiftUI
import AVFoundation

/// 方向管理与映射工具
enum OrientationManager {
    /// 供 AVCaptureConnection.videoOrientation 使用
    static func avOrientation(for mode: OrientationSettings.LockMode) -> AVCaptureVideoOrientation {
        switch mode {
        case .free:
            // 让系统自己决定（这里选 .portrait 作为默认回退）
            return .portrait
        case .portrait:
            return .portrait
        case .landscape:
            // 统一采用 .landscapeRight，避免左右切换导致取景层抖动
            return .landscapeRight
        }
    }
    
    /// UI 叠加层需要的旋转角度（以“竖屏设计稿”为基准）
    static func uiRotation(for mode: OrientationSettings.LockMode) -> Angle {
        switch mode {
        case .free, .portrait:
            return .degrees(0)
        case .landscape:
            return .degrees(90)
        }
    }
    
    /// 横竖屏下的尺寸交换：横屏需要“宽高置换”来充满
    static func swappedSize(for mode: OrientationSettings.LockMode, size: CGSize) -> CGSize {
        switch mode {
        case .free, .portrait:
            return size
        case .landscape:
            return .init(width: size.height, height: size.width)
        }
    }
}