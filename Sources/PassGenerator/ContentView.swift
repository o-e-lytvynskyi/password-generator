import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var vm: PasswordViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if !vm.collapsed {
                charactersRow
                lengthRow
                Divider().overlay(Theme.border)
                passwordRow
            }
        }
        .padding(16)
        .frame(width: 360)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.windowBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.border.opacity(0.6), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.18), value: vm.isPinned)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            if vm.isPinned {
                TrafficLights(
                    onClose: { NSApp.terminate(nil) },
                    onMinimize: { vm.toggleCollapse() }
                )
                .padding(.trailing, 2)
                .transition(.opacity)
            }
            Image(systemName: "key.fill")
                .foregroundColor(Theme.accentHover)
            Text("Password Generator")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            strengthBadge
            pinButton
        }
    }

    private var pinButton: some View {
        Button(action: { vm.isPinned.toggle() }) {
            Image(systemName: vm.isPinned ? "pin.fill" : "pin")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(vm.isPinned ? Theme.accentHover : Theme.textSecondary)
                .frame(width: 24, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(vm.isPinned ? Theme.accent.opacity(0.18) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(vm.isPinned ? "Unpin (auto-close on cursor leave)" : "Pin (keep window open, always on top)")
    }

    private var strengthBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Theme.strengthColor(vm.strength))
                .frame(width: 7, height: 7)
            Text(vm.strength.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.textSecondary)
        }
        .animation(.easeInOut(duration: 0.2), value: vm.strength)
    }

    // MARK: Characters

    private var charactersRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CHARACTERS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            HStack(spacing: 14) {
                CheckboxView(title: "Aa", isOn: $vm.useUppercase)
                CheckboxView(title: "aa", isOn: $vm.useLowercase)
                CheckboxView(title: "123", isOn: $vm.useNumbers)
                CheckboxView(title: "#$&", isOn: $vm.useSymbols)
            }
        }
        .onChange(of: vm.useUppercase) { _ in vm.regenerate() }
        .onChange(of: vm.useLowercase) { _ in vm.regenerate() }
        .onChange(of: vm.useNumbers) { _ in vm.regenerate() }
        .onChange(of: vm.useSymbols) { _ in vm.regenerate() }
    }

    // MARK: Length slider

    private var lengthRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("LENGTH")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text("\(Int(vm.length))")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
            }
            Slider(
                value: $vm.length,
                in: Double(Config.minLength)...Double(Config.maxLength),
                step: 1,
                onEditingChanged: { editing in
                    // Copy only once the knob is released.
                    if !editing { vm.autoCopyIfEnabled() }
                }
            )
            .tint(Theme.accent)
            // While dragging, regenerate but don't copy (copy happens on release).
            .onChange(of: vm.length) { _ in vm.regenerate(autoCopy: false) }
        }
    }

    // MARK: Password + copy

    private var passwordRow: some View {
        HStack(spacing: 8) {
            Group {
                if vm.password.isEmpty {
                    Text("Select a character set")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    // Native selectable label: truncates with a trailing "…"
                    // so a long password never spills past the window, yet a
                    // full select-all still copies the entire password.
                    SelectablePasswordField(text: vm.password)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.inputBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )

            Button(action: { vm.regenerate() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(IconButtonStyle())
            .help("Regenerate")

            CopyButton(copied: vm.copied) {
                vm.copyToClipboard()
            }
        }
    }
}

// MARK: - Traffic lights (native-style window buttons)

struct TrafficLights: View {
    let onClose: () -> Void
    let onMinimize: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 8) {
            light(color: Color(hex: 0xFF5F57), symbol: "xmark", action: onClose, help: "Close")
            light(color: Color(hex: 0xFEBC2E), symbol: "minus", action: onMinimize, help: "Minimize")
        }
        .onHover { hovering = $0 }
    }

    private func light(color: Color, symbol: String, action: @escaping () -> Void, help: String) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 0.5))
                Image(systemName: symbol)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.black.opacity(0.55))
                    .opacity(hovering ? 1 : 0)
            }
            .frame(width: 12, height: 12)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .help(help)
    }
}

// MARK: - Selectable password label

struct SelectablePasswordField: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSTextField {
        let tf = NSTextField(labelWithString: text)
        tf.isSelectable = true
        tf.isEditable = false
        tf.isBordered = false
        tf.drawsBackground = false
        tf.usesSingleLineMode = true
        tf.maximumNumberOfLines = 1
        tf.lineBreakMode = .byTruncatingTail
        tf.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        tf.textColor = NSColor(srgbRed: 0xCC / 255, green: 0xCC / 255, blue: 0xCC / 255, alpha: 1)
        tf.allowsDefaultTighteningForTruncation = false
        if let cell = tf.cell as? NSTextFieldCell {
            cell.lineBreakMode = .byTruncatingTail
            cell.truncatesLastVisibleLine = true
            cell.usesSingleLineMode = true
            cell.wraps = false
            // Don't scroll the field editor on selection — keep it truncated.
            cell.isScrollable = false
        }
        // Let SwiftUI drive the width so the text truncates instead of overflowing.
        tf.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return tf
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        guard nsView.stringValue != text else { return }
        // If the user had selected the old value, the field is using its field
        // editor (which shows the full, untruncated text). Resign it so the new
        // password renders truncated with a trailing "…" again.
        if nsView.currentEditor() != nil {
            nsView.window?.makeFirstResponder(nil)
        }
        nsView.stringValue = text
        nsView.lineBreakMode = .byTruncatingTail
        (nsView.cell as? NSTextFieldCell)?.lineBreakMode = .byTruncatingTail
        nsView.needsDisplay = true
    }

    // Force the field to the width SwiftUI offers so tail truncation kicks in.
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSTextField, context: Context) -> CGSize? {
        let height = nsView.intrinsicContentSize.height
        let width = proposal.width ?? nsView.intrinsicContentSize.width
        return CGSize(width: width, height: height)
    }
}

// MARK: - Checkbox

struct CheckboxView: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isOn ? Theme.accent : Theme.inputBackground)
                        .frame(width: 18, height: 18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(isOn ? Theme.accent : Theme.border, lineWidth: 1)
                        )
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(isOn ? 1 : 0)
                        .scaleEffect(isOn ? 1 : 0.5)
                }
                Text(title)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isOn)
    }
}

// MARK: - Copy button

struct CopyButton: View {
    let copied: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.system(size: 12, weight: .semibold))
                Text(copied ? "Copied to clipboard" : "Copy")
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            // Fixed width so the button doesn't resize between states.
            .frame(width: 150, height: 34)
        }
        .buttonStyle(AccentButtonStyle(success: copied))
        .animation(.easeInOut(duration: 0.2), value: copied)
    }
}

// MARK: - Button styles

struct AccentButtonStyle: ButtonStyle {
    var success: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(success ? Theme.success : (configuration.isPressed ? Theme.accent : Theme.accentHover))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Theme.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(configuration.isPressed ? Theme.accent : Theme.inputBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
