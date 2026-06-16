# Agent Awake — Technical Architecture

**Covers:** Item 3 (Technical Architecture), Item 6 (Service Architecture), Item 7 (State Management Architecture)

---

## 1. System Overview

```
┌──────────────────────────────────────────────────────┐
│                  macOS Menu Bar                       │
│  ┌──────────────────────────────────────────────┐    │
│  │  Agent Awake (NSApplication .accessory)       │    │
│  │                                               │    │
│  │  ┌─────────────┐  ┌──────────────────────┐   │    │
│  │  │ MenuBarView  │  │  PreferencesWindow   │   │    │
│  │  │ (SwiftUI)    │  │  (SwiftUI)           │   │    │
│  │  └──────┬──────┘  └──────────────────────┘   │    │
│  │         │                                     │    │
│  │  ┌──────▼──────────────────────────────────┐  │    │
│  │  │         AppState (ObservableObject)      │  │    │
│  │  │  - isPreventingSleep: Bool              │  │    │
│  │  │  - activeAgents: [AgentProcess]         │  │    │
│  │  │  - preferences: Preferences             │  │    │
│  │  └──────┬──────────────────────────────────┘  │    │
│  │         │                                     │    │
│  │  ┌──────▼──────────────────────────────────┐  │    │
│  │  │           Services Layer                 │  │    │
│  │  │  ┌────────────┐ ┌──────────────────┐    │  │    │
│  │  │  │ProcessScan │ │ SleepManager     │    │  │    │
│  │  │  │Service     │ │ (IOPMAssertion)  │    │  │    │
│  │  │  └────────────┘ └──────────────────┘    │  │    │
│  │  │  ┌────────────┐ ┌──────────────────┐    │  │    │
│  │  │  │HotKeyRegist│ │ LoginItemManager │    │  │    │
│  │  │  │rar         │ │ (SMAppService)   │    │  │    │
│  │  │  └────────────┘ └──────────────────┘    │  │    │
│  │  └──────────────────────────────────────────┘  │    │
│  └──────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────┘
```

---

## 2. Technology Stack

| Layer | Technology | Rationale |
|---|---|---|
| **UI Framework** | SwiftUI | Native, declarative, minimal boilerplate |
| **App Lifecycle** | `@main` SwiftUI `App` + `NSApplicationDelegateAdaptor` | Access to NSApplication delegate for menu bar setup |
| **Menu Bar** | `NSStatusBar.system.statusItem` (via `NSHostingView`) | SwiftUI-native menu bar rendering |
| **Process Detection** | `NSWorkspace.shared.runningApplications` | No special permissions required |
| **Sleep Prevention** | `IOPMAssertionCreateWithName` (IOPMLib) | System API for sleep management |
| **Screen Lock** | `SACLockScreenImmediate` (Security framework) | System API for immediate lock |
| **Global Hotkey** | `CGEvent` + `CGEventTapCreate` or `RegisterEventHotKey` (Carbon) | Global keyboard shortcut registration |
| **Login Item** | `SMAppService` (ServiceManagement) | Modern macOS 13+ API for launch-at-login |
| **Persistence** | `UserDefaults` (`.standard`) | Simple key-value preferences |
| **Minimum OS** | macOS 13 Ventura | Matches SwiftUI + SMAppService availability |

---

## 3. Service Architecture

### 3.1 ProcessScanService

**Responsibility:** Detect when supported agents are running.

```
ProcessScanService
├── Properties:
│   - knownAgentNames: Set<String>    (default + user-custom)
│   - scanInterval: TimeInterval      (default: 3.0 seconds)
│   - isScanning: Bool
├── Methods:
│   + startScanning()
│   + stopScanning()
│   - scan() -> Set<AgentProcess>
│   + updateAgentNames(Set<String>)
├── Output:
│   - publisher: AnyPublisher<Set<AgentProcess>, Never>
└── Implementation:
    Uses Timer.publish(every: 3s) + combineLatest with NSWorkspace.shared
    .runningApplications publisher.
    Filter: matches knownAgentNames against process name (NSString).
    Dedup: returns unique set of running agent identifiers.
```

**Scan algorithm:**

```
1. Timer fires every 3 seconds.
2. Call proc_listallpids() or use NSWorkspace.shared.runningApplications.
3. For each running process, extract localizedName / process name.
4. If name matches any known agent name → include in result set.
5. Publish result set via Combine CurrentValueSubject.
6. ProcessScanService compares old vs. new set → emits on change only.
```

### 3.2 SleepManager

**Responsibility:** Acquire and release `IOPMAssertion` based on active agents.

```
SleepManager
├── Properties:
│   - assertionID: IOPMAssertionID?
│   - isActive: Bool
├── Methods:
│   + preventSleep(reason: String) -> Bool
│   + allowSleep()
│   - assertionName: "com.agentawake.sleep-prevention"
└── Implementation:
    preventSleep: IOPMAssertionCreateWithName(
        kIOPMAssertionTypeNoIdleSleep,
        kIOPMAssertionLevelOn,
        "Agent Awake — AgentName active",
        &assertionID
    )
    allowSleep: IOPMAssertionRelease(assertionID)
```

**Assertion lifecycle rules:**

