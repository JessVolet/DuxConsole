# Audio widgets

## Public components

- `AppVolumeMixer`: independent vertical application-volume widget, at most five
  unique cards, selected center and up to two neighbors on each side. Selection
  chooses a volume/mute target; it does not launch or activate an application.
- `AudioOutputSelector`: independent output model and selection. LT/RT browse,
  A activates, Y opens options. Its heading names the selected device even when
  a different device is still active.
- `AudioInputSelector`: independent input model, selection and pinning with the
  same interaction contract. Input actions do not change output state.
- `VolumeKnob`: controlled primitive for normalized volume/mute; no service
  imports. Circle, pointer and thick 270-degree arc. It can be connected to any
  volume owner, including MPRIS, without importing the audio adapter.
- `AngularVolumeKnob`: reusable widget that composes the primitive with the
  angular input controller. Primitives never import core/interaction.
- `AudioControls`: composition of the three widgets, one knob, the active
  output/input summary, the application mixer, a media card and the action
  pills, mounted by `screens/slides/AudioScreen.qml` under the existing Sound
  tab. `AudioScreen` also mounts the existing `MediaPlayerModal` with
  `ContainerTransform`, anchored to that card.

## Sound tab layout

The composition follows the reference layout without new behavior:

- Header: screen title plus the active output and input names with their volume.
- Left stage: the absolute-angle knob with the selected target name inside the
  circle, the target title with the knob hint, and Mute/Previous/Next pills.
  Previous/Next are the mouse twin of LT/RT and call the focused carousel's
  `cycleSubItem`; no second browsing state exists.
- Right: the application mixer, reused unchanged and still the default focus.
  It is a wheel: the selected row stays in the middle and entries wrap on both
  sides (`CarouselView.cyclic`), so the first and last app still have neighbors.
- Bottom row: media card (left), output devices (center), input devices (right).
  A group with a single entry (one microphone) is centered explicitly instead
  of relying on a zero-length `PathView` path, which kept the item at x=0.
  Opening the card pushes the existing `media-player` layer through
  `mediaExpandRequested`; the screen owns that modal so widgets never import
  `screens/modals`.
- The media card adds a `sound-media` zone. While it or the media modal holds
  focus there is no audio target, so the knob stays disabled and the stick is
  ignored, matching the "authorized target" rule.
- Labels reuse existing catalog terms (`nav.sound`, `audio.*`, `media.prev/next`);
  no translation catalog was edited.

Each carousel publishes `selectedKey`, `selectedTarget` and `focusZone`.
Requests are `volumeRequested(key, value)`, `muteRequested(key, muted)`,
`activationRequested(key)` and `optionsRequested(key, sourceItem)`.
Standalone consumers connect these signals themselves; AudioControls provides
that wiring. Use distinct zone IDs for multiple instances of the same widget.

## Backend and selection

The composition root injects DMS AudioService into `AudioControlService`.
The adapter balances references while the Sound tab is live, never creates a
second PipeWire backend, and resolves every operation against current nodes.
Missing targets and unknown key kinds cannot alter another device.

Normalized snapshots contain `key`, `kind`, `title`, `subtitle`, `volume`,
`maxVolume`, `muted`, `canSetVolume`, `canMute`, `active`, `pinned`, `hasOptions`.
Volume is linear: 1.0 means 100%. Device limits are supplied by DMS. The knob's
minimum/maximum are caller-controlled, and backend limits remain authoritative.

Applications group playback streams by application identity, then binary,
process ID or stream name/ID fallback. A group displays its maximum stream
volume; setting it changes all current streams in that group to the requested
value, each clamped to its own limit. Mute affects only that group. This is not
the MPRIS player-volume API and not the global output volume.

Device keys use kind plus backend name, not a transient index. Pinned devices
sort first with stable pin order; multiple pins are allowed. Input and output
pin sets are separate. DMS plugin state persists them as `audio.inputPins` and
`audio.outputPins`. Missing pins are retained but never create fake devices.

The generic CarouselView now supports `orientation: Qt.Vertical`; horizontal
defaults and window-carousel consumers retain their previous geometry.
AudioTargetCarousel maintains a ListModel and selection key across reactive
updates, avoiding wholesale model replacement on each volume event.

