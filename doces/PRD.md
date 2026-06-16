# Agent Awake — Product Requirements Document

**Version:** 1.0  
**Status:** Draft  
**Last Updated:** 2026-06-16

---

## 1. Product Overview

Agent Awake is a lightweight macOS menu bar application that automatically prevents a Mac from sleeping while supported AI coding agents are actively running. It restores normal sleep behavior the moment agents stop, and provides a global keyboard shortcut to lock the screen immediately.

---

## 2. Problem Statement

AI coding agents (Claude Code, Cursor, Codex CLI, Gemini CLI, Aider, Copilot) run long-lived terminal or editor processes. When these agents are actively performing tasks — code generation, testing, analysis — the user's Mac may enter sleep, interrupting the agent mid-task. This causes:

- Failed agent runs and wasted tokens.
- Corrupted state or incomplete operations.
- Frustration requiring manual intervention.

Existing solutions (caffeinate, Amphetamine) are either CLI-only, overly broad, or require manual toggling. There is no purpose-built tool that:

1. Detects known agents automatically.
2. Manages sleep prevention *only* while agents run.
3. Operates entirely from the menu bar without dock presence.

---

## 3. Target Users

| Persona | Description |
|---|---|
| **Claude Code Power User** | Runs Claude Code in terminal for hours daily. Needs machine awake during long code generation or refactoring sessions. |
| **Cursor User** | Uses Cursor's agent mode. Wants sleep prevention without manually managing caffeinate. |
| **Multi-Agent Developer** | Runs multiple agents (e.g., Claude Code + Aider) simultaneously. Needs coordinated sleep management. |
| **Remote / Headless Developer** | Works via SSH or remote desktop. Needs the machine to stay awake for remote agent sessions. |
| **CI / Background Runner** | Runs agents in background terminals. Wants automatic sleep management without intervention. |

---

## 4. Functional Requirements

### FR-01: Menu Bar Presence
- The app MUST display a menu bar icon (tray) at all times while running.
- The app MUST NOT appear in the Dock.
- The icon SHOULD indicate current sleep-prevention status (active / inactive).

### FR-02: Agent Detection
- The app MUST detect when supported agents are running.
- Detection scope: running processes on the system.
- The app MUST support the following agents:
  - Claude Code (`claude`)
  - Cursor (`Cursor`)
  - Codex CLI (`codex`)
  - Gemini CLI (`gemini`)
  - Aider (`aider`)
  - Copilot (`github-copilot`)
- The app SHOULD support adding custom agent process names via preferences.

### FR-03: Automatic Sleep Prevention
- When any supported agent process is detected running, the app MUST prevent macOS sleep.
- Prevention mechanism: `IOPMAssertionCreateWithName` with `kIOPMAssertionTypeNoIdleSleep`.
- When ALL supported agents exit, the app MUST release the sleep assertion.
- The app MUST handle multiple agents: prevention remains active as long as at least one agent runs.

### FR-04: Manual Lock Screen Shortcut
- Global keyboard shortcut: **Option + Command + A**
- When pressed, the app MUST immediately lock the screen via `SACLockScreenImmediate`.
- This MUST work regardless of whether the app's menu bar UI is focused.

### FR-05: Preferences Window
- Provide a simple preferences panel accessible from the menu bar dropdown.
- Preferences MUST include:
  - List of monitored agent process names (editable).
  - Toggle for "Launch at login".
  - Toggle for "Show sleep prevention notifications".
  - About section.

### FR-06: Launch at Login
- The app MUST support automatic launch at user login.
- Implementation: `SMAppService` (macOS 13+).
- The user MUST be able to toggle this on/off from Preferences.

### FR-07: Process Monitoring
- The app MUST poll or subscribe to running processes at a reasonable interval (e.g., every 2–5 seconds).
- The app SHOULD use `NSWorkspace.shared.runningApplications` or `proc_listallpids` for efficient polling.

### FR-08: Notifications (Optional)
- The app MAY show a brief system notification when sleep prevention activates or deactivates.
- This SHOULD be user-configurable (opt-out in preferences).

---

## 5. Non-Functional Requirements

| Requirement | Specification |
|---|---|
| **Platform** | macOS 13 (Ventura) or later |
| **UI Framework** | SwiftUI (native) |
| **Architecture** | Menu bar only — no Dock icon |
| **Memory footprint** | < 50 MB RSS at rest |
| **CPU usage** | < 1% CPU idle, < 5% during process scan |
| **Binary size** | < 10 MB |
| **Language** | Swift (no Objective-C where avoidable) |
| **Distribution** | Developer-signed DMG or direct `.app` bundle |
| **Privacy** | No network access. No analytics. No telemetry. |
| **Accessibility** | No accessibility permissions required (process detection via public APIs only). |

---

## 6. Constraints

- Must use `IOPMAssertionCreateWithName` for sleep prevention (requires `IOPMLib`).
- Must use `SACLockScreenImmediate` for lock screen (requires Security Foundation framework).
- Must not require root privileges.
- Must not require Accessibility API permissions.
- Must be a single binary with no bundled daemons or helper tools.

---

## 7. Success Metrics

| Metric | Target |
|---|---|
| **User-reported agent interruptions** | 0 (after installation) |
| **App uptime without crash** | > 30 days |
| **Menu bar click to response** | < 100 ms |
| **Process detection latency** | < 5 seconds from agent launch |
| **Sleep assertion release latency** | < 5 seconds from agent exit |

---

## 8. Out of Scope (v1.0)

- Cloud sync of preferences.
- Network-based sleep prevention (Wake-on-LAN).
- Integration with CI/CD pipelines.
- iOS or iPadOS companion app.
- Custom sleep prevention schedules (time-based).
