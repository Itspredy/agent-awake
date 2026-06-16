import AppKit
import Combine
import OSLog

@MainActor
final class AgentMonitor: ObservableObject {
    @Published private(set) var detectedAgents: [AgentProcess] = []

    private let knownAgentNames: Set<String> = Set(
        AgentIdentifier.defaults.flatMap(\.processNames)
    )
    private var cancellables = Set<AnyCancellable>()

    func startMonitoring() {
        Timer.publish(every: Constants.scanInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.scan()
            }
            .store(in: &cancellables)

        scan()
    }

    func stopMonitoring() {
        cancellables.removeAll()
        detectedAgents = []
    }

    private func scan() {
        let matched = NSWorkspace.shared.runningApplications.filter { app in
            guard let name = app.localizedName else { return false }
            return knownAgentNames.contains(name)
        }

        let newAgents = matched.map { app in
            AgentProcess(
                id: "\(app.processIdentifier)",
                displayName: app.localizedName ?? "Unknown",
                pid: app.processIdentifier,
                detectedAt: Date()
            )
        }

        if newAgents != detectedAgents {
            detectedAgents = newAgents
        }

        Logger.agentMonitor.debug("Scan complete: \(matched.count) agent(s) found")
    }
}
