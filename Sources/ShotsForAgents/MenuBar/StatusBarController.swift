import AppKit
import SwiftUI

struct CaptureEntry {
    let id: UUID
    let index: Int
    let rawData: Data
    var annotation: String?
    let thumbnail: NSImage
    let curl: String
}

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    var onCapture: (() -> Void)?
    var onClearBatch: (() -> Void)?
    var onSettings: (() -> Void)?
    var onRemoveCapture: ((UUID) -> Void)?
    var onEditAnnotation: ((UUID) -> Void)?
    private var captures: [CaptureEntry] = []

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "camera.viewfinder",
                accessibilityDescription: "Oneshot"
            )
        }
        rebuildMenu()
    }

    func updateCaptures(_ entries: [CaptureEntry]) {
        captures = entries

        if let button = statusItem.button {
            button.title = entries.isEmpty ? "" : " \(entries.count)"
        }
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.minimumWidth = 300

        let captureItem = NSMenuItem(
            title: "Take Screenshot",
            action: #selector(handleCapture),
            keyEquivalent: ""
        )
        captureItem.target = self
        menu.addItem(captureItem)

        if !captures.isEmpty {
            menu.addItem(NSMenuItem.separator())

            // Section header
            let header = NSMenuItem()
            let headerView = NSHostingView(rootView:
                Text("RECENT")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
            )
            headerView.frame.size = headerView.fittingSize
            header.view = headerView
            menu.addItem(header)

            // Capture rows
            for entry in captures {
                let item = NSMenuItem()
                let rowView = CaptureRowView(
                    thumbnail: entry.thumbnail,
                    index: entry.index,
                    annotation: entry.annotation,
                    onEdit: { [weak self] in
                        menu.cancelTracking()
                        self?.onEditAnnotation?(entry.id)
                    },
                    onRemove: { [weak self] in
                        menu.cancelTracking()
                        self?.onRemoveCapture?(entry.id)
                    }
                )
                let hostingView = NSHostingView(rootView: rowView)
                hostingView.frame.size = hostingView.fittingSize
                item.view = hostingView
                menu.addItem(item)
            }

            // Clear all
            let clearItem = NSMenuItem(
                title: "Clear All",
                action: #selector(handleClearBatch),
                keyEquivalent: ""
            )
            clearItem.target = self
            menu.addItem(clearItem)
        }

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(handleSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit Oneshot",
            action: #selector(handleQuit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func handleCapture() {
        onCapture?()
    }

    @objc private func handleClearBatch() {
        onClearBatch?()
    }

    @objc private func handleSettings() {
        onSettings?()
    }

    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Thumbnail Helper

    static func makeThumbnail(from data: Data, maxHeight: CGFloat = 32) -> NSImage {
        guard let image = NSImage(data: data) else { return NSImage() }
        let aspect = image.size.width / image.size.height
        let size = NSSize(width: maxHeight * aspect, height: maxHeight)
        let thumb = NSImage(size: size)
        thumb.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size),
                   from: .zero, operation: .copy, fraction: 1.0)
        thumb.unlockFocus()
        return thumb
    }
}

// MARK: - SwiftUI Menu Row

private struct CaptureRowView: View {
    let thumbnail: NSImage
    let index: Int
    let annotation: String?
    let onEdit: () -> Void
    let onRemove: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            // Fixed-size thumbnail, filled and clipped
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Shot \(index)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
                if let annotation, !annotation.isEmpty {
                    Text(annotation)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else {
                    Text("No annotation")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                }
            }

            Spacer()

            Divider()
                .frame(height: 20)

            Button(action: onEdit) {
                Text("Edit")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Edit annotation")

            Button(action: onRemove) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(hovering ? Color.white.opacity(0.05) : Color.clear)
        )
        .onHover { hovering = $0 }
    }
}
