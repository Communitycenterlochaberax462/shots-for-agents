# Shots for Agents

A Mac menu bar utility that turns screenshots into one-time localhost URLs you can paste into AI agents.

## The Problem

Working with AI agents means taking a lot of screenshots — sharing UI bugs, showing designs, pointing at errors on screen. Every one of those screenshots lands on your desktop or downloads folder and stays there forever. You end up with hundreds of temp screenshots that were only ever meant to be seen once by an AI.

macOS has no concept of a "temporary screenshot." Every capture is permanent until you manually clean it up.

## How It Works

Shots for Agents sits in your menu bar. Press a shortcut, select a region, and get a URL on your clipboard. Paste it into your AI agent. The screenshot self-destructs after the agent reads it. No file saved. No cleanup needed.

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌───────────┐
│  ⌃⇧S        │ ──▶ │  Select      │ ──▶ │  URL copied  │ ──▶ │  Agent    │
│  Shortcut   │     │  Region      │     │  to clipboard│     │  reads it │
└─────────────┘     └──────────────┘     └─────────────┘     └─────┬─────┘
                                                                    │
                                                              ┌─────▼─────┐
                                                              │  Gone.    │
                                                              │  410.     │
                                                              └───────────┘
```

1. **Capture** — Press `Ctrl+Shift+S`. The screen freezes and you drag to select a region.
2. **Serve** — The screenshot is held in memory and served at `http://localhost:9853/s/<id>.png`.
3. **Copy** — A curl command is copied to your clipboard, ready to paste into any AI agent.
4. **Expire** — After the agent reads it, the image stays available for 60 seconds (configurable), then deletes. Unread screenshots expire after 10 minutes.

Nothing is ever written to disk. When the app quits, everything is gone.

## Batch Capture

Need to share multiple screenshots? Just keep pressing the shortcut. Each capture adds to a batch and the clipboard updates automatically with a markdown table:

| Screenshot | Fetch |
|------------|-------|
| shot-1 | `curl -s -o /tmp/shot-A1B2C3D4.png http://localhost:9853/s/...` |
| shot-2 | `curl -s -o /tmp/shot-E5F6G7H8.png http://localhost:9853/s/...` |
| shot-3 | `curl -s -o /tmp/shot-I9J0K1L2.png http://localhost:9853/s/...` |

Paste the table into your agent and it fetches all screenshots at once. The batch auto-clears after 30 seconds of inactivity, or you can clear it from the menu bar. The menu bar icon shows the current batch count.

A single screenshot still copies just the curl command — no table overhead.

## Why curl instead of a URL?

AI agents (like Claude Code) can't fetch `localhost` URLs with their web tools. But they can run shell commands. So instead of copying a bare URL, Shots for Agents copies:

```
curl -s -o /tmp/shot-A1B2C3D4.png http://localhost:9853/s/A1B2C3D4-...-E5F6.png
```

The agent runs the curl, reads the downloaded file, and sees your screenshot. The temp file in `/tmp` is cleaned up by macOS automatically.

## Install

### From Source

Requires Xcode 16+ and macOS 14 (Sonoma) or later.

```bash
git clone https://github.com/Kalypsokichu-code/shots-for-agents.git
cd shots-for-agents
open ShotsForAgents.xcodeproj
```

Build and run from Xcode (`Cmd+R`).

### Generating the Xcode Project

If you modify `project.yml`, regenerate the Xcode project with:

```bash
brew install xcodegen  # if not installed
xcodegen generate
```

## Usage

1. Launch the app — a camera icon appears in your menu bar.
2. Press **Ctrl+Shift+S** (or click "Take Screenshot" in the menu).
3. First launch will ask for **Screen Recording** permission — grant it in System Settings.
4. Select a region on screen.
5. Paste the clipboard contents into your AI agent.
6. The agent fetches the screenshot. Done.

## Settings

Click the menu bar icon → **Settings** to configure:

| Setting | Default | Description |
|---|---|---|
| Capture shortcut | `Ctrl+Shift+S` | Global hotkey to trigger capture |
| Port | `9853` | Localhost port for the image server (restart to apply) |
| Unread expire | `10 min` | How long unread screenshots stay in memory |
| Keep after read | `60 sec` | How long screenshots persist after first fetch |
| Launch at login | Off | Start automatically on login |

## Architecture

- **ScreenCaptureKit** — Captures the display using Apple's native framework. Fully sandbox-compatible. Uses a freeze-and-select approach: captures the full screen, shows it as a frozen overlay, and lets you drag to select a region.
- **FlyingFox** — Lightweight async Swift HTTP server. Serves screenshots on localhost.
- **KeyboardShortcuts** — Global hotkey registration without requiring Accessibility permissions.
- **In-memory store** — Screenshots are never written to disk. An actor-based store handles concurrent access from the HTTP server and the main thread.

### App Sandbox

The app is sandboxed and ready for Mac App Store distribution. Entitlements:

- `com.apple.security.network.server` — Localhost HTTP server
- `com.apple.security.network.client` — Network client capability

The only system permission required is **Screen Recording**.

## Dependencies

| Package | Purpose |
|---|---|
| [FlyingFox](https://github.com/swhitty/FlyingFox) | Async HTTP server |
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | Global hotkey |

## License

MIT
