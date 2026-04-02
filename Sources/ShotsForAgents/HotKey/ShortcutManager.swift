import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let captureScreenshot = Self(
        "captureScreenshot",
        default: .init(.s, modifiers: [.control, .shift])
    )
}
