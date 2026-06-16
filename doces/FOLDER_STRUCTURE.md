# Agent Awake — Xcode Project Structure

**Updated:** Migrated to SwiftUI-native `MenuBarExtra` (macOS 13+). No `NSStatusBar`, no `NSHostingView`.

---

## Architectural Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   AgentAwakeApp (@main)                      │
│                                                             │
│  ┌────────────────────────────────┐  ┌──────────────────┐   │
│  │  MenuBarExtra Scene            │  │  Settings Scene   │   │
│  │                                │  │  (Preferences)    │   │
│  │  ┌────────────┐ ┌───────────┐ │  └──────────────────┘   │
│  │  │ StatusIcon │ │ MenuBar   │ │                          │
│  │  │ (label)    │ │ ExtraCont │ │                          │
│  │  └────────────┘ │ ent       │ │                          │
│  │                 └───────────┘ │                          │
│  └────────────────────────────────┘                          │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  AppDelegate (NSApplicationDelegateAdaptor)              ││
│  │  • applicationWillTerminate → release assertion         ││
│  │  • applicationDidFinishLaunching → start services       ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  AppState (@StateObject → .environmentObject)          ││
│  │  • Owns all services                                    ││
│  │  • Published state for UI                               ││
│  │  • Combine subscriptions wire services together         ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

**Key difference from prior architecture:** `MenuBarExtra` replaces the manual `NSStatusBar` + `NSHostingView` setup. The menu bar icon and its dropdown content are now pure SwiftUI `Scene` + `View`, declared declaratively in `AgentAwakeApp.swift`.

---

## Folder Tree

```
AgentAwake.xcodeproj/
└── project.pbxproj

App/
├── AgentAwakeApp.swift
├── AppDelegate.swift
├── Info.plist
└── Entitlements.plist

UI/
├── MenuBar/
│   ├── MenuBarExtraContent.swift
│   ├── StatusIcon.swift
│   ├── AgentRow.swift
│   └── StatusHeader.swift
│
├── Settings/
│   ├── PreferencesView.swift
│   ├── AgentsSettingsTab.swift
│   ├── GeneralSettingsTab.swift
│   └── AboutSettingsTab.swift
│
└── Components/
    ├── ProcessNameEditor.swift
    └── AgentBadge.swift

Services/
├── ProcessScanService.swift
├── SleepManager.swift
├── HotKeyService.swift
├── LoginItemManager.swift
└── PreferencesService.swift

Models/
├── AgentProcess.swift
├── AgentIdentifier.swift
├── Preferences.swift
└── AppState.swift

Extensions/
├── Bundle+AppInfo.swift
└── ProcessInfo+AgentMatching.swift

Config/
└── Constants.swift

Resources/
└── Assets.xcassets/
    ├── Contents.json
    ├── StatusActive.imageset/
    │   └── Contents.json
    └── StatusInactive.imageset/
        └── Contents.json

Tests/
├── AgentAwakeTests/
│   ├── AgentIdentifierTests.swift
│   ├── AgentProcessTests.swift
│   ├── ProcessScanServiceTests.swift
│   ├── SleepManagerTests.swift
│   ├── PreferencesServiceTests.swift
│   ├── PreferencesModelTests.swift
│   ├── AppStateTests.swift
│   ├── LoginItemManagerTests.swift
│   └── HotKeyServiceTests.swift
│
└── AgentAwakeUITests/
    ├── AgentAwakeUITests.swift
    └── MenuBarExtraUITests.swift
```

**Total files:** 39 (including test targets)

---

## File Responsibilities

### App Layer — Entry Point & Lifecycle

#### `App/AgentAwakeApp.swift`

| Property | Value |
|---|---|
| **Role** | `@main` SwiftUI App struct. Declares the two scenes. |
| **Conformances** | `App` |
| **Key Imports** | `SwiftUI`, `ServiceManagement` |
| **Declares** | `@NSApplicationDelegateAdaptor var appDelegate: AppDelegate`, `@StateObject var appState: AppState` |
| **Scenes** | `MenuBarExtra` (primary), `Settings` (preferences window) |
| **Styling** | `.menuBarExtraStyle(.menu)` |
| **Injection** | `.environmentObject(appState)` on both scenes |

#### `App/AppDelegate.swift`

