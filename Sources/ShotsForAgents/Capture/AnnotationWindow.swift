import AppKit
import SwiftUI

@MainActor
final class AnnotationWindow: NSWindow {
    private let onComplete: (String?) -> Void
    private var didComplete = false
    nonisolated(unsafe) private var escMonitor: Any?

    init(anchorPoint: NSPoint, onComplete: @escaping (String?) -> Void) {
        self.onComplete = onComplete

        let width: CGFloat = 360
        let height: CGFloat = 120

        let frame = NSRect(
            x: anchorPoint.x - width / 2,
            y: anchorPoint.y - height - 12,
            width: width,
            height: height
        )

        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isReleasedWhenClosed = false

        let view = AnnotationView { [weak self] text in
            self?.complete(text)
        }
        contentView = NSHostingView(rootView: view)
    }

    func show() {
        makeKeyAndOrderFront(nil)
        NSApp.activate()

        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.complete(nil)
                return nil
            }
            return event
        }
    }

    override var canBecomeKey: Bool { true }

    private func complete(_ text: String?) {
        guard !didComplete else { return }
        didComplete = true
        if let monitor = escMonitor {
            NSEvent.removeMonitor(monitor)
            escMonitor = nil
        }
        close()
        onComplete(text)
    }

    deinit {
        let monitor = escMonitor
        MainActor.assumeIsolated {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
    }
}

private struct AnnotationView: View {
    let onComplete: (String?) -> Void
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "text.bubble")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Add a note")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                Spacer()
                Button("Skip", action: skip)
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Text field
            TextField("Describe what the AI should look at…", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($isFocused)
                .onSubmit(submit)
                .padding(.horizontal, 14)

            Spacer()

            // Footer hint
            HStack {
                Spacer()
                Text("return to confirm")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .frame(width: 360, height: 120)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        }
        .onAppear {
            isFocused = true
        }
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        onComplete(trimmed.isEmpty ? nil : trimmed)
    }

    private func skip() {
        onComplete(nil)
    }
}
