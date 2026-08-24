import SwiftUI

/// Preferences window content. Stores only small, local preferences in
/// UserDefaults; note data stays in SwiftData and never leaves this Mac.
struct SettingsView: View {
    @AppStorage("showTimestamps") private var showTimestamps = false

    var body: some View {
        Form {
            Section("Notes") {
                Toggle("Show timestamps in the note list", isOn: $showTimestamps)
                    .accessibilityIdentifier("showTimestampsToggle")
                    .help("Display a relative timestamp next to each note.")
            }
            Section("About") {
                LabeledContent("Version", value: appVersion)
                    .accessibilityIdentifier("versionLabel")
                Text("Pocket Drafts keeps everything on this Mac. Import and export only touch files you pick.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 360)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
