# Oneshot

![Oneshot](social.jpg)

Share screenshots with AI agents without pasting base64 walls into chat.

Oneshot is a Mac menu bar app that gives [Claude Code](https://docs.anthropic.com/en/docs/claude-code), [Cursor](https://www.cursor.com/), [GitHub Copilot](https://github.com/features/copilot), and other AI coding agents a way to see your screen. Screenshot a region, paste the command into chat, and the agent reads it. Then it's gone.

[oneshot.zip](https://oneshot.zip)

---

## Why Oneshot?

AI agents can run shell commands, but they can't see your screen. The usual workaround — encoding a screenshot as base64 and pasting it into chat — wastes tokens and bloats context. It gets worse when you need to share more than one image.

Oneshot replaces that with a tiny `curl` command. You screenshot a region, a command lands on your clipboard, and the agent fetches the image from a local server on your machine. After it's read, the screenshot deletes itself. Nothing is ever saved to disk.

---

## Install

### Mac App Store

Oneshot is currently in App Store review. A download link will appear here once it's approved.

### Build from Source

You'll need a Mac running **macOS 14 Sonoma** or later, with **Xcode 16+** installed.

```bash
git clone https://github.com/Kalypsokichu-code/shots-for-agents.git
cd shots-for-agents
open ShotsForAgents.xcodeproj
```

Press **Cmd + R** in Xcode to build and run.

On first launch, macOS will prompt for **Screen Recording** permission. Grant it in **System Settings > Privacy & Security > Screen Recording**.

<details>
<summary>Regenerating the Xcode project</summary>

If you modify `project.yml`, regenerate the project file:

```bash
brew install xcodegen  # if not already installed
xcodegen generate
```

</details>

---

## Batch Mode

Keep pressing **Ctrl + Shift + S** to capture additional regions. Each capture adds to a batch, and your clipboard updates with a markdown table:

| Screenshot | Fetch |
|------------|-------|
| shot-1 | `curl -s -o /tmp/shot-A1B2C3D4.png http://localhost:9853/s/...` |
| shot-2 | `curl -s -o /tmp/shot-E5F6G7H8.png http://localhost:9853/s/...` |
| shot-3 | `curl -s -o /tmp/shot-I9J0K1L2.png http://localhost:9853/s/...` |

Paste the table once and the agent fetches every image.

The batch clears after 30 seconds of inactivity. You can also manage it from the menu bar icon, where you can preview thumbnails, edit annotations, remove individual shots, or see which ones have been read vs. still pending.

---

## How It Works Under the Hood

- **ScreenCaptureKit** captures the full display, freezes it as an overlay, and lets you drag to select a region.
- **FlyingFox** runs a lightweight async HTTP server on localhost to serve screenshots.
- **KeyboardShortcuts** registers the global hotkey without requiring Accessibility permissions.
- An **actor-based in-memory store** holds screenshots. Nothing touches disk. Concurrent access is handled safely.

The only macOS permission required is **Screen Recording**.

### Dependencies

| Package | Role |
|---------|------|
| [FlyingFox](https://github.com/swhitty/FlyingFox) | Async HTTP server |
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | Global hotkey registration |

---

## License

MIT
