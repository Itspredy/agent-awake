import AppKit
import OSLog

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.appDelegate.debug("App did finish launching")
    }
}
