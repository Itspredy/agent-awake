import SwiftUI

struct AgentRow: View {
    let agent: AgentProcess

    var body: some View {
        HStack {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
            Text(agent.displayName)
                .font(.body)
                .lineLimit(1)
            Spacer()
            Text(agent.detectedAt, style: .offset)
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}
