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
- `AudioControls`: optional composition of all three widgets and one knob,
  mounted by `screens/slides/AudioScreen.qml` under the existing Sound tab.

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

### Transport status: frontend ready, physical producer pending

InputManager validates normalized axes. DconsoleBridge accepts this proposed
message and maps the stick through inputconfig, never hardcoded physical codes:

```json
{"type":"axis","stick":"right","x":0,"y":-1,"device":"xbox"}
```

The checked local daemon (`dconsole/internal/gamepad/evdev.go`) currently emits
button events only and ignores ABS_RX/ABS_RY. This frontend does not make a
physical right stick work until that separate producer is implemented. No
files in the daemon repository were changed. Socket loss and input reset clear
engagement; a connected=false status message is also accepted by the frontend.
Synthetic normalized input tests are not a hardware test.

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
