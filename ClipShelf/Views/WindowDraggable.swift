import SwiftUI

/// Makes the view it's attached to act as a window drag handle. Only signals drag
/// begin/changed/ended — the actual window move is left to the caller (typically a
/// WindowDragTracker), which reads absolute screen mouse coordinates rather than this
/// gesture's translation to avoid the flicker/jitter that comes from measuring movement
/// relative to the very window being repositioned.
struct WindowDraggable: ViewModifier {
    var onBegin: () -> Void = {}
    let onChanged: () -> Void
    var onEnded: () -> Void = {}

    @State private var isDragging = false

    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { _ in
                        if !isDragging {
                            isDragging = true
                            onBegin()
                        }
                        onChanged()
                    }
                    .onEnded { _ in
                        isDragging = false
                        onEnded()
                    }
            )
    }
}

extension View {
    func windowDraggable(onBegin: @escaping () -> Void = {}, onChanged: @escaping () -> Void, onEnded: @escaping () -> Void = {}) -> some View {
        modifier(WindowDraggable(onBegin: onBegin, onChanged: onChanged, onEnded: onEnded))
    }
}
