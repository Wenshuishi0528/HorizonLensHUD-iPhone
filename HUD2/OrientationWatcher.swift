//
//  OrientationWatcher.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//

import SwiftUI
import UIKit
import Combine

final class OrientationWatcher: ObservableObject {
    @Published var isLandscape: Bool = false
    private var sub: AnyCancellable?

    init() {
        isLandscape = OrientationWatcher.currentIsLandscape()
        sub = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .receive(on: RunLoop.main)
            .sink { _ in self.isLandscape = OrientationWatcher.currentIsLandscape() }
    }

    private static func currentIsLandscape() -> Bool {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return false }
        return scene.interfaceOrientation.isLandscape
    }
}

