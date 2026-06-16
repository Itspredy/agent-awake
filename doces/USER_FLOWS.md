# Agent Awake — User Flows

---

## Flow 1: Installation

```
User downloads Agent Awake.dmg
  → Mounts DMG
  → Drags app to /Applications
  → Opens Agent Awake from /Applications (or Launchpad)
  → macOS Gatekeeper warning (first launch)
  → User right-clicks → Open → confirms
  → App launches in menu bar
  → Welcome menu item appears briefly
  → User sees menu bar icon (moon / coffee cup)
```

**States:**
- Before first launch: agent processes may be running, sleep prevention inactive.
- After first launch: process monitor starts, detects any active agents, begins sleep prevention if needed.

---

## Flow 2: First Launch — Onboarding

```
App launches
  → Shows menu bar icon
  → User clicks icon
  → Dropdown displays:
      - Status: "Monitoring" / "Preventing Sleep"
      - List of detected agents (if any)
      - "Preferences…"
      - "Quit"
  → No modal onboarding — zero-click setup
  → First-time user sees a brief tooltip: "Agent Awake is running"
```

**Design principle:** No onboarding wizard. The app is self-explanatory from the menu bar.

---

## Flow 3: Daily Use — Agent Starts

```
User opens terminal → runs `claude`
  → Agent Awake process scanner (every 3s)
  → Detects "claude" in running processes
  → Acquires IOPMAssertion (NoIdleSleep)
  → Menu bar icon changes:
      - Idle state: ☽ (moon, gray)
      - Active state: ☀ (sun, highlighted) or badge overlay
  → Optional: system notification "Agent Awake — Preventing sleep (Claude Code)"
  → Status in menu bar dropdown updates:
      "Preventing sleep — 1 agent active"
```

**Time budget:** < 5 seconds from agent launch to assertion acquisition.

---

## Flow 4: Daily Use — Agent Stops

```
User exits `claude` (Ctrl+C, `exit`, or close terminal tab)
  → Next process scan cycle
  → "claude" no longer in process list
  → No remaining agents detected
  → Releases IOPMAssertion
  → Menu bar icon returns to idle state
  → Optional: notification "Agent Awake — Sleep prevention stopped"
  → Dropdown shows: "Monitoring — No agents detected"
```

**Edge case:** If multiple agents run, only release when ALL are gone.

---

## Flow 5: Daily Use — Multiple Agents

```
Agent A (Claude Code) running → sleep assertion active
User opens Cursor → Cursor agent mode starts
  → Scan detects both "claude" and "Cursor"
  → Assertion remains held (no change)
User quits Claude Code
  → Scan still finds "Cursor"
  → Assertion remains held
User quits Cursor
  → Scan finds no agents
  → Assertion released
```

---

## Flow 6: Global Shortcut — Lock Screen

```
User presses ⌥⌘A (Option + Command + A)
  → System intercepts global hotkey (registered via CGEvent or Carbon HotKey API)
  → App calls SACLockScreenImmediate()
  → Screen locks immediately
  → No UI feedback from Agent Awake (screen lock is feedback)
```

**Note:** This works even if the app's menu bar is not focused. The hotkey is registered globally.

---

## Flow 7: Preferences

```
User clicks menu bar icon → selects "Preferences…"
  → Preferences window opens (small, centered, no resize)
  → Tabs or sections:
      1. Agents
         - List of process names being monitored
         - Add / Remove buttons
         - Default list pre-populated
      2. General
         - "Launch at login" toggle
         - "Show sleep prevention notifications" toggle
      3. About
         - App version, build number
         - Link to documentation
  → Changes auto-save to UserDefaults
  → Close window → preferences take effect immediately
```

---

## Flow 8: Quit

```
User clicks menu bar icon → selects "Quit"
  → If sleep prevention is active:
      → Release IOPMAssertion
  → Unregister global hotkey
  → Terminate process
```

**Warning:** Quitting while agents are active means the Mac may sleep. No confirmation dialog — user intent is explicit.

---

## Flow 9: Launch at Login — Enable

```
User opens Preferences → toggles "Launch at Login" ON
  → App registers login item via SMAppService
  → On next login (or reboot), Agent Awake launches automatically
  → App appears in menu bar, begins monitoring immediately
```

---

## Flow 10: Launch at Login — Disable

```
User opens Preferences → toggles "Launch at Login" OFF
  → App unregisters login item via SMAppService
  → Next login: app does not launch automatically
```

---

## Flow 11: App Update

```
User downloads new version DMG
  → Replaces app in /Applications
  → Launches updated app
  → Old version's UserDefaults carry over (same bundle ID)
  → No migration needed (preferences are simple key-value pairs)
  → Process monitoring resumes immediately
```
