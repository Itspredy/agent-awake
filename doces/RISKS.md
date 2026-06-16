# Agent Awake — Risks & Edge Cases

---

## 1. Technical Risks

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | `IOPMAssertionCreateWithName` fails (e.g., macOS denies) | Low | Sleep prevention broken silently | Log failure, show error in menu bar dropdown, retry on next scan cycle |
| R2 | `CGEventTap` requires Accessibility permissions on newer macOS versions | Medium | Hotkey doesn't work | Fallback to `NSEvent.addGlobalMonitorForEvents`; document requirement in README |
| R3 | `SMAppService.register()` fails (quarantine, MDM policy) | Low | Launch at login doesn't work | Log failure; show inline error in Preferences; no crash |
| R4 | Process scan misses agents running under different user (e.g., `sudo`) | Medium | Agent not detected | Document that agents must run as same user; future: scan all users via `proc_listallpids` |
| R5 | macOS updates change IOPMAssertion behavior | Low | Sleep prevention may not work | Regression test on each new macOS beta during development |
| R6 | High-frequency polling drains battery | Low | Increased power usage | Default scan interval 3s; make configurable via hidden preference |
| R7 | Memory leak in `NSWorkspace.shared.runningApplications` publisher | Low | Gradual memory growth | Weak references; profile with Instruments before release |

---

## 2. UX Risks

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R8 | User doesn't know app is running | Medium | No awareness of sleep prevention | Distinctive menu bar icon; optional notification on state change |
| R9 | User quits app and forgets → Mac sleeps during agent session | Medium | Agent interruption | Show confirmation warning if quitting while agents are active (v2) |
| R10 | Multiple apps asserting NoIdleSleep conflict | Low | Mac stays awake unexpectedly | This is expected behavior — `IOPMAssertion` is additive |
| R11 | User disables launch at login, reboots, forgets to launch app | Medium | No sleep prevention | Strong visual cue in menu bar; onboarding tooltip |

---

## 3. Edge Cases

| # | Edge Case | Expected Behavior |
|---|---|---|
| EC1 | **Agent starts during sleep assertion** | Next scan cycle (≤3s) detects it; assertion already held, no change needed. |
| EC2 | **Agent crashes (SIGKILL)** | Process disappears from `runningApplications`; next cycle detects absence → releases assertion. |
| EC3 | **Multiple instances of same agent (e.g., 2 terminal tabs with `claude`)** | Detected as 2 `AgentProcess` entries (different PIDs); assertion held while count > 0. |
| EC4 | **Agent launched via SSH session on same machine** | If the process runs under same user UID, it will be detected. If different user, not detected (see R4). |
| EC5 | **macOS enters sleep while app holds assertion** | Assertion type `NoIdleSleep` should prevent this. If user forces sleep (lid close), `applicationWillSleep` notification fires → release assertion to avoid wake issues. |
| EC6 | **User changes agent names in Preferences while agents are running** | ProcessScanService updates monitored set; next cycle re-evaluates with new names. |
| EC7 | **App launched while agents are already running** | Initial scan immediately detects them; assertion acquired within 3 seconds of launch. |
| EC8 | **App crashes** | `IOPMAssertion` is associated with process; if app crashes, the kernel auto-releases it. Mac returns to normal sleep behavior. |
| EC9 | **Agent process name collision (non-agent app with same name)** | Edge: any app named "cursor" or "claude" would trigger prevention. Mitigation: document that users should not add generic names. Future: bundle ID or path matching. |
| EC10 | **Battery vs. AC power** | `NoIdleSleep` works identically on both. No special handling needed. |
| EC11 | **Screen lock hotkey collides with another app's shortcut** | Both handlers fire; `SACLockScreenImmediate` is called (harmless even if screen already locked). |
| EC12 | **Agent running inside Docker/VM on the same machine** | Not detected (Docker/VM processes are separate). Out of scope for v1. |
| EC13 | **Fast user switching** | App runs in user session; only detects processes in that session. If another user runs an agent, it won't be detected. Acceptable limitation for v1. |
| EC14 | **Agent runs headless via launchd** | If the process name matches and runs under the user's UID, it will be detected. |
| EC15 | **User removes all agent names from Preferences** | Monitored set = empty; sleep prevention never activates. Dropdown shows "No agents configured — add process names in Preferences." |

---

## 4. Failure Modes & Recovery

| Failure | Symptom | Recovery |
|---|---|---|
| Assertion acquisition failure | `isPreventingSleep` stuck false, agent running | Auto-retry every scan cycle; log failure; show warning icon in menu bar |
| Assertion release failure | `isPreventingSleep` stuck true, no agents | Force-release on app quit; log to console |
| Hotkey registration failure | ⌥⌘A does nothing | Log warning; show indicator in Preferences → About |
| Service crash (unlikely, isolated) | ProcessScanService timer stops | Timer runs on main run loop; crash would be in assertion code only — handled via try/catch |
| UserDefaults corruption | Preferences reset to defaults | Load with fallback to `Preferences.defaults` on decode failure |

---

## 5. Privacy & Security Risks

| # | Risk | Mitigation |
|---|---|---|
| PR1 | App could be used to keep Mac awake maliciously | App cannot hide; always visible in menu bar; user must explicitly keep it running; no persistent background daemon |
| PR2 | Process scanning reveals running apps | Data stays on-device; no network access; no telemetry |
| PR3 | Screen lock hotkey could be triggered accidentally | Unlikely combo (⌥⌘A); locks screen immediately but user can unlock with password |

---

## 6. Platform-Specific Risks (macOS)

| # | Risk | Mitigation |
|---|---|---|
| PS1 | macOS 13 vs 14 vs 15 API differences | Compile with macOS 13 SDK; weak-link macOS 14+ APIs if used |
| PS2 | `LSSharedFileList` deprecated in macOS 13+ | Use `SMAppService` (available macOS 13+) |
| PS3 | Gatekeeper / notarization issues | Pre-submit to Apple notary; test on clean macOS install |
| PS4 | System Integrity Protection (SIP) blocking C API calls | `IOPMAssertion` and `SACLockScreenImmediate` are public APIs, not blocked by SIP |
