import SwiftUI
import Combine
import OSLog

@MainActor
final class AppState: ObservableObject {
    @Published var isAgentModeEnabled = true
    @Published var activeAgents: [AgentProcess] = []

    let agentMonitor = AgentMonitor()
    let sleepManager = SleepManager()
    let hotKeyService = HotKeyService()
    private var cancellables = Set<AnyCancellable>()

    var agentCount: Int { activeAgents.count }

    var agentNames: [AgentProcess] { activeAgents }

    var isActive: Bool {
        isAgentModeEnabled && !activeAgents.isEmpty && sleepManager.isPreventingSleep
    }

    init() {
        agentMonitor.$detectedAgents
            .removeDuplicates()
            .sink { [weak self] agents in
                self?.activeAgents = agents
            }
            .store(in: &cancellables)

        Publishers.CombineLatest($isAgentModeEnabled, $activeAgents)
            .removeDuplicates { lhs, rhs in
                lhs.0 == rhs.0 && lhs.1 == rhs.1
            }
            .sink { [weak self] isEnabled, agents in
                guard let self else { return }
                if isEnabled, !agents.isEmpty {
                    let names = agents.map(\.displayName).joined(separator: ", ")
                    self.sleepManager.preventSleep(reason: names)
                } else {
                    self.sleepManager.allowSleep()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .sink { [weak self] _ in
                Logger.appState.debug("Termination notification received")
                self?.cleanup()
            }
            .store(in: &cancellables)

        agentMonitor.startMonitoring()
        hotKeyService.register()
    }

    func cleanup() {
        sleepManager.allowSleep()
        agentMonitor.stopMonitoring()
        hotKeyService.unregister()
    }
}
