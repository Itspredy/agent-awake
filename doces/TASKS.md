# Agent Awake — Implementation Task List

**Total phases:** 7  
**Total tasks:** 107  
**Estimated total effort:** ~80 hours  
**Each task:** Atomic, completable in < 1 hour by a senior macOS developer

---

## Phase 1 — Project Setup (10 tasks)

**Goal:** Scaffold the Xcode project, configure build settings, verify the app launches as an empty menu bar process.

### 1.1 Create Xcode project
- Create new macOS app project in Xcode.
- Target: macOS 13.0.
- Language: Swift, Interface: SwiftUI.
- Bundle identifier: `com.agentawake.app`.
- Team: none (set up signing later in Phase 7).
- Uncheck "Core Data", "Include Tests" (add manually).
- **Acceptance:** Project opens, builds successfully.

### 1.2 Set LSUIElement to hide Dock icon
- Open `Info.plist`.
- Add key `Application is agent (UIElement)` = `YES`.
- **Acceptance:** App launches with no Dock icon, no ⌘+Tab presence.

### 1.3 Create AppDelegate with empty NSStatusBar
- Add `AppDelegate.swift`.
- Conform to `NSApplicationDelegate`.
- Initialize `NSStatusBar.system.statusItem` with length `NSStatusItem.variableLength`.
- Set a placeholder title string ("Awake").
- **Acceptance:** App launches, empty menu bar item visible with "Awake" text.

### 1.4 Wire AppDelegate into SwiftUI @main
- Create `AgentAwakeApp.swift`.
- Use `@main` with `SwiftUI.App` struct.
- Use `NSApplicationDelegateAdaptor` to connect `AppDelegate`.
- Set `WindowGroup` to empty `ContentView`.
- **Acceptance:** App launches, AppDelegate.statusItem appears, no window.

### 1.5 Create Info.plist entries for versioning
- Set bundle version (`CFBundleVersion`) to `1`.
- Set short version string (`CFBundleShortVersionString`) to `1.0.0`.
- Set minimum system version (`LSMinimumSystemVersion`) to `13.0`.
- **Acceptance:** About dialog shows correct version info.

### 1.6 Create Constants.swift
- Define `enum Constants` with static values:
  - `appName = "Agent Awake"`
  - `defaultScanInterval: TimeInterval = 3.0`
  - `hotKeyModifiers = [.option, .command]`
  - `hotKeyCharacter = "a"`
  - `bundleIdentifier = "com.agentawake.app"`
- **Acceptance:** Constants file compiles, values accessible from anywhere.

### 1.7 Create empty Entitlements.plist
- Create `AgentAwake.entitlements`.
- Add `com.apple.security.device` (if needed — leave empty for now).
- Disable App Sandbox (no sandbox for v1).
- **Acceptance:** Code signing works in development mode.

### 1.8 Create Assets.xcassets with placeholder icons
- Create `StatusActive.imageset` with a temporary filled circle (green).
- Create `StatusInactive.imageset` with a temporary outlined circle (gray).
- Set both as "Template Image" render mode.
- **Acceptance:** Icons load in the asset catalog, render as template images.

### 1.9 Create empty model files
- Create `AgentProcess.swift`, `AgentIdentifier.swift`, `Preferences.swift`, `AppState.swift` with empty structs/classes.
- Create `AgentAwakeTests` test target.
- **Acceptance:** All files compile, test target builds.

### 1.10 Create bridging header for C APIs (if needed)
- If using `IOPMAssertion` or `SACLockScreenImmediate` directly without module import, create bridging header.
- Otherwise, verify `import IOKit` and `import Security` compile.
- **Acceptance:** C framework imports compile without errors.

---

## Phase 2 — Menu Bar App (18 tasks)

**Goal:** Build the full menu bar UI: icon, dropdown menu, preferences window.

### 2.1 Replace placeholder title with StatusIconView
- Create `StatusIconView.swift` using SwiftUI `Image(systemName:)`.
- Active state: `"moon.fill"` or `"sun.max.fill"` (SF Symbol).
- Inactive state: `"moon"` or `"sun.max"`.
- Use `.foregroundColor(.primary)` for template rendering.
- **Acceptance:** Icon renders in menu bar, changes with state.

