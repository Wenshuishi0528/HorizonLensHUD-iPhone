//
//  HUD2App.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//

import SwiftUI

@main
struct HUD2App: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

