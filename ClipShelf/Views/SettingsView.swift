import SwiftUI

struct SettingsView: View {
    @ObservedObject var monitor: ClipboardMonitor
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var maxItems: Double

    init(monitor: ClipboardMonitor) {
        self.monitor = monitor
        _maxItems = State(initialValue: Double(monitor.maxItems))
    }

    var body: some View {
        Form {
            Section {
                Toggle("Bei Anmeldung starten", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        LaunchAtLogin.setEnabled(newValue)
                    }
            }

            Section("Verlauf") {
                VStack(alignment: .leading) {
                    Text("Maximale Einträge: \(Int(maxItems))")
                        .font(.system(size: 12))
                    Slider(value: $maxItems, in: 50...1000, step: 50)
                        .onChange(of: maxItems) { newValue in
                            monitor.maxItems = Int(newValue)
                        }
                }

                Button("Zugriff für automatisches Einfügen erlauben…") {
                    PasteboardWriter.hasAccessibilityPermission(prompt: true)
                }
                Text("Nötig, damit ein Klick den Eintrag direkt in die aktive App einfügt (⌘V wird simuliert). Ohne diese Berechtigung wird nur kopiert.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 280)
    }
}