### 2.2 Create AppState ObservableObject
- Define `AppState` class with:
  - `@Published var isPreventingSleep: Bool = false`
  - `@Published var activeAgents: [AgentProcess] = []`
  - `@Published var preferences: Preferences = .defaults`
- Annotate with `@MainActor`.
- **Acceptance:** AppState instance can be created and observed.

### 2.3 Inject AppState as EnvironmentObject
- In `AgentAwakeApp.swift`, create `AppState()` and inject via `.environmentObject()`.
- Pass to `AppDelegate` via init or setter.
- **Acceptance:** All views can access `@EnvironmentObject var appState: AppState`.

### 2.4 Create MenuDropdownView
- SwiftUI view with:
  - Status text: `appState.statusText`.
  - `ForEach(appState.activeAgents)` showing `MenuItemRow`.
  - Divider.
  - Button "Preferences…".
  - Button "Quit".
- **Acceptance:** View renders full dropdown.

### 2.5 Create MenuItemRow
- SwiftUI `HStack`:
  - Agent display name.
  - "Active" badge or dot.
  - Timestamp (optional, small secondary text).
- **Acceptance:** Row displays agent info.

### 2.6 Wire dropdown as NSMenu via NSHostingView
- In `AppDelegate`, create `NSMenu` and set as `statusItem.menu`.
- Use `NSHostingView` wrapped in `NSMenuItem` for the custom dropdown.
- Set up view with `environmentObject(appState)`.
- **Acceptance:** Clicking menu bar icon shows SwiftUI dropdown.

### 2.7 Implement PreferencesWindow
- Create `PreferencesWindow.swift` as `NSWindow` subclass or factory.
- Window style: `.titled`, `.closable`, `.miniaturizable`.
- Size: `width: 420, height: 320`.
- Center on screen.
- **Acceptance:** Window opens centered, correct size.

### 2.8 Create PreferencesView root
- SwiftUI `TabView` with three tabs:
  - "Agents".
  - "General".
  - "About".
- Tab style: `NSTabViewStyle` or `.toolbar`-style tabs.
- **Acceptance:** Tab switching works.

### 2.9 Implement AgentsPreferencesTab
- List of monitored agent names (defaults + custom).
- Each row: agent display name + process name(s).
- Add button → text field to type custom process name → append to list.
- Swipe-to-delete or minus button to remove custom entries.
- Default agents are non-removable.
- Changes propagate immediately to `appState.preferences`.
- **Acceptance:** Agent list editable, persists across window close/open.

### 2.10 Implement GeneralPreferencesTab
- Toggle: "Launch at login" bound to `appState.preferences.launchAtLogin`.
- Toggle: "Show sleep prevention notifications" bound to `appState.preferences.showSleepNotifications`.
- Small descriptive text below each toggle.
- **Acceptance:** Toggles work, values persist.

### 2.11 Implement AboutPreferencesTab
- App icon (from Assets).
- App name: "Agent Awake".
- Version from bundle.
- Build number from bundle.
- Copyright or credit text.
- **Acceptance:** Displays correct version info.

### 2.12 Wire Preferences menu item to open window
- In `MenuDropdownView`, "Preferences…" button calls action.
- Create `AppDelegate.openPreferences()` method.
- Method checks if window already open → bring to front; else create and show.
- **Acceptance:** Clicking Preferences opens window.

### 2.13 Wire Quit menu item
- "Quit" button in dropdown calls `NSApplication.shared.terminate(nil)`.
- **Acceptance:** Quit closes the app.

### 2.14 Implement PreferencesService
- Create `PreferencesService` class.
- Methods: `load() -> Preferences`, `save(_:) -> Void`, `resetToDefaults()`.
- Use `UserDefaults.standard` with JSON encoder/decoder.
- Key: `"com.agentawake.preferences"`.
- On decode failure, return `Preferences.defaults`.
- **Acceptance:** Preferences survive app relaunch.

### 2.15 Wire PreferencesService into AppState
- On `AppState.init`, load preferences via `PreferencesService.load()`.
- On `appState.preferences` change (via `didSet` or Combine), call `PreferencesService.save()`.
- Debounce saves to avoid thrashing (e.g., 0.5s).
- **Acceptance:** Preference changes persist automatically.

