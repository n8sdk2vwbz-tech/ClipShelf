import SwiftUI

@main
struct ClipShelfApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // No real window: ClipShelf lives entirely in the status item + floating panels.
        // A Settings scene is the minimal Scene SwiftUI's App protocol requires.
        Settings {
            EmptyView()
        }
    }
}
