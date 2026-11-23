# Audio widgets and absolute-angle volume knob

Status: widgets, adapter, composition and input transport implemented end to
end (daemon axis producer plus frontend receiver). Real DMS audio and physical
controller acceptance remain a manual check.
Tasks are tracked in `tasks/todo.md`; contracts are in `docs/AUDIO_WIDGETS.md`.

## Scope and accepted behavior

Deliver three independent public widgets and an independent controller:

- `AppVolumeMixer`: vertical app-volume carousel, up to five unique visible
  cards: two before, selected center, two after. Fewer applications produce
  fewer cards, never duplicated padding cards. Selecting a card chooses the
  volume/mute target; this is a mixer, not an application launcher.
- `AudioOutputSelector`: independent output selection, title describing the
  selected output, LT/RT browse, A activates and Y opens supported options.
- `AudioInputSelector`: the same interaction contract for inputs, with its own
  model, selection, active-device state and pinned device list. It must work
  without mounting the output widget.
- `VolumeKnob`: reusable 270-degree absolute-angle control, independent of DMS,
  devices, applications and MPRIS. The caller binds its value and mute state.

No Home redesign, media-player rework or unrelated system controls. Reuse the
current design system, locales, input configuration and motion/style tokens.

## Current constraints and integration evidence

- Another implementation is modifying carousel/container-transform/Home files.
  Preserve that work. Re-read status and current contracts before each slice;
  never stage or overwrite another agent's changes.
- `CarouselView` is generic but currently horizontal; `WindowCarousel` owns
  window-specific behavior and must not become the audio widget base.
- DMS `AudioService` exposes nodes, stream volume/mute and default sink/source
  operations. Reuse it; do not introduce another PipeWire backend.
- Balance `AudioService.addRef()` and `removeRef()` with adapter lifetime/live
  usage. No polling to reconstruct models already supplied reactively by DMS.
- `InputManager.handleAnalog()` exists. `DconsoleBridge` currently accepts
  buttons only. Actual right-stick operation requires a verified producer and
  consumer axis contract; R3 is a button, not the analog axes.

## Module boundaries

| Module | Responsibility |
| --- | --- |
| `services/AudioControlService.qml` | Wrap DMS audio, normalize reactive app/output/input models, activate devices, route volume/mute requests by explicit key |
| `services/AudioDevicePreferences.qml` | Independent multiple input/output pins, stable ordering and persistence through DMS plugin state |
| `components/widgets/audio/AppVolumeMixer.qml` | Vertical app-volume browsing and selected-target publication |
| `components/widgets/audio/AudioOutputSelector.qml` | Independent public output widget |
| `components/widgets/audio/AudioInputSelector.qml` | Independent public input widget |
| `components/widgets/audio/AudioDeviceCarousel.qml` | Internal common presentation, not one public widget with an input/output mode switch |
| `components/widgets/audio/AudioTargetCard.qml` | Reusable selected/active/pinned/volume/mute presentation |
| `components/widgets/audio/AudioDeviceOptions.qml` | Reusable options content, supported ports/profiles and pin/unpin |
| `components/primitives/controls/VolumeKnob.qml` | Circle, pointer and 270-degree track/fill; controlled value/mute properties and request signals |
| `core/interaction/AngularKnobController.qml` | Absolute stick-angle conversion, deadzone/hysteresis, target-change rearming and forbidden-gap handling |
| `core/interaction/AngularKnobMath.js` | Pure range/angle math, no visual or service dependencies |
| `components/widgets/audio/AudioControls.qml` | Optional composition of all three independent widgets and one bound knob |

Screens assemble widgets and wire FocusZones/services; they do not draw cards
or options inline. Core never imports components, screens or services.

## Model and event contracts

Normalized audio target:

```text
{ key, kind: app|output|input, title, subtitle, volume, maxVolume,
  muted, canSetVolume, canMute, active, pinned, hasOptions }
```

- `volume` is a normalized linear value: 1.0 means 100%, not perceptual gain.
  Default limits are 0..1; any allowed boost is an explicit target capability.
- Backend objects remain in the service. UI emits requests with a stable key;
  the service resolves the current object and rejects missing/stale targets.
- Devices use stable backend names, not transient numeric IDs or labels.
- Application grouping uses available application identity with process/stream
  fallback. Do not merge unrelated unnamed streams. For a multi-stream app,
  expose maximum stream volume as its summary; an explicit volume request sets
  its current playback streams to the requested value within each stream's
  limits. Mute requests affect those streams only. Document this policy in UI
  module specs and test it against unequal stream levels.
- Widgets expose `selectedKey` and `selectedTarget`; input/output widgets also
  expose active key independently. Browsing never calls activation setters.
- Widget events: `volumeRequested(key, value)`, `muteRequested(key, muted)`,
  `activationRequested(key)` and `optionsRequested(key, sourceItem)` as relevant.
- Pinning is multi-select, independently stored for inputs/outputs. Pinned
  devices precede unpinned ones with stable relative order. Pinning never
  activates a device; retain selection by key when ordering changes. Missing
  pinned devices are not rendered as fake connected devices.
- Options expose only backend-supported actions. Capture the target key on
  opening and use the anchored container transform, existing layers/inert and
  exact focus return. Ports and card profiles must not be invented for devices
  lacking those capabilities.

## Input and knob contract

