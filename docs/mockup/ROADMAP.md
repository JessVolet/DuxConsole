# DuxConsole mockup roadmap

The native fixture implementation is available on the planning branch. This roadmap records functional verification and the remaining visual acceptance work.

| Stage | Status | Work and deliverable | Exit criteria |
| --- | --- | --- | --- |
| P0 | Complete | Inspect video and existing plugin, define M01–M12, dependency rules, fidelity matrix and independent audit. | Auditor reviews branch diff and planning findings have dispositions. |
| P1 | Implemented | Add an opt-in QML fixture composition, config, mock service and deterministic scene loader. Reuse the native focus and input stack. Map timestamped references to named fixtures and measure geometry and transitions. M01–M03, M12. | Opt-in QML preview opens, theme/i18n/hints resolve via config, key and pointer routes converge, layer restoration works, the fixture path opens no production sockets, and closing all layers releases exclusive keyboard focus. Reference inventory records exact frames and boundaries for visual comparison. |
| P2 | Implemented | Build Home and shared carousel with sample art and live-looking fixtures. M04–M05 and mini media from M11. | Match the Home anchors. Compare 0/1/2/4/6/7+ items, clip/fade, repeated input, missing icon and independent session/window state. |
| P3 | Implemented | Add Audio and Capture. Finish expanded player, capture viewer/settings and feedback layers. M06–M07, M11. | Compare audio, gallery, viewer, options and toast states. Confirm mocks, focus returns and unavailable-device branches. |
| P4 | Implemented | Add Launcher, Achievements and both wheels. M08–M10. | Compare all remaining named scenes including missing achievement art and wheel opened over the backdrop. Exercise command selection, cancel, modal return and keyboard release after closing a wheel opened over the bare backdrop. |
| P5 | Visual review in progress | Compare the full native sequence, address visual gaps and demonstrate reuse of shared visual widgets via a second fixture composition. All modules. | Attached parity evidence, working import in independent composition, zero unresolved blocking audit findings. |
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


## Implementation review

- The standalone Wayland smoke check covered each of the five slides, the Home capture options state, capture image and video viewers, a missing-achievement preview, both wheels and the wheel over the bare backdrop.
- Semantic input checks exercised Home counts 0, 1, 2, 4, 6, 7 and 8, Select expansion, Refuse, and wheel dismissal with the dashboard closed. After browsing Capture, Launcher and Achievements details with the D-pad, each dashboard retained its original ID. The wheel could not open over Capture's named modal.
- QueueCarousel is used with independent window, gallery, device, library and achievement models. The track renderer is shared between Home and Audio, and Capture settings is reused from both Home and Capture.
- The independent reviewer approved the corrected layer and selection logic. It reviewed fixture isolation, the wheel layer guard, the shared Home capture options and the shortcut access guard.
- Visual acceptance is still open. The reference/render comparisons at 1920 × 1080 and layout captures at 1600 × 900 and 1280 × 720 expose differences in wheel profile detail, typography and some panel proportions. The backdrop and art are original fixtures by design. The per-region 2% acceptance and timed motion comparison remain unverified. The semantic path was exercised via IPC, and physical controller, pointer and assistive-technology acceptance remain to be demonstrated.
- Final Wayland sweep collected 45 scene/action states. The runtime log contained no local QML warnings or errors. `qmlls --ignore-settings` returned diagnostics for all 56 changed application QML files. Its only warning was the static `PanelWindow` backend diagnostic, which the Wayland run resolved. All 13 configuration, locale and fixture JSON files parsed.

## P5 measurements

- At 1920 × 1080, the upper/lower bright glyph bounds for the Capture title at 01:01 were y=147/179 in the reference. The first native render was y=117/139. After moving and enlarging the title, the native bounds were y=147/176. Title bounds were estimated from bright pixels in the heading region, excluding the top bar and action cards.
- The Home shelf reference starts moving around 00:23.83 and the first change finishes around 00:24.17. A native capture sequence confirms edge fade and shift during the same semantic action. Frequent frame grabs changed native rendering cadence, so that sample cannot certify equal timing.
- A direct cold start revealed a late-injection bug in the screen loader. The backend pointers now stay bound to the host loaders, and a fresh native render showed Home populated before any IPC scene switch.
