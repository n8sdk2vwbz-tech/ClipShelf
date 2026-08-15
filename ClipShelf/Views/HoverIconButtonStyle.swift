import SwiftUI

/// Small round icon button with a soft hover/press background — used for every toolbar
/// and per-row icon action so they read as one consistent, tactile control language.
struct HoverIconButtonStyle: ButtonStyle {
    var size: CGFloat = 22
    var tint: Color = .secondary

    func makeBody(configuration: Configuration) -> some View {
        HoverIconButtonBody(configuration: configuration, size: size, tint: tint)
    }
}

private struct HoverIconButtonBody: View {
    let configuration: HoverIconButtonStyle.Configuration
    let size: CGFloat
    let tint: Color
    @State private var isHovering = false

    var body: some View {
        configuration.label
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(Circle().fill(isHovering ? tint.opacity(0.15) : Color.clear))
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: isHovering)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
            .onHover { isHovering = $0 }
    }
}

extension ButtonStyle where Self == HoverIconButtonStyle {
    static var hoverIcon: HoverIconButtonStyle { HoverIconButtonStyle() }
    static func hoverIcon(tint: Color) -> HoverIconButtonStyle { HoverIconButtonStyle(tint: tint) }
}