### 2.16 Add status text to dropdown
- In `MenuDropdownView`, compute status string:
  - No agents + no assertion: "Monitoring — No agents detected".
  - Agents detected: "Preventing sleep — N agent(s) active".
  - Agents detected but assertion failed: "Error preventing sleep".
- Display above the agent list.
- **Acceptance:** Status text updates in real time.

### 2.17 Add empty state to agent list in dropdown
- When `activeAgents` is empty, show secondary text:
  - "No agents running. Open Claude Code, Cursor, etc."
  - Or if no agents configured: "No agents configured. Add process names in Preferences."
- **Acceptance:** Dropdown is never blank.

### 2.18 Implement SF Symbol icon swap based on state
- `StatusIconView` observes `appState.isPreventingSleep`.
- True → `sun.max.fill` (or custom active icon).
- False → `moon` (or custom inactive icon).
- Animate transition with `.animation(.easeInOut(duration: 0.3))`.
- **Acceptance:** Icon animates smoothly on state change.

---

## Phase 3 — Agent Detection (12 tasks)

**Goal:** Detect running coding agents by process name. Handle custom agents. Output via Combine publisher.

### 3.1 Implement AgentIdentifier enum
- Define `enum AgentIdentifier: String, CaseIterable, Codable`.
- Cases: `claudeCode`, `cursor`, `codexCLI`, `geminiCLI`, `aider`, `copilot`, `custom`.
- Property `displayName: String` returning human names.
- Property `processNames: [String]` returning process names to match.
- Static `defaults: [AgentIdentifier]` returning all non-custom cases.
- **Acceptance:** Enum compiles, `AgentIdentifier.defaults` returns 6 agents.

### 3.2 Implement AgentProcess struct
- Define `struct AgentProcess: Identifiable, Hashable, Codable`.
- Properties: `id: String` (computed from pid), `identifier: AgentIdentifier`, `displayName: String`, `pid: pid_t`, `detectedAt: Date`.
- Hashable conformance based on `pid`.
- **Acceptance:** Struct compiles, two AgentProcesses with same pid are equal.

### 3.3 Implement process scanning with NSWorkspace
- Create function: `func scanRunningProcesses() -> Set<AgentProcess>`.
- Use `NSWorkspace.shared.runningApplications`.
- Filter by `.localizedName` matching any `AgentIdentifier.processNames` (case-insensitive).
- Map matched apps to `AgentProcess`.
- Return unique set.
- **Acceptance:** Function returns correct agents when processes are running.

### 3.4 Create ProcessScanService with Timer
- Define `ProcessScanService` class.
- Property: `knownAgentNames: Set<String>` (default + custom).
- Property: `scanInterval: TimeInterval` (default 3.0).
- Internal `Timer` that fires `scan()` on a background queue.
- **Acceptance:** Service runs scan on interval.

### 3.5 Add Combine publisher to ProcessScanService
- `CurrentValueSubject<Set<AgentProcess>, Never>`.
- On each scan, publish result set.
- Use `.removeDuplicates()` so subscribers only fire on actual changes.
- Expose as `AnyPublisher<Set<AgentProcess>, Never>`.
- **Acceptance:** Publisher emits only on change, not on identical scans.

### 3.6 Handle empty knownAgentNames
- If `knownAgentNames` is empty, skip scan and publish empty set.
- **Acceptance:** No crash, empty set published.

### 3.7 Implement ProcessScanService.start() / stop()
- `start()` creates and schedules Timer.
- `stop()` invalidates Timer, publishes empty set.
- Ensure timer is scheduled on RunLoop.main (or common).
- Use weak self in timer callback.
- **Acceptance:** Start and stop toggle scanning.

### 3.8 Wire ProcessScanService to AppState
- In `AppState`, create `ProcessScanService` instance.
- Subscribe to its publisher.
- On new agent set → update `activeAgents`.
- Subscribe on main thread (`.receive(on: DispatchQueue.main)`).
- **Acceptance:** `appState.activeAgents` updates when agents start/stop.

