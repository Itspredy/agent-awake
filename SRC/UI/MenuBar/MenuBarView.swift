import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        StatusHeader()

        if !appState.activeAgents.isEmpty {
            Divider()

            ForEach(appState.activeAgents) { agent in
                AgentRow(agent: agent)
            }
        }

        Divider()

        Toggle("Agent Mode", isOn: $appState.isAgentModeEnabled)

        Divider()

        HStack {
            Text("Lock Screen")
            Spacer()
            Text("⌥⌘A")
                .foregroundColor(.secondary)
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