| Condition | Action |
|---|---|
| No agents → agents detected | Acquire assertion |
| Agents active → agent count increases | No change (already held) |
| Agents active → agent count decreases but > 0 | No change (still needed) |
| Agents active → agent count reaches 0 | Release assertion |
| App quits while assertion held | Release assertion (in `applicationWillTerminate`) |

### 3.3 HotKeyService

**Responsibility:** Register and handle the global Option+Command+A shortcut.

```
HotKeyService
├── Key: Option (⌥) + Command (⌘) + A
├── Registration: Carbon RegisterEventHotKey or CGEventTap
├── Handler:
│   onPress → SACLockScreenImmediate()
├── Methods:
│   + register()
│   + unregister()
└── Considerations:
    - Must handle key repeat (ignore if held).
    - Must work when app is background / menu bar not focused.
    - Must coexist with other apps that may use same shortcut.
```

**Recommended approach:** Use `CGEventTap` with `.cgEventTapMachPort` for a lightweight global monitor. Fallback: `NSEvent.addGlobalMonitorForEvents(matching:)`.

### 3.4 LoginItemManager

**Responsibility:** Manage launch-at-login registration.

```
LoginItemManager
├── API: SMAppService(.mainApp)
├── Methods:
│   + isRegistered() -> Bool
│   + register() throws
│   + unregister() throws
└── Implementation:
    SMAppService.mainApp.register()
    SMAppService.mainApp.unregister()
    (SMAppService is available on macOS 13+)
```

### 3.5 PreferencesService

**Responsibility:** Persist and load user preferences.

```
PreferencesService
├── Backing store: UserDefaults.standard (suite: "com.agentawake")
├── Keys:
│   - "agentNames"         : [String]
│   - "launchAtLogin"      : Bool
│   - "showNotifications"  : Bool
│   - "hasLaunchedBefore"  : Bool
├── Methods:
│   + load() -> Preferences
│   + save(Preferences)
│   + resetToDefaults()
└── Implementation:
    Simple Codable struct → JSON encoder/decoder → UserDefaults.
```

---

## 4. State Management Architecture

### 4.1 AppState (Root ObservableObject)

```swift
@MainActor
class AppState: ObservableObject {
    // Published state (UI-bound)
    @Published var isPreventingSleep: Bool
    @Published var activeAgents: [AgentProcess]
    @Published var preferences: Preferences

    // Internal
    private let processScanService: ProcessScanService
    private let sleepManager: SleepManager
    private let hotKeyService: HotKeyService
    private let loginItemManager: LoginItemManager
    private var cancellables: Set<AnyCancellable>
}
```

### 4.2 Data Flow — Agent Detection

```
ProcessScanService (publishes Set<AgentProcess>)
    │
    ▼
AppState (subscribes via Combine)
    │  Filters: only on change (removeDuplicates)
    │
    ├──► Updates activeAgents
    │
    ├──► If activeAgents.isEmpty → calls sleepManager.allowSleep()
    │                             → sets isPreventingSleep = false
    │
    └──► If !activeAgents.isEmpty → calls sleepManager.preventSleep()
                                  → sets isPreventingSleep = true
                                  → (optional) posts notification
```

### 4.3 Data Flow — Preferences Change

```
User edits Preferences
    │
    ▼
PreferencesService.save()
    │
    ▼
AppState.preferences updated
    │
    ├──► If agentNames changed → ProcessScanService.updateAgentNames()
    ├──► If launchAtLogin changed → LoginItemManager.register/unregister()
    └──► If showNotifications changed → updates internal flag (no action needed)
```

### 4.4 State Diagram

```
                    ┌──────────────┐
                    │   Idle       │
                    │ (Monitoring) │
                    └──────┬───────┘
                           │ agents detected
                           ▼
                    ┌──────────────┐
                    │  Preventing  │
                    │   Sleep      │
                    │              │
                    │  (assertion  │
                    │   acquired)  │
                    └──────┬───────┘
                           │ all agents gone
                           ▼
                    ┌──────────────┐
                    │   Idle       │
                    │ (Monitoring) │
                    └──────────────┘
```

### 4.5 Threading Model

| Component | Thread | Rationale |
|---|---|---|
| AppState | Main actor | All UI-bound state on main thread |
| ProcessScanService | Background (serial queue) | Avoid blocking UI during `proc_listallpids` |
| SleepManager | Main actor (bridge to C API) | IOPMAssertion is thread-safe, but assertions are lightweight |
| HotKeyService | Main thread (event tap) | CGEventTap delivers on run loop |
| PreferencesService | Any (synchronized) | UserDefaults is thread-safe for reads/writes |

---

## 5. Key Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Process scan vs. callback | Polling every 3s | No system callback for "process started" without elevated privs |
| IOPMAssertion vs. caffeinate | IOPMAssertion | Native API, no subprocess, programmatic control |
| SMAppService vs. LSSharedFileList | SMAppService | Modern, sandbox-friendly, macOS 13+ only |
| Carbon hotkey vs. CGEventTap | CGEventTap | More modern, better Swift interop |
| No Accessibility API | Avoided | Privacy concern, not needed for process detection |
| SwiftUI MenuBar vs. AppKit | SwiftUI + NSHostingView | Balance of modern UI and menu bar flexibility |

---

## 6. Security & Privacy

- **No network permissions** required.
- **No Accessibility API** required.
- **No filesystem access** beyond app bundle.
- **No sandbox restrictions** (will run without sandbox for flexibility).
- **No privileged entitlements** required.