### 3.9 Implement custom agent name updates
- Method: `ProcessScanService.updateAgentNames(_ names: Set<String>)`.
- Merges default agent process names + custom names.
- Rebuilds `knownAgentNames`.
- **Acceptance:** Custom names appear in scan results.

### 3.10 Wire custom agent names to Preferences changes
- In `AppState`, subscribe to `$preferences`.
- On change, build combined set = default process names + `preferences.customAgentNames`.
- Call `processScanService.updateAgentNames(...)`.
- **Acceptance:** Adding custom name in Preferences → scanned in next cycle.

### 3.11 Optimize scan performance
- Ensure scan runs on a background serial queue.
- Use `autoreleasepool` around each scan.
- Log scan duration (debug only).
- **Acceptance:** CPU usage < 1% during scans.

### 3.12 Handle agent detection on app launch
- If agents are already running when app launches, `ProcessScanService` should detect them on first scan.
- Ensure `start()` is called in `AppDelegate.applicationDidFinishLaunching`.
- Consider an immediate (non-delayed) first scan.
- **Acceptance:** If `claude` is running before app launch, it appears in `activeAgents` within 3 seconds.

---

## Phase 4 — Sleep Prevention (12 tasks)

**Goal:** Acquire/release IOPMAssertion based on agent detection state. Handle edge cases.

### 4.1 Implement SleepManager — acquire assertion
- Create `SleepManager` class.
- Method: `func preventSleep(reason: String) -> Bool`.
- Call `IOPMAssertionCreateWithName` with `kIOPMAssertionTypeNoIdleSleep`, `kIOPMAssertionLevelOn`.
- Use `"com.agentawake.sleep-prevention"` as assertion name.
- Return `true` on success, `false` on failure.
- Store `assertionID: IOPMAssertionID?`.
- **Acceptance:** Assertion is acquired, Mac stays awake.

### 4.2 Implement SleepManager — release assertion
- Method: `func allowSleep()`.
- If `assertionID` is set, call `IOPMAssertionRelease`.
- Set `assertionID = nil`.
- Safe to call multiple times (no-op if nil).
- **Acceptance:** Assertion released, Mac can sleep.

### 4.3 Implement SleepManager — isActive
- Computed property: `var isActive: Bool { assertionID != nil }`.
- **Acceptance:** Reflects assertion state.

### 4.4 Wire ProcessScanService → SleepManager via AppState
- In `AppState`, subscribe to `ProcessScanService` publisher.
- If `activeAgents` transitions from empty → non-empty → call `sleepManager.preventSleep()`.
- If `activeAgents` transitions from non-empty → empty → call `sleepManager.allowSleep()`.
- Update `isPreventingSleep` accordingly.
- **Acceptance:** Agent launch → assertion acquired. Agent exit → assertion released.

### 4.5 Handle multiple agents correctly
- Track agent count, not just presence.
- Only release assertion when count reaches 0.
- No double-acquire (check `sleepManager.isActive` before acquiring).
- **Acceptance:** Assertion held while at least one agent runs.

### 4.6 Release assertion on app termination
- In `AppDelegate.applicationWillTerminate`, call `sleepManager.allowSleep()`.
- Also call `processScanService.stop()`.
- **Acceptance:** Assertion released when user quits.

### 4.7 Handle sleep assertion failure gracefully
- If `preventSleep()` returns false, log error.
- Set `appState.lastScanError = "Failed to prevent sleep"`.
- Show error state in menu bar (different icon or text).
- Retry on next scan cycle.
- **Acceptance:** Error state visible to user, auto-retry happens.

### 4.8 Handle assertion release failure
- Wrap `IOPMAssertionRelease` in a `guard` / check.
- If release fails (returns non-zero), log and continue.
- Not user-visible (kernel will release on process death anyway).
- **Acceptance:** No crash on release failure.

### 4.9 Subscribe to NSWorkspace.willSleepNotification
- Register for `NSWorkspace.willSleepNotification`.
- On sleep notification, release assertion if held (to prevent wake issues).
- Re-acquire on wake: register for `NSWorkspace.didWakeNotification`, re-scan agents, re-acquire if needed.
- **Acceptance:** System sleep/wake cycle handled correctly.