## Device options

AudioDeviceOptions uses TransformSurface, the existing LayerManager and inert
contract. Its target key is captured when Y opens the panel. B returns focus.
Pinning is offered for both kinds. Output ports/profiles come directly from
DMS `outputChoices`/`activateOutputChoice`, refreshed on opening. The current
DMS facade has no equivalent generic input-port choices, so the input panel
does not invent unsupported port/profile operations. Backend failures surface
through the composition's localized error state.

## Absolute right-stick control

`AngularVolumeKnob.handleStick(x,y)` takes normalized axes, x right-positive and y
down-positive. AngularKnobController uses atan2(x,-y): lower-left (-135 degrees)
is zero, up is halfway, lower-right (+135 degrees) is full range. The lower
90-degree gap is excluded. There is no speed/rate-based volume adjustment.

- Neutral below releaseRadius preserves the last value and rearms input.
- Movement must exceed engageRadius to start; separate thresholds prevent
  chatter. `inputconfig.json.analog.right` defaults to 0.30/0.20.
- Crossing the forbidden gap, changing target, disabling the control or losing
  input requires neutral before reengagement. Invalid/nonfinite axes are ignored.
- Angular jitter filtering is configured in degrees. Repeated identical backend
  writes are discarded. No timer runs while the stick is idle.
- R3 emits a mute toggle and never overwrites the saved volume.
- The primitive emits `valueRequested`/`muteToggleRequested`; the caller applies
  changes and supplies observed value/mute back. Mouse dragging is supported.
- `theme.knobStrokeWidth` controls the arc thickness through StyleTokens.

### Transport status

The Go daemon now produces the normalized axes and the frontend consumes the
same contract. DconsoleBridge maps sticks through inputconfig, never hardcoded
physical codes:

```json
{"type":"axis","stick":"right","x":0,"y":-1,"device":"xbox"}
{"type":"status","active":true,"connected":false,"grabbed":false}
```

- The daemon normalizes each evdev range around its midpoint, `x`
  right-positive and `y` down-positive, and only sends axes while `EVIOCGRAB`
  is actually held. If capture fails, it broadcasts `grabbed:false` with
  `error:"grab_failed"` and sends no axes, so the knob cannot move while the
  game still receives the same stick.
- `connected:false` (pad unplugged) or `grabbed:false` makes the bridge reset
  InputManager, which clears controller engagement. Re-engagement always needs
  a neutral position first.
- Closing the overlay, socket loss, pad disconnect, a stalled client or daemon
  shutdown releases the grab; the kernel also releases it on process death.
  A pad that reconnects while the overlay is open is re-grabbed automatically.
- `inputconfig.json.analog.right` uses `engageRadius: 0.40` and
  `releaseRadius: 0.30`. The measured resting offset of the test pad's right
  stick is ~0.21, so the previous 0.20 release radius never armed neutral and
  would have emitted a final ~14% angle during spring-back instead of holding
  the volume. Re-measure a unit whose drift exceeds the release radius.

Hardware acceptance was checked with the physical pad: the overlay received
4574 axis samples covering x/y ±1 while a second reader of `/dev/input/event28`
received none, and a PipeWire monitor recorded the focused app volume following
the stick plus R3 muting it without changing the saved volume. Overlay close
released the grab. Physical unplug/replug is only covered by unit tests; the
daemon is still started manually rather than by a user unit.

## Verification and deployment

QtTest covers knob endpoints/neutral/gap/rearming, app grouping, volume/mute
isolation, selected versus active devices, persistence/order of multiple pins,
0/1/2/5/6-card models, stale targets, options focus return and semantic stick/R3
routing. Service and composition tests inject a fake backend and Theme.

```sh
QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME= QT_QUICK_CONTROLS_STYLE=Basic \
  /usr/lib64/qt6/bin/qmltestrunner -import tests/support -input tests/motion
```

Actual DMS audio/hotplug and physical-stick acceptance remain manual checks.
New QML files in already cached directories may require `dms restart`, not only
plugin reload. The overlay and Home design are not otherwise changed.
