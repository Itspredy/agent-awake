import SwiftUI

struct StatusHeader: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.activeAgents.isEmpty {
            Label("No agents detected", systemImage: "eye")
                .foregroundColor(.secondary)
        } else {
            Label(
                "\(appState.agentCount) agent(s) active",
                systemImage: "bolt.fill"
            )
            .foregroundColor(.green)
        }
    }
}
