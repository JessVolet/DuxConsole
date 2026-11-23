# Audio widgets implementation checklist

Implementation slices 1–8 and the runnable Sound composition are implemented.
Physical daemon axis production and real DMS/controller acceptance are pending.
Contract and dependency details: `plan.md`; implementation: `docs/AUDIO_WIDGETS.md`.

## 1. Angular knob controller (S; no dependencies)
- [x] Implement pure angle/range math and configurable engagement state.
- [x] Verify top=50%, endpoints=0/100%, drift, forbidden gap and target rearming.
- [x] Verify inactive/disconnected state emits no volume changes.

## 2. Controlled knob primitive (M; depends on 1)
- [x] Implement circle, pointer and thick 270-degree volume arc.
- [x] Expose value/mute inputs and request signals without service coupling.
- [x] Test backend feedback, R3 mute semantics and disabled animations.

## Checkpoint A
- [ ] Focused controller/primitive tests pass before audio integration.

## 3. DMS audio adapter (M; independent of 1-2)
- [x] Normalize live app/output/input models and explicit-key setters.
- [x] Test unequal app streams, device capabilities and stale target rejection.
- [x] Balance service references without introducing polling or another backend.

## 4. Vertical application volume mixer (M; depends on 3)
- [x] Render up to five unique apps, selected at center with two on each side.
- [x] Publish the selected volume/mute target; keep D-pad macro navigation.
- [x] Test counts 0/1/2/5/6+, hot removal and stable selected identity.

## Checkpoint B
- [ ] Demonstrate real app-volume changes through the selected app target.

## 5. Independent multi-pin preferences (M; depends on 3)
- [x] Persist independent input/output pin sets with stable device keys.
- [x] Test stable ordering, multiple pins, missing devices and selection retention.

## 6. Output selector (M; depends on 3, 5)
- [x] Create independent output widget and common internal presentation.
- [x] Test selected heading, LT/RT browsing and A-only activation.
- [x] Expose individual volume/mute requests without embedding a knob/backend.

## 7. Input selector (S; depends on 3, 5, 6 internal presentation)
- [x] Create independent input widget with separate selection/activation state.
- [x] Test that input actions never mutate output state or pins.
- [x] Expose selected input volume/mute and supported-options capability.

## 8. Device options (M; depends on 6-7)
- [x] Open supported options and pin/unpin with Y and anchored transform.
- [x] Test ports/profiles, disappeared target and exact B focus return.

## Checkpoint C
- [ ] Both independent device widgets work alone and together against DMS.

## 9. Right-stick transport (M; depends on verified daemon axis contract, 1)
- [x] Verify producer/schema; normalize axes and configure semantic routing.
- [x] Test bridge input validation, deadzone/hysteresis and one-shot R3.
- [x] Verify shutdown/inert/disconnect resets and no stale target writes.
- [ ] Physical stick moves the selected target and R3 mutes it on real hardware.

## 10. Runnable composition and acceptance (M; depends on 1-9)
- [x] Wire focused widget selection to the shared controlled knob.
- [ ] Demonstrate app/output/input volume and mute with actual hardware.
- [x] Update architecture/roadmap and record tests and runtime limitations.

## Final checkpoint
- [ ] Focused and existing regression tests pass; JSON and qmlls are clean.
- [ ] Concurrent changes remain intact and only owned changes are committed.
- [ ] Conventional commits use JoseV. <contact@jessvega.me>.