### 4.10 Derive assertion reason from agent names
- When acquiring, build reason string: `"Agent Awake — \(agentNames) running"`.
- Join multiple agent display names with comma.
- This appears in Activity Monitor → Energy → Prevented Sleep.
- **Acceptance:** Activity Monitor shows meaningful reason.

### 4.11 Add debug logging to SleepManager
- Log on acquire: "Preventing sleep — reason: \(reason)".
- Log on release: "Allowing sleep".
- Log on error: "Failed to acquire assertion — error code: \(code)".
- Use `os_log` with subsystem `"com.agentawake"`.
- **Acceptance:** Logs appear in Console app.

### 4.12 Verify IOPMAssertion with command line
- Manual test: run app, launch agent, run `pmset -g assertions` in terminal.
- Verify `NoIdleSleep` assertion appears with proper name.
- Kill agent, re-run command, verify assertion removed.
- **Acceptance:** Assertion lifecycle verified via `pmset`.

---

## Phase 5 — Global Hotkey (10 tasks)

**Goal:** Register Option+Command+A, lock screen on press.

### 5.1 Implement HotKeyService — register
- Create `HotKeyService` class.
- Use `CGEventTapCreate` (or `RegisterEventHotKey` via Carbon).
- Register key combination: Option (⌥) + Command (⌘) + 'A'.
- Store event tap reference.
- **Acceptance:** Hotkey registered, no crash.

### 5.2 Implement event handler — key down
- In event tap callback, check for key match.
- On match, call `SACLockScreenImmediate()`.
- Return `nil` (swallow event to prevent propagation) — or pass through (consider UX).
- **Acceptance:** Pressing ⌥⌘A locks screen immediately.

### 5.3 Handle key repeat
- Ignore key repeat events (`AXIsProcessTrusted` or check event type).
- Only fire on first key-down, not on repeat.
- **Acceptance:** Holding shortcut locks screen only once.

### 5.4 Handle CGEventTap permissions gracefully
- On macOS, `CGEventTapCreate` may fail without Accessibility permissions.
- If creation fails, log warning and fall back to `NSEvent.addGlobalMonitorForEvents(matching: .keyDown)`.
- If both fail, set `appState.hotKeyUnavailable = true`.
- Show warning in Preferences → About.
- **Acceptance:** Hotkey degrades gracefully if permissions denied.

### 5.5 Implement HotKeyService — unregister
- Method: `func unregister()`.
- `CGEventTap` → `CFMachPortInvalidate`, `CFRelease`.
- Carbon → `UnregisterEventHotKey`.
- `NSEvent` monitor → `removeMonitor`.
- Call on app termination.
- **Acceptance:** Hotkey removed when app quits.

### 5.6 Wire HotKeyService into AppDelegate
- Create `HotKeyService` instance in `AppDelegate`.
- Call `register()` in `applicationDidFinishLaunching`.
- Call `unregister()` in `applicationWillTerminate`.
- **Acceptance:** Hotkey lifecycle matches app lifecycle.

### 5.7 Test hotkey from background
- Launch app, open Terminal (so app is not focused).
- Press ⌥⌘A.
- Verify screen locks.
- **Acceptance:** Hotkey works from any app.

### 5.8 Handle hotkey in setup assistant / accessibility prompt
- If user is on macOS 14+ and CGEventTap prompts for Accessibility, show helpful message in Preferences.
- Provide instructions in About tab: "Go to System Settings → Privacy → Accessibility → add Agent Awake."
- **Acceptance:** Clear instructions available if hotkey fails.

### 5.9 Consider using NSEvent.addGlobalMonitorForEvents as primary
- Evaluate if CGEventTap complexity is warranted.
- If `NSEvent` global monitor works reliably for lock screen, prefer it.
- Decision: document which approach is used.
- **Acceptance:** Chosen approach works reliably.

### 5.10 Add hotkey display in Preferences About tab
- Show registered shortcut: "⌥⌘A → Lock Screen" in About tab.
- Indicate if hotkey is active or unavailable.
- **Acceptance:** User can see shortcut and status.

---

## Phase 6 — Launch at Login (12 tasks)

