//
//  MiniMapView.swift
//  HUD2
//
//  Created by apple on 2025/10/31.
//

import SwiftUI
import MapKit
import CoreLocation

struct MiniMapView: View {
    let center: CLLocationCoordinate2D?
    let track: [CLLocationCoordinate2D]
    let accuracy: CLLocationDistance?
    let side: CGFloat

    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $camera, interactionModes: []) {
            if let c = center {
                if let r = accuracy, r > 0 {
                    MapCircle(center: c, radius: r)
                        .foregroundStyle(.blue.opacity(0.12))
                    MapCircle(center: c, radius: max(2, r * 0.02))
                        .stroke(.blue.opacity(0.6), lineWidth: 1)
                } else {
                    MapCircle(center: c, radius: 3).foregroundStyle(.blue)
                }
            }
            if track.count > 1 {
                MapPolyline(coordinates: track)
                    .stroke(.blue.opacity(0.85), lineWidth: 2)
            }
        }
        .mapStyle(.standard)
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.9), lineWidth: 1))
        .shadow(radius: 2)
        .onAppear { updateCamera() }
        // 改为监听纬度/经度（可等值比较）
        .onChange(of: center?.latitude) { _, _ in updateCamera() }
        .onChange(of: center?.longitude) { _, _ in updateCamera() }
    }

    private func updateCamera() {
        guard let c = center else { return }
        let span = MKCoordinateSpan(latitudeDelta: 0.0045, longitudeDelta: 0.0045)
        camera = .region(.init(center: c, span: span))
    }
}
