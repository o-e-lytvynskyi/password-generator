import Foundation
import CoreGraphics

/// Compile-time configuration for the extension.
///
/// For now everything is configured here in code, as requested.
/// Later this can be backed by `UserDefaults` or a settings UI.
enum Config {
    /// Copy the generated password to the clipboard immediately on every
    /// generation, without requiring a click on the "Copy" button.
    static let autoCopyOnGenerate: Bool = true

    /// Quit the app when the cursor moves farther than this many points
    /// away from the window's frame.
    static let cursorLeaveDistance: CGFloat = 120

    // MARK: Password defaults

    static let defaultLength: Int = 12
    static let minLength: Int = 4
    static let maxLength: Int = 64

    static let defaultUseUppercase: Bool = true
    static let defaultUseLowercase: Bool = true
    static let defaultUseNumbers: Bool = true
    static let defaultUseSymbols: Bool = true
}
