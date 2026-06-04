# Password Generator (macOS popup)

A tiny macOS popup app that, on launch, renders a small password‑generator
window **next to the cursor**. It auto‑closes when the cursor moves away from
the window. UI is styled after VS Code's dark theme.

## Features

- Pops up near the current cursor position, no dock icon (accessory app).
- Top‑to‑bottom layout: **character checkboxes → length slider → password + copy button**.
- Copy button switches to **"Copied to clipboard"** after you click it,
  *or* if you select the password and copy it manually (`⌘C`).
- Live regeneration when you change any option, plus a manual regenerate button.
- Strength indicator (Weak / Medium / Strong) based on entropy.
- Auto‑closes when the cursor moves farther than a configurable distance away.
- `Esc` also closes the window.

## Stack

Swift + SwiftUI + AppKit, built with Swift Package Manager. Native, lightweight,
and easy to maintain — no Electron / heavy runtime.

## Build & run

```bash
# Build a proper .app bundle
./build_app.sh release

# Launch it
open PassGenerator.app
```

Install / update the copy in `/Applications` (e.g. to bind it to a mouse
button in Logi Options+):

```bash
./install.sh          # builds and installs/updates /Applications/PassGenerator.app
```

Uninstall it:

```bash
./uninstall.sh          # remove the installed app
./uninstall.sh --clean  # also remove local build artifacts (.build, *.app)
```

During development you can also run the raw binary:

```bash
swift run -c release
```

> **Sharing the source is the easiest way to distribute this app.** When a user
> builds it locally it is ad‑hoc signed on their machine, so macOS Gatekeeper
> runs it without the "unverified developer" warning. Requirements: macOS 13+
> and the Xcode Command Line Tools (`xcode-select --install`).

> **Accessibility permission:** to detect the cursor leaving the window while it
> is over *other* apps, macOS requires Accessibility access for global mouse
> monitoring. On first run, grant it under
> *System Settings → Privacy & Security → Accessibility* and add `PassGenerator.app`.
> Without it, close‑on‑leave still works while the cursor is over the window's own
> app, and `Esc` always closes it.

## Configuration

All settings live in [`Sources/PassGenerator/Config.swift`](Sources/PassGenerator/Config.swift)
(in code, for now):

| Setting | Default | Description |
|---|---|---|
| `autoCopyOnGenerate` | `false` | Copy the password to the clipboard immediately on every generation. |
| `cursorLeaveDistance` | `120` | Distance (pts) the cursor must move from the window before it closes. |
| `defaultLength` | `12` | Initial slider value. |
| `minLength` / `maxLength` | `4` / `64` | Slider range. |
| `defaultUse*` | `true` | Which character sets start enabled. |

Set `autoCopyOnGenerate = true` to have the password copied automatically as
soon as it's generated.

## Project layout

```
Sources/PassGenerator/
  main.swift              # NSApplication entry point
  AppDelegate.swift       # Window placement, cursor-leave & key monitors
  PasswordPanel.swift     # Borderless floating NSPanel
  ContentView.swift       # SwiftUI UI (VS Code themed)
  PasswordViewModel.swift # State + clipboard watcher
  PasswordGenerator.swift # Generation + strength logic
  Theme.swift             # VS Code dark palette
  Config.swift            # Compile-time configuration
```
