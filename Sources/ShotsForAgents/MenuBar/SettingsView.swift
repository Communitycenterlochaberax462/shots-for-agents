import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @AppStorage("serverPort") private var port = Constants.defaultPort
    @AppStorage("ttlMinutes") private var ttlMinutes = Constants.defaultTTLMinutes
    @AppStorage("readWindowSeconds") private var readWindowSeconds = Constants.defaultReadWindowSeconds
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    @State private var portText = ""
    @State private var portChanged = false

    private let version = Bundle.main.object(
        forInfoDictionaryKey: "CFBundleShortVersionString"
    ) as? String ?? "—"

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Shortcut") {
                    LabeledContent("Capture") {
                        KeyboardShortcuts.Recorder(for: .captureScreenshot)
                            .fixedSize()
                    }
                }

                Section("Server") {
                    LabeledContent("Port") {
                        HStack(spacing: 6) {
                            TextField("", text: $portText)
                                .frame(width: 52)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .multilineTextAlignment(.trailing)
                                .onSubmit { applyPort() }
                                .onChange(of: portText) { _, newValue in
                                    portChanged = (Int(newValue) ?? port) != port
                                }
                            if portChanged {
                                Text("restart to apply")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    Picker("Unread expire", selection: $ttlMinutes) {
                        Text("1 min").tag(1)
                        Text("2 min").tag(2)
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                        Text("30 min").tag(30)
                    }

                    Picker("Keep after read", selection: $readWindowSeconds) {
                        Text("30 sec").tag(30)
                        Text("1 min").tag(60)
                        Text("2 min").tag(120)
                        Text("5 min").tag(300)
                    }
                }

                Section {
                    Toggle("Launch at login", isOn: $launchAtLogin)
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)

            HStack {
                Text("Shots for Agents v\(version)")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .frame(width: 360)
        .onAppear { portText = "\(port)" }
    }

    private func applyPort() {
        guard let newPort = Int(portText), (1024...65535).contains(newPort) else {
            portText = "\(port)"
            return
        }
        port = newPort
    }
}
