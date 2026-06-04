import SwiftUI
import AppKit
import Combine

@MainActor
final class PasswordViewModel: ObservableObject {
    @Published var length: Double = Double(Config.defaultLength)
    @Published var useUppercase: Bool = Config.defaultUseUppercase
    @Published var useLowercase: Bool = Config.defaultUseLowercase
    @Published var useNumbers: Bool = Config.defaultUseNumbers
    @Published var useSymbols: Bool = Config.defaultUseSymbols

    @Published var password: String = ""
    @Published var copied: Bool = false

    /// When pinned, the window stays open (no auto-close on cursor leave).
    @Published var isPinned: Bool = false {
        didSet { onPinChanged?(isPinned) }
    }

    /// Notifies the app delegate when the pin state changes.
    var onPinChanged: ((Bool) -> Void)?

    /// Collapsed (window-shade) state toggled by the yellow traffic light.
    @Published var collapsed: Bool = false

    /// Asks the app delegate to resize the window after a layout change.
    var onMinimize: (() -> Void)?

    func toggleCollapse() {
        collapsed.toggle()
        onMinimize?()
    }

    private var lastPasteboardChangeCount: Int = NSPasteboard.general.changeCount
    private var clipboardTimer: Timer?

    var options: PasswordOptions {
        PasswordOptions(
            length: Int(length),
            useUppercase: useUppercase,
            useLowercase: useLowercase,
            useNumbers: useNumbers,
            useSymbols: useSymbols
        )
    }

    var strength: PasswordStrength {
        PasswordGenerator.strength(options)
    }

    init() {
        regenerate()
        startClipboardWatcher()
    }

    deinit {
        clipboardTimer?.invalidate()
    }

    /// Generates a new password. When `autoCopy` is nil the configured default
    /// (`Config.autoCopyOnGenerate`) is used.
    func regenerate(autoCopy: Bool? = nil) {
        guard options.hasAnySet else {
            password = ""
            copied = false
            return
        }
        password = PasswordGenerator.generate(options)
        copied = false

        if autoCopy ?? Config.autoCopyOnGenerate {
            copyToClipboard()
        }
    }

    /// Copies the current password if auto-copy is enabled. Used when the user
    /// releases the length slider, so we don't copy on every intermediate step.
    func autoCopyIfEnabled() {
        if Config.autoCopyOnGenerate {
            copyToClipboard()
        }
    }

    func copyToClipboard() {
        guard !password.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(password, forType: .string)
        lastPasteboardChangeCount = pb.changeCount
        copied = true
    }

    /// Detects when the user copies the password manually (e.g. select + Cmd+C)
    /// and flips the button into the "copied" state too.
    private func startClipboardWatcher() {
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }
    }

    private func checkClipboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastPasteboardChangeCount else { return }
        lastPasteboardChangeCount = pb.changeCount

        if let current = pb.string(forType: .string), current == password, !password.isEmpty {
            copied = true
        }
    }
}
