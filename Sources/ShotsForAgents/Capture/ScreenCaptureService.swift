import AppKit
import ScreenCaptureKit

@MainActor
final class ScreenCaptureService {
    private static var overlayWindow: SelectionOverlayWindow?

    static func captureRegion() async -> Data? {
        // 1. Get available displays (triggers permission prompt if needed)
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: true
            )
        } catch {
            return nil
        }

        // Use the display under the mouse cursor, or fall back to first
        let mouseLocation = NSEvent.mouseLocation
        let display = content.displays.first { display in
            display.frame.contains(mouseLocation)
        } ?? content.displays.first

        guard let display else { return nil }

        // 2. Capture the full display (freeze frame)
        // Exclude our own overlay windows from the capture
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height

        guard let screenshot = try? await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        ) else {
            return nil
        }

        // 3. Show selection overlay on the frozen screenshot
        let selectedRect: CGRect? = await withCheckedContinuation { continuation in
            let window = SelectionOverlayWindow(
                screenshot: screenshot,
                displayFrame: display.frame
            ) { rect in
                continuation.resume(returning: rect)
                Self.overlayWindow?.close()
                Self.overlayWindow = nil
            }
            Self.overlayWindow = window
            window.show()
        }

        guard let rect = selectedRect, rect.width > 0, rect.height > 0 else {
            return nil
        }

        // 4. Crop to selection
        // View coordinates: origin bottom-left (AppKit)
        // CGImage coordinates: origin top-left
        let displayFrame = display.frame
        let scaleX = CGFloat(screenshot.width) / displayFrame.width
        let scaleY = CGFloat(screenshot.height) / displayFrame.height

        let cropRect = CGRect(
            x: rect.origin.x * scaleX,
            y: (displayFrame.height - rect.maxY) * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
        )

        guard let cropped = screenshot.cropping(to: cropRect) else { return nil }

        // 5. Convert to PNG
        let rep = NSBitmapImageRep(cgImage: cropped)
        return rep.representation(using: .png, properties: [:])
    }
}