- Dashboard D-pad moves between zones; LT/RT browse within the focused widget.
  The vertical appearance of the mixer does not seize Up/Down from macro-nav.
  A activates a selected input/output; Y opens its options when that zone is
  focused. No global device activation from unrelated zones.
- R motion addresses only the caller-designated active volume target. R3 emits
  a mute toggle once per press, without changing the saved volume.
- The knob receives `value`, `minimum`, `maximum`, `muted`, `enabled` and
  `targetKey`; emits `valueRequested(value)` and `muteToggleRequested()`.
  The caller applies backend changes and feeds observed state back. No backend
  writes, service imports or invented local mute state in the primitive.
- Axes are normalized x/y in [-1,1], x right-positive and y down-positive.
  Angle is atan2(x, -y): -135 degrees = 0%, 0 degrees/up = 50%,
  +135 degrees = 100%. This is absolute angular positioning, not speed control.
- The lower 90-degree gap is excluded. Entering it retains the last accepted
  value; crossing it must not jump from 100% to 0%. Require neutral rearming
  before accepting the opposite endpoint after crossing that gap.
- Configurable radial engage/release thresholds provide hysteresis; require
  0 <= release < engage < 1. Initial proposal: engage 0.30, release 0.20.
  Inside release radius, hold volume and discard the unreliable angle.
- When the target changes, the layer becomes inert, overlay closes or the
  controller disconnects, clear engagement. Require neutral before rearming
  on a different target. Do not apply a previous target's pending event to a
  newly selected app/device. Validate finite values and clamp external input.
- Small angular jitter filtering is configurable. Smooth only visual motion,
  without turning absolute positioning into delayed or rate-based adjustment.
- Input axes, thresholds and R3 semantics belong in inputconfig/InputManager;
  motion duration/curve in MotionTokens/uiconfig; appearance in StyleTokens.
  Reuse DMS volume limits and coalesce duplicate writes without an idle timer.

## Ordered implementation slices

1. **Knob math/controller:** prove 270-degree geometry, deadzone, gap and target
   rearming before wiring hardware. Files: math, controller and focused tests.
2. **Knob primitive:** circle, pointer, thick 270-degree volume arc, mute and
   controlled API. Files: primitive, UI test, required style/motion tokens.
3. **DMS audio adapter:** real models and explicit-key setters, capability and
   stale-target handling. Files: adapter, normalization helper if needed, tests.
4. **Application mixer:** vertical generic carousel support and volume cards;
   two above/two below selected, correct counts 0..5+, stable selected key.
   Coordinate generic-carousel edits with the active implementation first.
5. **Device preferences:** stable multi-pin ordering and independent persistent
   input/output lists; backend keys rather than display names. Files: preferences,
   tests and composition-root persistence wiring.
6. **Output widget:** common device presentation plus independent output API;
   browse versus activate, volume parameter and selected-device heading.
7. **Input widget:** independent input API and state using shared presentation;
   never alter output selection/activation/pins as a side effect.
8. **Device options:** anchored Y/B panel, pin/unpin and supported ports/profiles;
   handle device disappearance and preserve source focus.
9. **Analog transport:** verify daemon producer first, specify axis schema,
   normalize/configure input and test frontend bridge and R3 routing. If backend
   axis production is absent, report the dependency rather than claiming real
   controller support from simulated events.
10. **Composition and acceptance:** assemble AudioControls and connect a knob to
    the focused widget's selected target. Provide a runnable composition/demo;
    expose it in the existing sound screen only after coordinating file ownership.
    Update docs and validate against real DMS audio and an actual controller.

Each slice is independently reviewable, tested and conventionally committed
as JoseV. <contact@jessvega.me>. Split configuration/integration edits when a
slice would exceed five implementation/test files. Do not batch unrelated work.

## Acceptance checkpoints

- After 1-2: 0/50/100% mapping, no center/drift reset, no forbidden-gap wrap,
  no writes from inert state and correct visual/backend feedback separation.
- After 3-4: selected app really controls app volume/mute; no duplicate cards
  below five apps; multi-stream grouping and disappearing targets verified.
- After 5-8: independent input/output widgets; A-only activation; multiple pins
  stable and persisted; Y options and B return work without changing selection.
- After 9-10: real R controls the correct target, R3 mutes it, target switches
  require rearming, and keyboard/mouse alternatives remain available.

## Verification and release conditions

- Focused QtTest cases for pure math, widget behavior and service contracts.
- Existing container-transform/media tests still pass; new features must not
  weaken existing checks or replace runtime dependencies with test fixtures.
- All JSON valid, diff whitespace clean, qmlls --ignore-settings reports zero
  local errors/warnings. Document external-module diagnostics separately.
- Manual DMS tests: multiple apps/streams, 0/1/2/5/6+ apps, hotplug, renamed and
  removed devices, failed activation, no audio backend and supported options.
- Physical-controller check is distinct from unit tests or synthetic axis input.
- Update root ARCHITECTURE/ROADMAP only after coordinating the concurrent edits.
  No claims of completion for features left only as unused components.

## Open choices and defaults

No blocking product questions. Device widgets are independent, apps are a
volume mixer and the stick interaction is angular/absolute as requested.
Deadzone values and card dimensions are initial configurable defaults, not
hardcoded UX requirements. The final dashboard arrangement is outside the
widget contract; supply a working composition without redesigning Home.
