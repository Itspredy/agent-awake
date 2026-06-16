import OSLog

extension Logger {
    static let appState = Logger(subsystem: Constants.bundleIdentifier, category: "app-state")
    static let agentMonitor = Logger(subsystem: Constants.bundleIdentifier, category: "agent-monitor")
    static let sleepManager = Logger(subsystem: Constants.bundleIdentifier, category: "sleep-manager")
    static let hotKeyService = Logger(subsystem: Constants.bundleIdentifier, category: "hotkey")
    static let appDelegate = Logger(subsystem: Constants.bundleIdentifier, category: "app-delegate")
}
