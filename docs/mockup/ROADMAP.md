# DuxConsole mockup roadmap

The planning branch stages documentation first. Implementation starts in a later turn when the scope is accepted. Track state and review evidence here at each increment.

| Stage | Status | Work and deliverable | Exit criteria |
| --- | --- | --- | --- |
| P0 | Documentation | Inspect video and existing plugin, define M01–M12, dependency rules, fidelity matrix and independent audit. | Auditor reviews branch diff and planning findings have dispositions. |
| P1 | Planned | Add an opt-in QML fixture composition, config, mock service and deterministic scene loader. Reuse the native focus and input stack. Map timestamped references to named fixtures and measure geometry and transitions. M01–M03, M12. | Opt-in QML preview opens, theme/i18n/hints resolve via config, key and pointer routes converge, layer restoration works, the fixture path opens no production sockets, and closing all layers releases exclusive keyboard focus. Reference inventory records exact frames and boundaries for visual comparison. |
| P2 | Planned | Build Home and shared carousel with sample art and live-looking fixtures. M04–M05 and mini media from M11. | Match the Home anchors. Compare 0/1/2/4/6/7+ items, clip/fade, repeated input, missing icon and independent session/window state. |
| P3 | Planned | Add Audio and Capture. Finish expanded player, capture viewer/settings and feedback layers. M06–M07, M11. | Compare audio, gallery, viewer, options and toast states. Confirm mocks, focus returns and unavailable-device branches. |
| P4 | Planned | Add Launcher, Achievements and both wheels. M08–M10. | Compare all remaining named scenes including missing achievement art and wheel opened over the backdrop. Exercise command selection, cancel, modal return and keyboard release after closing a wheel opened over the bare backdrop. |
| P5 | Planned | Compare the full native sequence, address visual gaps and demonstrate reuse of shared visual widgets via a second fixture composition. All modules. | Attached parity evidence, working import in independent composition, zero unresolved blocking audit findings. |
| Follow-up | Separate scope | Assess production service integration or a reusable web extraction after native parity and user review. | Agree on scope, reuse plan, runtime dependencies and independent implementation review. |

## Action plan for every increment

1. Start from the stage's fixture and acceptance scene. Snapshot the video timestamp and state. Build from primitive to widget to screen, then connect the adapter at the app root.
2. Validate config/locales, run QML diagnostics and verify compose/open/close in Quickshell. Capture the states in the spec. For any separately requested web extraction, run its TypeScript, build and browser checks. Exercise keyboard and pointer plus a supported gamepad when available. Check the console and compare the exact frame geometry, motion and recorded deviations.
3. Request a fresh read-only review from an independent agent. Give it the base/head diff, module IDs, QML/config changes (and CSS/TS changes for web extraction) and validation artifacts. It reports blocking findings with file, line, contract and concrete fix. Resolve blockers, rerun affected checks and return the revised diff for approval.
4. Commit a conventional change as `JoseV. <contact@jessvega.me>`. Record the resulting hash, exact reference frames, validation results and audit verdict here or link the stage's evidence. If the diff changes after approval, request a fresh review for the changed scope.

Reinvoke the independent reviewer on future work sessions. Use the repository's JSON and `qmlls --ignore-settings` checks required by root `AGENTS.md`. Include native runtime verification whenever a QML stage changes plugin behavior.

## P0 review record

Independent review: approved with observations. The plan now includes the capture viewer variants, wheel-only host lifecycle and exclusive keyboard release in P1/P4. JSON validation passed for the six root configuration and locale files.

Baseline `qmlls --ignore-settings` reported on 43 QML files. It found existing diagnostics in `ActionHints.qml`, `TopBar.qml`, `CircularProgressGlyph.qml`, `ItemOptionsModal.qml` and `ConsoleOverlay.qml`. In P1, verify the `PanelWindow` diagnostic against the running Quickshell environment and clear the local warnings in components touched by each stage. The planning diff contains only Markdown.
