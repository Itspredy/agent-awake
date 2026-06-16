import Foundation

enum AgentIdentifier: String, CaseIterable, Sendable {
    case claudeCode = "Claude"

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code"
        }
    }

    var processNames: [String] {
        switch self {
        case .claudeCode: return ["Claude", "claude"]
        }
    }

    static var defaults: [AgentIdentifier] {
        [.claudeCode]
    }
}