**Goal:** Implement SMAppService registration, wire to preference toggle, handle state restoration.

### 6.1 Implement LoginItemManager
- Create `LoginItemManager` class.
- Use `SMAppService.mainApp`.
- Method: `func isRegistered() -> Bool`.
- Method: `func register() throws`.
- Method: `func unregister() throws`.
- Wrap errors with meaningful messages.
- **Acceptance:** Login item can be registered and unregistered.

### 6.2 Implement LoginItemManager — sync state on init
- On init, check `SMAppService.mainApp.status`.
- Expose `@Published var isEnabled: Bool`.
- **Acceptance:** Reflects actual current state.

### 6.3 Wire LoginItemManager to Preferences toggle
- In `GeneralPreferencesTab`, toggle bound to `appState.preferences.launchAtLogin`.
- On toggle ON → call `loginItemManager.register()`.
- On toggle OFF → call `loginItemManager.unregister()`.
- On success, update `preferences.launchAtLogin`.
- On failure, show alert, revert toggle.
- **Acceptance:** Toggle controls login item registration.

### 6.4 Handle SMAppService errors
- Common errors: `SMAppServiceError.notPermitted`, `.duplicateRegistration`.
- Map to user-friendly alert messages.
- Log errors with `os_log`.
- **Acceptance:** Errors surfaced to user inline.

### 6.5 Sync login item state on app launch
- On app launch, check actual login item status.
- Sync `preferences.launchAtLogin` to match actual status (in case user changed via System Settings).
- **Acceptance:** Toggle reflects reality.

### 6.6 Add "Launch at Login" visible status in menu bar
- Optional: add secondary indicator in dropdown, e.g., "Launch at Login: Enabled".
- Not necessary for v1 — consider if spare time.
- **Acceptance:** N/A (stretch goal).

### 6.7 Handle macOS 13 vs 14 SMAppService differences
- SMAppService is available on macOS 13+.
- On macOS 13, the `.mainApp` service type works for agent apps.
- Test on macOS 13, 14, 15 for compatibility.
- **Acceptance:** Works on all targeted OS versions.

### 6.8 Implement PreferencesService — migrate legacy flag
- If old `UserDefaults.bool(forKey: "launchAtLogin")` exists, read it.
- On first launch with new schema, migrate to new storage format.
- **Acceptance:** No data loss from schema changes.

### 6.9 Handle SMAppService status polling after registration
- After `register()`, poll `status` briefly to confirm (async).
- If status remains `.notRegistered` after 1s, log warning.
- **Acceptance:** Registration confirmed async.

### 6.10 Wire login item into onboarding (first launch)
- On `Preferences.hasLaunchedBefore == false`:
  - After 5 seconds, show a small popup or tooltip: "Enable launch at login?"
  - If user clicks "Yes", toggle ON.
  - Set `hasLaunchedBefore = true`.
- **Acceptance:** First-launch prompt appears once.

### 6.11 Test full login cycle
- Enable launch at login.
- Restart Mac.
- Verify Agent Awake appears in menu bar without user intervention.
- **Acceptance:** Auto-launch works across reboots.

### 6.12 Add launch at login status to About tab
- "Login Item: Enabled" or "Login Item: Disabled".
- **Acceptance:** User can verify status.

---

## Phase 7 — Testing & Release (33 tasks)

**Goal:** Unit tests, UI tests, manual QA, code signing, notarization, DMG distribution.

### Sub-Phase 7A — Unit Tests (12 tasks)

#### 7A.1 Test AgentIdentifier matching
- Test each agent identifier returns correct process names.
- Test case-insensitive matching.
- Test default set contains 6 agents.
- **Acceptance:** All agent matching tests pass.

#### 7A.2 Test AgentProcess hash/equality
- Test two AgentProcess with same pid are equal.
- Test two AgentProcess with different pids are not equal.
- Test `detectedAt` does not affect equality.
- **Acceptance:** Hashable contract verified.

#### 7A.3 Test PreferencesService save/load cycle
- Save preferences, load from fresh instance.
- Verify all fields match.
- Test decode failure returns defaults.
- **Acceptance:** Persistence round-trip verified.

