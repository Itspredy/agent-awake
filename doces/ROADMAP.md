# Agent Awake — Development Roadmap & Milestones

---

## Release Cadence

| Phase | Duration | Goal |
|---|---|---|
| Alpha | 2 weeks | Core functionality: detection + sleep prevention + hotkey |
| Beta | 2 weeks | Polish, edge cases, testing, signing |
| GA (v1.0) | — | Public release |

---

## Milestones

### M1 — Project Scaffold (Days 1–2)

| Task | Deliverable |
|---|---|
| Create Xcode project | SwiftUI target, macOS 13+, no sandbox |
| Configure `Info.plist` | `LSUIElement = YES`, bundle ID, version |
| Set up `AgentAwakeApp.swift` | `@main` with `NSApplicationDelegateAdaptor` |
| Set up `AppDelegate.swift` | Empty `NSStatusBar` with placeholder icon |
| Configure code signing | Developer cert, matching bundle ID |
| **Acceptance:** | App launches, shows menu bar icon, no dock icon |

### M2 — Process Detection (Days 3–5)

| Task | Deliverable |
|---|---|
| Implement `AgentIdentifier` enum | All 6 default agents with process names |
| Implement `AgentProcess` model | Struct with pid, identifier, detectedAt |
| Implement `ProcessScanService` | Timer-based polling, Combine publisher |
| Implement scan algorithm | `NSWorkspace.shared.runningApplications` match |
| Unit tests for edge cases | Zero matches, multiple matches, case sensitivity |
| **Acceptance:** | Service emits correct agent sets when processes are launched/killed |

### M3 — Sleep Management (Days 6–7)

| Task | Deliverable |
|---|---|
| Implement `SleepManager` | `IOPMAssertionCreateWithName` wrapper |
| Wire `ProcessScanService` → `SleepManager` | Auto-acquire/release on agent state change |
| Handle app termination | Release assertion on quit |
| Unit tests | Assertion acquire/release lifecycle |
| **Acceptance:** | Mac stays awake when agent runs, sleeps normally when none |

### M4 — Menu Bar UI (Days 8–10)

| Task | Deliverable |
|---|---|
| Implement `MenuBarView` | StatusItem with SwiftUI `NSHostingView` |
| Implement `StatusIconView` | Active/inactive icons using SF Symbols |
| Implement `MenuDropdownView` | Agent list, status text, Preferences/Quit buttons |
| Implement `PreferencesWindow` | `NSWindow` with SwiftUI content |
| Implement `AgentsPreferencesTab` | Editable list of process names |
| Implement `GeneralPreferencesTab` | Launch at login + notification toggles |
| Implement `AboutPreferencesTab` | Version info |
| **Acceptance:** | Full menu bar interaction works, preferences persist |

### M5 — Global Hotkey (Days 11–12)

| Task | Deliverable |
|---|---|
| Implement `HotKeyService` | Register ⌥⌘A via `CGEventTap` or Carbon |
| Wire to `SACLockScreenImmediate` | Lock screen on key press |
| Handle teardown | Unregister on quit |
| Test edge cases | Key repeat, other apps using same shortcut |
| **Acceptance:** | Option+Command+A locks screen from any app |

### M6 — Launch at Login (Day 13)

| Task | Deliverable |
|---|---|
| Implement `LoginItemManager` | `SMAppService.mainApp` wrapper |
| Wire to preferences toggle | Register/unregister on change |
| Test login cycle | Reboot, verify auto-launch |
| **Acceptance:** | Toggle enables/disables login item, survives reboot |

### M7 — AppState Integration (Day 14)

| Task | Deliverable |
|---|---|
| Implement `AppState` | ObservableObject with all published state |
| Wire all services to AppState | Combine subscriptions |
| Implement `PreferencesService` | Codable persistence via UserDefaults |
| Handle state restoration | Load preferences on launch, apply immediately |
| **Acceptance:** | End-to-end flow: agent launch → detect → assert → UI update → agent exit → release |

### M8 — Polish & Hardening (Days 15–19)

| Task | Deliverable |
|---|---|
| Notification on state change | `UNUserNotificationCenter` (opt-in) |
| Menu bar icon design | Custom template image (active/inactive) |
| Handle macOS sleep/wake events | Re-scan on wake, re-acquire if needed |
| Handle agent crash/kill edge cases | Process death detection |
| CPU optimization | Ensure < 1% idle usage |
| Dark mode support | SF Symbols adapt automatically |
| Accent color support | System-color-aware icons |
| **Acceptance:** | App runs for 24h without issues, < 50 MB memory |

### M9 — Testing & QA (Days 20–24)

| Task | Deliverable |
|---|---|
| Unit tests for all services | > 80% code coverage |
| UI tests for menu bar interactions | Click, preferences, quit |
| Manual testing matrix | 6 agents × 3 macOS versions (13, 14, 15) |
| Edge case testing | 0 agents, 1 agent, 5 agents simultaneously |
| Power/battery impact measurement | Verify negligible drain |
| **Acceptance:** | All tests pass, manual QA sign-off |

### M10 — Release (Days 25–28)

| Task | Deliverable |
|---|---|
| App icon design | Standard macOS menu bar icon |
| Code signing | Developer ID (not App Store) |
| Notarization | Submit to Apple notary |
| DMG packaging | `create-dmg` or scripted build |
| Documentation | README with screenshots, usage guide |
| Distribution | GitHub Releases / website download |
| **Acceptance:** | Notarized DMG available, users can download and run |

---

## Release Plan

### v1.0 (GA)
- All features described in PRD.
- Signed, notarized, distributable DMG.
- Public availability.

### v1.x (Post-GA — Future)
- Custom hotkey configuration.
- Per-agent monitoring toggle.
- Dark mode icon variants.
- Telemetry (opt-in, privacy-preserving).

### v2.0 (Future)
- Network-based wake prevention (Wake-on-LAN).
- CLI companion tool (`agentawake status`, `agentawake manual on/off`).
- Electron/VS Code extension companion (for deeper Cursor/Copilot integration).
- Swift Dashboard widget.

---

## Effort Estimates

| Milestone | Days | Developer |
|---|---|---|
| M1 — Scaffold | 2 | 1 |
| M2 — Process Detection | 3 | 1 |
| M3 — Sleep Management | 2 | 1 |
| M4 — Menu Bar UI | 3 | 1 |
| M5 — Global Hotkey | 2 | 1 |
| M6 — Launch at Login | 1 | 1 |
| M7 — AppState Integration | 1 | 1 |
| M8 — Polish & Hardening | 5 | 1 |
| M9 — Testing & QA | 5 | 1 |
| M10 — Release | 4 | 1 |
| **Total** | **28 days** | **1 FTE** |

---

## Dependencies

All milestones are sequential except:
- M5 (Hotkey) is independent of M4 (UI) — can be parallelized.
- M6 (Login Item) depends on M4 (Preferences window), but the service can be built independently.
