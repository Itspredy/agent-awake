# Agent Awake — Data Models

---

## 1. AgentProcess

Represents a detected coding agent running on the system.

```swift
public struct AgentProcess: Identifiable, Hashable, Codable {
    /// Unique identifier (bundle PID as string)
    public let id: String

    /// The agent identifier (e.g., .claudeCode, .cursor, .custom)
    public let identifier: AgentIdentifier

    /// Display-friendly name (e.g., "Claude Code", "Cursor")
    public let displayName: String

    /// Process ID on the system
    public let pid: pid_t

    /// Timestamp when this agent was first detected in this run
    public let detectedAt: Date
}
```

**Hashable:** Based on `pid` (a process is unique by PID at any given time).

**Codable:** Used only for logging/debugging; not persisted across launches.

---

## 2. AgentIdentifier

Enum of all supported coding agents.

```swift
public enum AgentIdentifier: String, CaseIterable, Codable, Hashable {
    case claudeCode   = "Claude"
    case cursor       = "Cursor"
    case codexCLI     = "codex"
    case geminiCLI    = "gemini"
    case aider        = "aider"
    case copilot      = "github-copilot"
    case custom       = "__custom__"  // user-defined process names

    // ── Computed properties ──

    /// Human-readable display name for the UI
    public var displayName: String {
        switch self {
        case .claudeCode:  return "Claude Code"
        case .cursor:      return "Cursor"
        case .codexCLI:    return "Codex CLI"
        case .geminiCLI:   return "Gemini CLI"
        case .aider:       return "Aider"
        case .copilot:     return "GitHub Copilot"
        case .custom:      return "Custom Agent"
        }
    }

    /// The process name(s) to match against running applications
    public var processNames: [String] {
        switch self {
        case .claudeCode:  return ["Claude", "claude"]
        case .cursor:      return ["Cursor"]
        case .codexCLI:    return ["codex"]
        case .geminiCLI:   return ["gemini"]
        case .aider:       return ["aider"]
        case .copilot:     return ["github-copilot"]
        case .custom:      return []
        }
    }

    /// The default set of identifiers shipped with the app
    public static var defaults: [AgentIdentifier] {
        [.claudeCode, .cursor, .codexCLI, .geminiCLI, .aider, .copilot]
    }
}
```

**Process matching logic:**

```
For each running application:
    let appName = application.localizedName ?? application.bundleIdentifier ?? ""
    For each AgentIdentifier in monitored set:
        if identifier.processNames contains appName (case-insensitive)
            → matched
```

**Match rules:**
- Case-insensitive comparison.
- Substring match is NOT used (must match full process name) to avoid false positives.
- Custom agent names are stored as `AgentIdentifier.custom` with a user-provided `customName` property.

---

## 3. Preferences

Persisted user settings.

```swift
public struct Preferences: Codable, Equatable {
    /// Custom agent process names added by the user (beyond defaults)
    public var customAgentNames: [String]

    /// Whether to launch at login
    public var launchAtLogin: Bool

    /// Whether to show system notifications on state changes
    public var showSleepNotifications: Bool

    /// Whether the user has completed first-launch
    public var hasLaunchedBefore: Bool

    // ── Defaults ──

    public static let defaults = Preferences(
        customAgentNames: [],
        launchAtLogin: false,
        showSleepNotifications: true,
        hasLaunchedBefore: false
    )
}
```

**Persistence:** `UserDefaults.standard` via `JSONEncoder`/`JSONDecoder`.

**Storage key:** `"com.agentawake.preferences"`

---

## 4. AppState

The single root observable state object.

```swift
@MainActor
public class AppState: ObservableObject {
    /// Whether the app is currently holding a sleep prevention assertion
    @Published public var isPreventingSleep: Bool = false

    /// Set of currently detected active agents
    @Published public var activeAgents: [AgentProcess] = []

    /// Current user preferences (loaded on init, saved on change)
    @Published public var preferences: Preferences = .defaults

    /// Read-only: combined list of all monitored process names (default + custom)
    @Published private(set) public var monitoredProcessNames: [String] = []

    /// Last scan error (if any), for diagnostics
    @Published public var lastScanError: String? = nil
}
```

**State invariants:**

| Invariant | Enforced by |
|---|---|
| `isPreventingSleep` is `true` iff `activeAgents` is non-empty | `processScanService` subscriber |
| `activeAgents` never contains duplicates | `Set<AgentProcess>` in the publisher pipeline |
| `monitoredProcessNames` always = defaults + `preferences.customAgentNames` | Computed on preferences change |
| Assertion is always released on app termination | `applicationWillTerminate` hook |

---

## 5. Computed / Derived State (not stored)

```swift
extension AppState {
    /// Human-readable status string for the dropdown menu
    var statusText: String {
        if isPreventingSleep {
            "Preventing sleep — \(activeAgents.count) agent(s) active"
        } else {
            "Monitoring — No agents detected"
        }
    }

    /// Most recently detected agent (for notification content)
    var latestAgent: AgentProcess? {
        activeAgents.max(by: { $0.detectedAt < $1.detectedAt })
    }

    /// True if the global agent names include custom entries
    var hasCustomAgents: Bool {
        !preferences.customAgentNames.isEmpty
    }
}
```

---

## 6. Notification Payload (Local)

```swift
public enum SleepStateChange: Equatable {
    case preventionStarted(agent: AgentProcess)
    case preventionStopped
}
```

Used only for in-app logic; not persisted.

---

## 7. UserDefaults Schema

| Key | Type | Default | Purpose |
|---|---|---|---|
| `com.agentawake.preferences` | `Data` (JSON) | `Preferences.defaults` | Full preferences struct |
| `com.agentawake.hasLaunchedBefore` | `Bool` | `false` | First-launch flag (redundant with above, kept for quick check) |

---

## 8. Codable Compliance

All model types conform to `Codable` for:

- Persistence (`Preferences`)
- Diagnostic logging (`AgentProcess`, `AgentIdentifier`)
- Potential future clipboard or export features

No Core Data or SwiftData is used — the data model is intentionally flat and lightweight.