#### 7A.4 Test ProcessScanService scan behavior
- Mock `NSWorkspace.shared.runningApplications`.
- Inject mock process list.
- Verify correct agents detected.
- Verify empty set when no agents match.
- **Acceptance:** Scan logic correct.

#### 7A.5 Test ProcessScanService Combine publisher
- Start service with mocks.
- Verify publisher emits on changes only.
- Verify `.removeDuplicates()` prevents identical emissions.
- **Acceptance:** Publisher contract verified.

#### 7A.6 Test SleepManager assertion lifecycle
- Use `IOPMAssertionCreateWithName` with test assertion name.
- Verify acquisition succeeds.
- Verify release succeeds.
- Verify `isActive` returns correct state.
- **Acceptance:** Assertion lifecycle verified.

#### 7A.7 Test AppState agent → assertion wiring
- Create AppState with mock services.
- Simulate agent detection → verify `isPreventingSleep` true.
- Simulate agent removal → verify `isPreventingSleep` false.
- **Acceptance:** State machine correct.

#### 7A.8 Test AppState multiple agent scenario
- Add 2 agents → `isPreventingSleep` true.
- Remove 1 → `isPreventingSleep` still true.
- Remove last → `isPreventingSleep` false.
- **Acceptance:** Multi-agent lifecycle correct.

#### 7A.9 Test PreferencesService migration
- Write old-format UserDefaults key.
- Load with new PreferencesService.
- Verify migration occurs.
- **Acceptance:** Migration no-op or successful.

#### 7A.10 Test LoginItemManager registration
- Mock `SMAppService` (requires testability wrapper).
- Test register/unregister/isRegistered.
- Verify errors are thrown properly.
- **Acceptance:** Login item logic tested.

#### 7A.11 Test HotKeyService registration
- Test hotkey registration mock.
- Verify handler fires on matching key combo.
- Verify handler ignores non-matching combos.
- **Acceptance:** Hotkey logic tested.

#### 7A.12 Test error paths
- Simulate IOPMAssertion failure → verify state handling.
- Simulate PreferencesService decode failure → verify defaults used.
- Simulate timer nil self → verify no crash.
- **Acceptance:** Error paths handled gracefully.

### Sub-Phase 7B — UI Tests (5 tasks)

#### 7B.1 Test menu bar icon presence
- UI test: launch app, verify status item exists in menu bar.
- Use Accessibility API to query status item.
- **Acceptance:** Menu bar icon present.

#### 7B.2 Test dropdown contents
- UI test: click status item, verify dropdown opens.
- Verify status text present.
- Verify "Preferences…" and "Quit" buttons present.
- **Acceptance:** Dropdown renders correctly.

#### 7B.3 Test Preferences window
- UI test: click Preferences, verify window opens.
- Verify tabs exist and are functional.
- Verify toggle interactions.
- **Acceptance:** Preferences UI functional.

#### 7B.4 Test Quit
- UI test: click Quit, verify app terminates.
- **Acceptance:** Quit works.

#### 7B.5 Test dark mode
- UI test: switch system to dark mode.
- Verify icons and text are visible.
- Verify SF Symbols adapt.
- **Acceptance:** Dark mode supported.

### Sub-Phase 7C — Manual Testing (8 tasks)

#### 7C.1 Manual test — Claude Code detection
- Launch Claude Code in terminal.
- Verify Agent Awake detects it within 3 seconds.
- Verify sleep prevention activates.
- Quit Claude Code.
- Verify sleep prevention deactivates.
- **Acceptance:** Claude Code flow works.

#### 7C.2 Manual test — Cursor detection
- Launch Cursor with agent mode.
- Verify detection and prevention.
- Quit Cursor.
- Verify deactivation.
- **Acceptance:** Cursor flow works.

#### 7C.3 Manual test — Multi-agent scenario
- Launch Claude Code + Cursor simultaneously.
- Verify detection of both.
- Kill Claude Code.
- Verify prevention still active (Cursor still running).
- Kill Cursor.
- Verify prevention stops.
- **Acceptance:** Multi-agent flow works.

#### 7C.4 Manual test — Custom agent name
- Add "my-custom-agent" in Preferences.
- Launch a process named `my-custom-agent`.
- Verify detection and prevention.
- **Acceptance:** Custom agent flow works.