| Property | Value |
|---|---|
| **Role** | `NSApplicationDelegate` — lifecycle hooks only. No menu bar setup (that is `MenuBarExtra`'s job). |
| **Conformances** | `NSApplicationDelegate`, `ObservableObject` |
| **Key Imports** | `AppKit` |
| **Properties** | `weak var appState: AppState?` (set from `AgentAwakeApp`) |
| **Methods** | `applicationDidFinishLaunching` → start process scan, register hotkey, load preferences, sync login item state |
| **Methods** | `applicationWillTerminate` → release sleep assertion, unregister hotkey, stop process scan |
| **Methods** | `applicationDidChangeScreenParameters` → no-op (future: handle display change) |

#### `App/Info.plist`

| Key | Value | Purpose |
|---|---|---|
| `LSUIElement` | `YES` | Hides Dock icon and app switcher presence |
| `CFBundleIdentifier` | `com.agentawake.app` | Bundle ID |
| `CFBundleName` | `Agent Awake` | Display name |
| `CFBundleShortVersionString` | `1.0.0` | Marketing version |
| `CFBundleVersion` | `1` | Build number |
| `LSMinimumSystemVersion` | `13.0` | Minimum macOS version |

#### `App/Entitlements.plist`

| Key | Value | Purpose |
|---|---|---|
| `com.apple.security.app-sandbox` | `NO` v2: optional sandbox |
| `com.apple.security.device` | (none) | No device entitlements needed |
| `com.apple.security.network.client` | `NO` | No network access |

---

### UI Layer — Menu Bar

All files in `UI/MenuBar/` are SwiftUI `View` types.

#### `UI/MenuBar/MenuBarExtraContent.swift`

| Property | Value |
|---|---|
| **Role** | The content of the `MenuBarExtra` dropdown. Replaces the old `NSMenu`-based dropdown. |
| **Conformances** | `View` |
| **Key Imports** | `SwiftUI` |
| **Environment** | `@EnvironmentObject var appState: AppState` |
| **Contains** | `StatusHeader` (top), `ForEach(appState.activeAgents)` of `AgentRow`, `Divider()`, `SettingsLink { Label("Preferences…", ...) }`, `Divider()`, `Button("Quit")` |
| **Modifiers** | `.onAppear` (future), `.onDisappear` (future) |

#### `UI/MenuBar/StatusIcon.swift`

| Property | Value |
|---|---|
| **Role** | The `Label` of the `MenuBarExtra` — the icon shown in the menu bar itself. |
| **Conformances** | `View` |
| **Key Imports** | `SwiftUI` |
| **Environment** | `@EnvironmentObject var appState: AppState` |
| **Rendering** | Uses SF Symbol `"moon.fill"` / `"sun.max.fill"` based on `appState.isPreventingSleep`. Template image rendering. |
| **Animation** | Smooth crossfade or symbol effect on state change |

#### `UI/MenuBar/AgentRow.swift`

| Property | Value |
|---|---|
| **Role** | Single row showing one detected agent in the dropdown. |
| **Conformances** | `View` |
| **Key Imports** | `SwiftUI` |
| **Parameters** | `let agent: AgentProcess` |
| **Contains** | `Label(agent.displayName, systemImage: ...)`, secondary text showing "Active" badge + elapsed time |
| **Accessibility** | Label: "Agent agentName, active for X minutes" |

#### `UI/MenuBar/StatusHeader.swift`

| Property | Value |
|---|---|
| **Role** | Top section of the dropdown — shows current status. |
| **Conformances** | `View` |
| **Key Imports** | `SwiftUI` |
| **Environment** | `@EnvironmentObject var appState: AppState` |
| **States** | Preventing: `HStack { Image(systemName: "shield.fill") Text("Preventing sleep — \(n) agent(s)") }` |
| **States** | Monitoring: `HStack { Image(systemName: "eye") Text("Monitoring — No agents detected") }` |
| **States** | Error: `HStack { Image(systemName: "exclamationmark.triangle.fill") Text("Error preventing sleep") }` (when `lastScanError != nil`) |

---

### UI Layer — Settings / Preferences

All files in `UI/Settings/` — content of the `Settings` scene (opened via `SettingsLink` or `Cmd+,`).

#### `UI/Settings/PreferencesView.swift`

| Property | Value |
|---|---|
| **Role** | Root of the Settings scene. Hosts a `TabView`. |
| **Conformances** | `View` |
| **Key Imports** | `SwiftUI` |
| **Environment** | `@EnvironmentObject var appState: AppState` |
| **Contains** | `TabView { AgentsSettingsTab().tabItem { ... }; GeneralSettingsTab().tabItem { ... }; AboutSettingsTab().tabItem { ... } }` |
| **Style** | `.tabViewStyle(.automatic)` — native macOS tab bar |

#### `UI/Settings/AgentsSettingsTab.swift`

| Property | Value |
|---|---|
| **Role** | "Agents" tab — manage monitored agent process names. |
| **Conformances** | `View` |
| **Key Imports** | `SwiftUI` |
| **Environment** | `@EnvironmentObject var appState: AppState` |
| **Sections** | Default agents (non-removable list), Custom agents (editable via `ProcessNameEditor`) |
| **Behaviors** | Adding a custom name updates `appState.preferences.customAgentNames`. Removing a custom name removes it from the array. Changes propagate immediately. |

#### `UI/Settings/GeneralSettingsTab.swift`

| Property | Value |
|---|---|
| **Role** | "General" tab — app behavior toggles. |
| **Conformances** | `View` |
| **Key Imports** | `SwiftUI`, `ServiceManagement` |
| **Environment** | `@EnvironmentObject var appState: AppState` |
| **Toggles** | `Toggle("Launch at login", isOn: $appState.preferences.launchAtLogin)`, `Toggle("Show sleep prevention notifications", isOn: $appState.preferences.showSleepNotifications)` |
| **Side effects** | `launchAtLogin` change triggers `LoginItemManager.register()`/`unregister()` via AppState subscription |

#### `UI/Settings/AboutSettingsTab.swift`

| Property | Value |
|---|---|
| **Role** | "About" tab — version info, credits, hotkey display. |
| **Conformances** | `View` |
| **Key Imports** | `SwiftUI` |
| **Environment** | `@EnvironmentObject var appState: AppState` |
| **Contents** | App icon, app name "Agent Awake", version from `Bundle.main.versionString`, build from `Bundle.main.buildString`, "Global shortcut: ⌥⌘A → Lock Screen" with status indicator (active/unavailable), login item status |

---

### UI Layer — Reusable Components

#### `UI/Components/ProcessNameEditor.swift`

| Property | Value |
|---|---|
| **Role** | Reusable view for adding/removing process name strings. Used in `AgentsSettingsTab`. |
| **Conformances** | `View` |
| **Key Imports** | `SwiftUI` |
| **Parameters** | `@Binding var names: [String]`, `let title: String` |
| **Contains** | `List` of names with swipe-to-delete, `HStack { TextField(...) }` + `Button("Add")` at bottom |

#### `UI/Components/AgentBadge.swift`

| Property | Value |
|---|---|
| **Role** | Small colored badge indicating agent state. |
| **Conformances** | `View` |
| **Key Imports** | `SwiftUI` |
| **Parameters** | `let isActive: Bool` |
| **Rendering** | Green filled circle (active), gray outlined circle (inactive). Uses `Circle().fill(.green).frame(width: 8, height: 8)` |

---

### Services Layer

All services are classes that hold no UI state themselves — they emit values that `AppState` subscribes to.

#### `Services/ProcessScanService.swift`

| Property | Value |
|---|---|
| **Role** | Polls running processes and publishes detected agents via Combine. |
| **Conformances** | None (plain `class`) |
| **Key Imports** | `AppKit`, `Combine`, `OSLog` |
| **Actor isolation** | `@MainActor` (starts timer on main run loop; scan itself dispatches to background) |
| **Properties** | `private let knownAgentNames: CurrentValueSubject<Set<String>, Never>`, `private let scanInterval: TimeInterval`, `private var timer: Timer?`, `private let detectedAgentsSubject: CurrentValueSubject<Set<AgentProcess>, Never>` |
| **Publisher** | `var detectedAgents: AnyPublisher<Set<AgentProcess>, Never>` — emits only on change (`.removeDuplicates()`) |
| **Methods** | `startScanning()` — creates `Timer.scheduledTimer(withTimeInterval:scanInterval, repeats: true)`, performs initial scan immediately |
| **Methods** | `stopScanning()` — invalidates timer, publishes empty set |
| **Methods** | `updateAgentNames(_:)` — merges default + custom names into `knownAgentNames` |
| **Internal** | `private func scan() -> Set<AgentProcess>` — calls `NSWorkspace.shared.runningApplications`, filters by `knownAgentNames`, maps to `AgentProcess`, runs on a background serial queue |
| **Errors** | On scan failure, logs via `os_log` and returns empty set (fail-open) |

#### `Services/SleepManager.swift`

| Property | Value |
|---|---|
| **Role** | Wraps `IOPMAssertionCreateWithName` and `IOPMAssertionRelease`. |
| **Conformances** | None (plain `class`) |
| **Key Imports** | `IOKit` (`IOPMLib`), `OSLog` |
| **Actor isolation** | `@MainActor` |
| **Properties** | `private var assertionID: IOPMAssertionID?` |
| **Computed** | `var isPreventingSleep: Bool { assertionID != nil }` |
| **Methods** | `func preventSleep(reason: String) -> Bool` — acquires assertion with `kIOPMAssertionTypeNoIdleSleep`, stores ID, logs, returns success |
| **Methods** | `func allowSleep()` — releases assertion if held, nil-ifies ID, logs |
| **Methods** | `func releaseOnTerminate()` — called from `AppDelegate.applicationWillTerminate`; calls `allowSleep()` |
| **Thread safety** | All calls through `@MainActor`; assertion C APIs are thread-safe but wrapping ensures ordering |

#### `Services/HotKeyService.swift`

| Property | Value |
|---|---|
| **Role** | Registers Option+Command+A globally; calls `SACLockScreenImmediate`. |
| **Conformances** | None (plain `class`) |
| **Key Imports** | `Carbon` (for `RegisterEventHotKey`), `Security` (for `SACLockScreenImmediate`), `OSLog` |
| **Actor isolation** | `@MainActor` |
| **Properties** | `private var hotKeyRef: EventHotKeyRef?`, `private var eventHandler: EventHandlerRef?`, `private let hotKeyID: EventHotKeyID`, `private var isUsingCarbon: Bool` |
| **Methods** | `func register() -> Bool` — registers global hotkey via `RegisterEventHotKey`, installs event handler via `InstallEventHandler`. Returns false if registration fails. |
| **Methods** | `func unregister()` — `UnregisterEventHotKey`, `RemoveEventHandler` |
| **Callback** | On hotkey event: `SACLockScreenImmediate()` — locks screen immediately. Ignores key-repeat events. |
| **Error state** | On failure, logs warning and sets `appState.hotKeyUnavailable = true` |
| **Alternative** | If Carbon hotkey fails, fall back to `CGEventTapCreate` with a note in the log |

#### `Services/LoginItemManager.swift`

| Property | Value |
|---|---|
| **Role** | Wraps `SMAppService.mainApp` for login item registration. |
| **Conformances** | None (plain `class`) |
| **Key Imports** | `ServiceManagement`, `OSLog` |
| **Actor isolation** | `@MainActor` |
| **Computed** | `var isRegistered: Bool { SMAppService.mainApp.status == .enabled }` |
| **Methods** | `func register() throws` — calls `SMAppService.mainApp.register()` |
| **Methods** | `func unregister() throws` — calls `SMAppService.mainApp.unregister()` |
| **Methods** | `func synchronize() -> Bool` — reads actual status, returns it (used on launch to sync toggle with reality) |
| **Error mapping** | Maps `SMAppServiceError` to user-readable messages via a private helper |

#### `Services/PreferencesService.swift`

| Property | Value |
|---|---|
| **Role** | Reads and writes `Preferences` struct to `UserDefaults`. |
| **Conformances** | None (plain `class`) |
| **Key Imports** | `Foundation`, `OSLog` |
| **Actor isolation** | Not isolated (stateless; thread-safe by virtue of `UserDefaults` being thread-safe) |
| **Storage key** | `"com.agentawake.preferences"` |
| **Methods** | `func load() -> Preferences` — reads `Data` from `UserDefaults.standard`, decodes via `JSONDecoder`. On failure, logs and returns `Preferences.defaults`. |
| **Methods** | `func save(_ preferences: Preferences)` — encodes via `JSONEncoder`, writes to `UserDefaults.standard`. Flushes synchronously for UI consistency. |
| **Methods** | `func resetToDefaults()` — removes key from `UserDefaults`, returns `Preferences.defaults` |
| **Methods** | `func migrateIfNeeded() -> Preferences` — checks for legacy keys, migrates, returns migrated `Preferences` |

---

### Models Layer

#### `Models/AgentProcess.swift`

| Property | Value |
|---|---|
| **Role** | Value type representing a detected agent process. |
| **Conformances** | `Identifiable`, `Hashable`, `Codable`, `Sendable` |
| **Properties** | `let id: String` (computed from `pid`), `let identifier: AgentIdentifier`, `let displayName: String`, `let pid: pid_t`, `let detectedAt: Date` |
| **Hashable** | Based solely on `pid` (process ID is unique per system at any point in time) |
| **Equality** | Two `AgentProcess` values are equal if their `pid` matches |

#### `Models/AgentIdentifier.swift`

| Property | Value |
|---|---|
| **Role** | Enum of all supported (and user-custom) coding agents. |
| **Conformances** | `String`, `CaseIterable`, `Codable`, `Hashable`, `Sendable` |
| **Cases** | `claudeCode`, `cursor`, `codexCLI`, `geminiCLI`, `aider`, `copilot`, `custom` |
| **Computed** | `var displayName: String` — human-readable name for UI |
| **Computed** | `var processNames: [String]` — process name(s) to match against `NSRunningApplication.localizedName`. Claude Code matches both "Claude" and "claude". |
| **Static** | `static var defaults: [AgentIdentifier]` — all non-custom cases |
| **Match logic** | Case-insensitive, exact match against `localizedName` (no substring matching to avoid false positives) |

#### `Models/Preferences.swift`

| Property | Value |
|---|---|
| **Role** | Value type for all persisted user preferences. |
| **Conformances** | `Codable`, `Equatable`, `Sendable` |
| **Properties** | `var customAgentNames: [String]`, `var launchAtLogin: Bool`, `var showSleepNotifications: Bool`, `var hasLaunchedBefore: Bool` |
| **Static** | `static let defaults: Preferences` — factory value with sensible defaults (no custom agents, no launch at login, notifications on, false for hasLaunchedBefore) |

#### `Models/AppState.swift`

| Property | Value |
|---|---|
| **Role** | Single root state object. Owns all services. Subscribes to service publishers and updates published UI state. |
| **Conformances** | `ObservableObject` |
| **Actor isolation** | `@MainActor` |
| **Published** | `var isPreventingSleep: Bool`, `var activeAgents: [AgentProcess]`, `var preferences: Preferences`, `var lastScanError: String?`, `var hotkeyUnavailable: Bool` |
| **Published (private(set))** | `var monitoredProcessNames: [String]` |
| **Owned services** | `let processScanService: ProcessScanService`, `let sleepManager: SleepManager`, `let hotKeyService: HotKeyService`, `let loginItemManager: LoginItemManager`, `let preferencesService: PreferencesService` |
| **Subscriptions** | `private var cancellables: Set<AnyCancellable>` |
| **Init** | Loads preferences, configures service with monitored names, subscribes to `ProcessScanService.detectedAgents` |
| **Subscriber logic** | Agent set change → update `activeAgents`. If non-empty and not already preventing: `sleepManager.preventSleep()`. If empty and preventing: `sleepManager.allowSleep()`. |
| **Subscriber logic** | `$preferences.dropFirst().debounce(...)` → save via `preferencesService.save()`. If `customAgentNames` changed: call `processScanService.updateAgentNames(...)`. If `launchAtLogin` changed: call `loginItemManager.register()`/`unregister()`. |
| **Computed** | `var statusText: String`, `var latestAgent: AgentProcess?`, `var hasCustomAgents: Bool` |

---

### Extensions Layer

#### `Extensions/Bundle+AppInfo.swift`

| Property | Value |
|---|---|
| **Role** | Convenience accessors for version info from Info.plist. |
| **Conformances** | None (extension on `Bundle`) |
| **Computed** | `var versionString: String` — `infoDictionary["CFBundleShortVersionString"] as? String ?? "0.0.0"` |
| **Computed** | `var buildString: String` — `infoDictionary["CFBundleVersion"] as? String ?? "0"` |

#### `Extensions/ProcessInfo+AgentMatching.swift`

| Property | Value |
|---|---|
| **Role** | Helper to match an `NSRunningApplication` against a set of known agent names. |
| **Conformances** | None (extension on `ProcessInfo`) |
| **Methods** | `static func matches(application: NSRunningApplication, knownNames: Set<String>) -> Bool` — compares `application.localizedName` (case-insensitive) against `knownNames` |
| **Methods** | `static func activeAgentDisplayNames(applications: [NSRunningApplication], knownNames: Set<String>) -> [String]` — maps matched apps to their display names |

---

### Config Layer

#### `Config/Constants.swift`

| Property | Value |
|---|---|
| **Role** | Single source of truth for app-wide constants. No logic. |
| **Key Imports** | `Foundation` |
| **Enum** | `enum Constants { }` — non-instantiable namespace |
| **Values** | `static let appName = "Agent Awake"`, `static let defaultScanInterval: TimeInterval = 3.0`, `static let hotkeyModifierFlags: UInt32 = (cmdKey + optionKey)`, `static let hotkeyKeyCode: UInt32 = 0x00` (key code for 'A'), `static let preferencesStoreKey = "com.agentawake.preferences"`, `static let assertionNamePrefix = "com.agentawake.sleep-prevention"` |

---

### Resources Layer

#### `Resources/Assets.xcassets/StatusActive.imageset/Contents.json`

| Property | Value |
|---|---|
| **Role** | Template image for the active (preventing sleep) state. |
| **Contents** | JSON with `"preserves-vector-representation": true`, `"template"` render mode. References PDF or PNG at 16pt and 22pt. |

#### `Resources/Assets.xcassets/StatusInactive.imageset/Contents.json`

| Property | Value |
|---|---|
| **Role** | Template image for the inactive (monitoring) state. |
| **Contents** | Same structure as `StatusActive`. Outlined/variant design to distinguish states. |

---

### Tests Layer

#### `Tests/AgentAwakeTests/AgentIdentifierTests.swift`

| Tests | `testDefaultCount`, `testProcessNamesNotEmpty`, `testCaseInsensitiveMatching`, `testCustomHasEmptyProcessNames`, `testAllCasesHaveDisplayNames` |
|---|---|

#### `Tests/AgentAwakeTests/AgentProcessTests.swift`

| Tests | `testEqualityByPID`, `testHashableContract`, `testIdentifiableIDMatchesPID`, `testCodableRoundTrip` |
|---|---|

#### `Tests/AgentAwakeTests/ProcessScanServiceTests.swift`

| Tests | `testScanWithNoMatches`, `testScanWithSingleMatch`, `testScanWithMultipleMatches`, `testScanIgnoresUnknownProcesses`, `testPublisherEmitsOnChangeOnly`, `testPublisherDoesNotEmitOnIdenticalScan`, `testCustomAgentNamesAreScanned`, `testEmptyKnownNamesReturnsEmpty`, `testStartStopLifecycle` |
|---|---|

#### `Tests/AgentAwakeTests/SleepManagerTests.swift`

| Tests | `testPreventSleepAcquiresAssertion`, `testAllowSleepReleasesAssertion`, `testIsActiveReflectsState`, `testAllowSleepWhenNotActiveIsNoop`, `testDoublePreventDoesNotCrash`, `testReasonStringFormat` |
|---|---|

#### `Tests/AgentAwakeTests/PreferencesServiceTests.swift`

| Tests | `testSaveLoadRoundTrip`, `testOnDecodeFailureReturnsDefaults`, `testResetToDefaults`, `testCustomAgentNamesPersist`, `testToggleValuesPersistIndependently` |
|---|---|

#### `Tests/AgentAwakeTests/PreferencesModelTests.swift`

| Tests | `testDefaultValues`, `testEquatableConformance`, `testCodableRoundTrip` |
|---|---|

#### `Tests/AgentAwakeTests/AppStateTests.swift`

| Tests | `testInitialState`, `testAgentDetectionTriggersPrevention`, `testAllAgentsGoneReleasesPrevention`, `testMultipleAgentsKeepsPreventionAlive`, `testCustomNamesUpdateScanService`, `testPreferencesChangeSaves` |
|---|---|

#### `Tests/AgentAwakeTests/LoginItemManagerTests.swift`

| Tests | `testRegisterUnregister`, `testIsRegisteredReflectsState`, `testDoubleRegisterThrows` |
|---|---|

#### `Tests/AgentAwakeTests/HotKeyServiceTests.swift`

| Tests | `testRegisterSucceeds`, `testUnregisterAfterRegister`, `testDoubleRegisterSafe`, `testHandlerNotCalledOnWrongKey` |
|---|---|

#### `Tests/AgentAwakeUITests/AgentAwakeUITests.swift`

| Tests | `testAppLaunches`, `testMenuBarIconExists`, `testMenuBarIconChangesState` |
|---|---|

#### `Tests/AgentAwakeUITests/MenuBarExtraUITests.swift`

| Tests | `testDropdownOpensOnClick`, `testDropdownShowsStatusText`, `testDropdownHasPreferencesButton`, `testDropdownHasQuitButton`, `testQuitTerminatesApp` |
|---|---|

---

## Swift 6 Concurrency Compliance

| Requirement | How Files Comply |
|---|---|
| **`Sendable` models** | `AgentProcess`, `AgentIdentifier`, `Preferences` conform to `Sendable` |
| **`@MainActor` UI** | `AgentAwakeApp`, all `View` types, `AppDelegate`, `AppState` annotated `@MainActor` |
| **`@MainActor` services** | `ProcessScanService`, `SleepManager`, `HotKeyService`, `LoginItemManager` annotated `@MainActor` |
| **Non-isolated services** | `PreferencesService` — stateless, no actor needed; all methods are synchronous |
| **Combine subscriptions** | `.receive(on: DispatchQueue.main)` on all service → UI pipelines |
| **Background scanning** | `ProcessScanService.scan()` dispatches to `DispatchQueue.global(qos: .utility)` via `async` |

---

## Import Map

```
File                              Imports
───                               ──────
AgentAwakeApp.swift               SwiftUI, ServiceManagement
AppDelegate.swift                 AppKit, Combine, OSLog
MenuBarExtraContent.swift         SwiftUI
StatusIcon.swift                  SwiftUI
AgentRow.swift                    SwiftUI
StatusHeader.swift                SwiftUI
PreferencesView.swift             SwiftUI
AgentsSettingsTab.swift           SwiftUI
GeneralSettingsTab.swift          SwiftUI, ServiceManagement
AboutSettingsTab.swift            SwiftUI
ProcessNameEditor.swift           SwiftUI
AgentBadge.swift                  SwiftUI
ProcessScanService.swift          AppKit, Combine, OSLog
SleepManager.swift                IOKit (IOPMLib), OSLog
HotKeyService.swift               Carbon, Security, OSLog
LoginItemManager.swift            ServiceManagement, OSLog
PreferencesService.swift          Foundation, OSLog
AgentProcess.swift                Foundation
AgentIdentifier.swift             Foundation
Preferences.swift                  Foundation
AppState.swift                    SwiftUI, Combine, OSLog
Bundle+AppInfo.swift              Foundation
ProcessInfo+AgentMatching.swift   AppKit
Constants.swift                   Foundation
```

---

## No External Dependencies

All system frameworks. Zero SPM packages, zero CocoaPods, zero Carthage.

| Framework | Used By | Purpose |
|---|---|---|
| `SwiftUI` | All views, App struct | UI framework |
| `AppKit` | AppDelegate, ProcessScanService | Application lifecycle, running applications API |
| `Combine` | AppState, ProcessScanService | Reactive pipelines between services and UI |
| `IOKit` | SleepManager | `IOPMAssertionCreateWithName` / `IOPMAssertionRelease` |
| `Security` | HotKeyService | `SACLockScreenImmediate` |
| `Carbon` | HotKeyService | `RegisterEventHotKey`, `EventHotKeyRef` |
| `ServiceManagement` | LoginItemManager, AgentAwakeApp, GeneralSettingsTab | `SMAppService` |
| `OSLog` | All services, AppState | Unified logging |
