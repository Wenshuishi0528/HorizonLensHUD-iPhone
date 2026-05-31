import SwiftUI

struct PhotoButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "camera.circle.fill")
                .font(.system(size: 44, weight: .bold))
                .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Photo"))
    }
}