#### 7C.5 Manual test — Hotkey
- Launch app, press ⌥⌘A from any app.
- Verify screen locks.
- **Acceptance:** Hotkey works.

#### 7C.6 Manual test — Launch at login
- Enable launch at login in Preferences.
- Reboot.
- Verify app auto-launches.
- **Acceptance:** Auto-launch works.

#### 7C.7 Manual test — Sleep assertion verification
- App running with agent.
- Run `pmset -g assertions` in terminal.
- Verify `NoIdleSleep` assertion present with correct name.
- Kill agent.
- Re-run command, verify assertion gone.
- **Acceptance:** Assertion lifecycle verified via system tools.

#### 7C.8 Manual test — Battery impact
- Run app for 1 hour with no agents.
- Measure energy impact in Activity Monitor.
- Verify < 1% CPU, < 50 MB RSS.
- Run with agents active, verify similar.
- **Acceptance:** Energy impact negligible.

### Sub-Phase 7D — Release (8 tasks)

#### 7D.1 Design production app icon
- Create 16×16 and 22×22 template icon for menu bar.
- Keep simple: coffee cup, moon, or "Z" icon.
- Export as PDF or PNG for Assets.xcassets.
- **Acceptance:** App has production-quality icon.

#### 7D.2 Update Info.plist for release
- Set version to `1.0.0`.
- Set build number appropriately.
- Verify `LSUIElement` correct.
- **Acceptance:** Info.plist ready for distribution.

#### 7D.3 Code signing setup
- Obtain Developer ID Application certificate.
- Set code signing identity in Xcode.
- Enable "Hardened Runtime".
- Add entitlements: no extra required (no sandbox).
- **Acceptance:** Archive builds with valid signature.

#### 7D.4 Notarization
- Archive app in Xcode, export Developer ID-signed app.
- Submit to Apple notary: `xcrun notarytool submit`.
- Wait for processing.
- Staple ticket: `xcrun stapler staple`.
- Verify: `spctl --assess --verbose`.
- **Acceptance:** App passes Gatekeeper on clean Mac.

#### 7D.5 DMG packaging
- Create DMG using `create-dmg` or script.
- Include: `Agent Awake.app`, alias to `/Applications`, background image.
- Set DMG volume name: "Agent Awake".
- Sign DMG (optional but recommended).
- **Acceptance:** DMG mounts, drag-to-install works.

#### 7D.6 Create release script (CI-ready)
- Write `build-release.sh`:
  - Clean build, archive.
  - Export for Developer ID.
  - Notarize.
  - Staple.
  - Package DMG.
  - Verify.
- **Acceptance:** One command produces distributable DMG.

#### 7D.7 Write user documentation
- README.md with:
  - What it does.
  - How to install.
  - How to use.
  - Supported agents.
  - FAQ / troubleshooting.
- Include screenshots.
- **Acceptance:** Documentation covers all features.

#### 7D.8 GitHub release
- Create GitHub repository (if not exists).
- Push code.
- Create v1.0.0 release tag.
- Upload DMG + `RELEASE_NOTES.md`.
- **Acceptance:** Public release available.

---

## Task Summary

| Phase | Tasks | Est. Hours | Key Deliverable |
|---|---|---|---|
| 1 — Project Setup | 10 | 6 | Xcode project, basic menu bar shell |
| 2 — Menu Bar App | 18 | 16 | Full menu bar UI, preferences window |
| 3 — Agent Detection | 12 | 8 | Process scanner, Combine pipeline |
| 4 — Sleep Prevention | 12 | 8 | IOPMAssertion, wired to detection |
| 5 — Global Hotkey | 10 | 6 | ⌥⌘A → lock screen |
| 6 — Launch at Login | 12 | 8 | SMAppService, preference toggle |
| 7A — Unit Tests | 12 | 8 | Core logic coverage |
| 7B — UI Tests | 5 | 4 | Menu bar interaction coverage |
| 7C — Manual Testing | 8 | 8 | Real-agent verification |
| 7D — Release | 8 | 8 | Signed, notarized DMG |
| **Total** | **107** | **80** | **v1.0.0 release** |
