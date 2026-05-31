import Foundation
import Combine

/// 屏幕方向设置（独立于项目原有 AppSettings，避免冲突）
final class OrientationSettings: ObservableObject {
    enum LockMode: String, CaseIterable, Identifiable {
        case free        // 跟随系统（不锁定）
        case portrait    // 竖屏固定
        case landscape   // 横屏固定（允许左右）
        
        var id: String { rawValue }
        var localizedTitle: String {
            switch self {
            case .free: return "跟随系统"
            case .portrait: return "竖屏固定"
            case .landscape: return "横屏固定"
            }
        }
    }
    
    @Published var lockMode: LockMode {
        didSet { Self.persist(lockMode) }
    }
    
    private static let storageKey = "orientation.lockMode.v1"
    
    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let m = LockMode(rawValue: raw) {
            self.lockMode = m
        } else {
            self.lockMode = .free
        }
    }
    
    private static func persist(_ mode: LockMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: storageKey)
    }
}