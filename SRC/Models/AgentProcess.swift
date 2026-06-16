import Foundation

struct AgentProcess: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let pid: pid_t
    let detectedAt: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(pid)
    }

    static func == (lhs: AgentProcess, rhs: AgentProcess) -> Bool {
        lhs.pid == rhs.pid
    }
}
