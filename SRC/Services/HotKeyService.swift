import AppKit
import OSLog

@MainActor
final class HotKeyService {
    private var globalMonitor: Any?
    private var localMonitor: Any?

    private let hotKeyCode: UInt16 = 0x00

    private let cgsessionURL = URL(
        fileURLWithPath: "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
    )

    func register() {
        guard globalMonitor == nil else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak event] event in
            guard let event, HotKeyService.isHotKey(event) else { return event }
            Self.lockScreen()
            return nil
        }

        Logger.hotKeyService.debug("Hotkey registered: ⌥⌘A")
    }

    func unregister() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        Logger.hotKeyService.debug("Hotkey unregistered")
    }

    private static func isHotKey(_ event: NSEvent) -> Bool {
        event.modifierFlags.isSuperset(of: [.command, .option]) && event.keyCode == 0x00
    }

    private static func lockScreen() {
        let process = Process()
        process.executableURL = URL(
            fileURLWithPath: "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
        )
        process.arguments = ["-suspend"]

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            Logger.hotKeyService.error("Failed to lock screen: \(error.localizedDescription)")
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        if Self.isHotKey(event) {
            Self.lockScreen()
        }
    }
}
