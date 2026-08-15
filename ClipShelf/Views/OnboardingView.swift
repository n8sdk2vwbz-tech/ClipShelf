import SwiftUI

struct OnboardingView: View {
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.accentColor)
                Text("Willkommen bei ClipShelf")
                    .font(.system(size: 17, weight: .semibold))
            }
            .padding(.top, 6)

            VStack(alignment: .leading, spacing: 16) {
                row(
                    icon: "doc.on.clipboard.fill",
                    tint: .blue,
                    title: "Verlauf öffnen",
                    text: "⌘⇧V oder Klick auf das Symbol in der Menüleiste zeigt alles, was du zuletzt kopiert hast."
                )
                row(
                    icon: "tray.full.fill",
                    tint: .orange,
                    title: "Ablage per Schütteln",
                    text: "Beim Ziehen einer Datei kurz die Maus hin und her schütteln – die Ablage erscheint direkt am Mauszeiger zum Ablegen."
                )
                row(
                    icon: "square.and.arrow.up",
                    tint: .green,
                    title: "Weiterreichen",
                    text: "Einträge lassen sich wieder herausziehen oder per Rechtsklick direkt über AirDrop senden."
                )
            }

            Button(action: onDismiss) {
                Text("Los geht's")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(width: 360)
    }

    private func row(icon: String, tint: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tint.opacity(0.15))
                .frame(width: 30, height: 30)
                .overlay(Image(systemName: icon).font(.system(size: 13)).foregroundStyle(tint))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                Text(text)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
