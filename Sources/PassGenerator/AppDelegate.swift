import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: PasswordPanel?
    private var viewModel: PasswordViewModel?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var keyMonitor: Any?
    private var isPinned = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // No dock icon / menu bar app — behaves like a popup extension.
        NSApp.setActivationPolicy(.accessory)

        let vm = PasswordViewModel()
        self.viewModel = vm
        vm.onPinChanged = { [weak self] pinned in self?.isPinned = pinned }
        vm.onMinimize = { [weak self] in self?.minimizeWindow() }

        let root = ContentView(vm: vm)
        let hosting = NSHostingView(rootView: root)
        hosting.layout()
        let fitting = hosting.fittingSize

        let panel = PasswordPanel(
            contentRect: NSRect(origin: .zero, size: fitting)
        )
        panel.contentView = hosting
        self.panel = panel

        positionNearCursor(panel: panel, size: fitting)

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        installMouseMonitors()
        installKeyMonitor()
    }

    // MARK: Resize (collapse / expand)

    private func minimizeWindow() {
        guard let panel = panel else { return }
        // Anchor the top-left so the window collapses/expands downward.
        let topLeft = NSPoint(x: panel.frame.minX, y: panel.frame.maxY)
        panel.contentView?.layoutSubtreeIfNeeded()
        let size = panel.contentView?.fittingSize ?? panel.frame.size
        panel.setContentSize(size)
        panel.setFrameTopLeftPoint(topLeft)
    }

    // MARK: Positioning

    private func positionNearCursor(panel: NSPanel, size: NSSize) {
        let mouse = NSEvent.mouseLocation // screen coords, bottom-left origin
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        // Center the window exactly on the cursor.
        var x = mouse.x - size.width / 2
        var y = mouse.y - size.height / 2

        // Keep inside the visible screen area.
        x = min(max(x, visible.minX), visible.maxX - size.width)
        y = min(max(y, visible.minY), visible.maxY - size.height)

        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
    }

    // MARK: Cursor-leave monitoring

    private func installMouseMonitors() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.handleMouseMoved()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved()
            return event
        }
    }

    private func handleMouseMoved() {
        // When pinned, never auto-close on cursor leave.
        if isPinned { return }
        guard let frame = panel?.frame else { return }
        let mouse = NSEvent.mouseLocation
        if distance(from: mouse, to: frame) > Config.cursorLeaveDistance {
            NSApp.terminate(nil)
        }
    }

    private func distance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return hypot(dx, dy)
    }

    // MARK: Keyboard

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if event.keyCode == 53 { // Escape
                NSApp.terminate(nil)
                return nil
            }
            return event
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let g = globalMonitor { NSEvent.removeMonitor(g) }
        if let l = localMonitor { NSEvent.removeMonitor(l) }
        if let k = keyMonitor { NSEvent.removeMonitor(k) }
    }
}
