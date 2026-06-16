import Foundation
@preconcurrency import IOKit
import OSLog

@MainActor
final class SleepManager: ObservableObject {
    @Published private(set) var isPreventingSleep = false

    private var assertionID: IOPMAssertionID = 0

    deinit {
        if isPreventingSleep {
            IOPMAssertionRelease(assertionID)
        }
    }

    @discardableResult
    func preventSleep(reason: String) -> Bool {
        guard !isPreventingSleep else { return true }

        var id: IOPMAssertionID = 0
        let name = "Agent Awake — \(reason)" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep,
            kIOPMAssertionLevelOn,
            name,
            &id
        )

        guard result == kIOReturnSuccess else {
            Logger.sleepManager.error("Failed to acquire assertion: \(result)")
            return false
        }

        assertionID = id
        isPreventingSleep = true
        Logger.sleepManager.debug("Sleep prevention started: \(reason)")
        return true
    }

    func allowSleep() {
        guard isPreventingSleep else { return }

        IOPMAssertionRelease(assertionID)
        assertionID = 0
        isPreventingSleep = false
        Logger.sleepManager.debug("Sleep prevention stopped")
    }
}
