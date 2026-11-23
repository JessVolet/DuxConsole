# Audio widgets implementation checklist

All tasks below are pending. Contract and dependency details: `plan.md`.

## 1. Angular knob controller (S; no dependencies)
- [ ] Implement pure angle/range math and configurable engagement state.
- [ ] Verify top=50%, endpoints=0/100%, drift, forbidden gap and target rearming.
- [ ] Verify inactive/disconnected state emits no volume changes.

## 2. Controlled knob primitive (M; depends on 1)
- [ ] Implement circle, pointer and thick 270-degree volume arc.
- [ ] Expose value/mute inputs and request signals without service coupling.
- [ ] Test backend feedback, R3 mute semantics and disabled animations.

## Checkpoint A
- [ ] Focused controller/primitive tests pass before audio integration.

## 3. DMS audio adapter (M; independent of 1-2)
- [ ] Normalize live app/output/input models and explicit-key setters.
- [ ] Test unequal app streams, device capabilities and stale target rejection.
- [ ] Balance service references without introducing polling or another backend.

## 4. Vertical application volume mixer (M; depends on 3)
- [ ] Render up to five unique apps, selected at center with two on each side.
- [ ] Publish the selected volume/mute target; keep D-pad macro navigation.
- [ ] Test counts 0/1/2/5/6+, hot removal and stable selected identity.

## Checkpoint B
- [ ] Demonstrate real app-volume changes through the selected app target.

## 5. Independent multi-pin preferences (M; depends on 3)
- [ ] Persist independent input/output pin sets with stable device keys.
- [ ] Test stable ordering, multiple pins, missing devices and selection retention.

## 6. Output selector (M; depends on 3, 5)
- [ ] Create independent output widget and common internal presentation.
- [ ] Test selected heading, LT/RT browsing and A-only activation.
- [ ] Expose individual volume/mute requests without embedding a knob/backend.

## 7. Input selector (S; depends on 3, 5, 6 internal presentation)
- [ ] Create independent input widget with separate selection/activation state.
- [ ] Test that input actions never mutate output state or pins.
- [ ] Expose selected input volume/mute and supported-options capability.

## 8. Device options (M; depends on 6-7)
- [ ] Open supported options and pin/unpin with Y and anchored transform.
- [ ] Test ports/profiles, disappeared target and exact B focus return.

## Checkpoint C
- [ ] Both independent device widgets work alone and together against DMS.

## 9. Right-stick transport (M; depends on verified daemon axis contract, 1)
- [ ] Verify producer/schema; normalize axes and configure semantic routing.
- [ ] Test bridge input validation, deadzone/hysteresis and one-shot R3.
- [ ] Verify shutdown/inert/disconnect resets and no stale target writes.

## 10. Runnable composition and acceptance (M; depends on 1-9)
- [ ] Wire focused widget selection to the shared controlled knob.
- [ ] Demonstrate app/output/input volume and mute with actual hardware.
- [ ] Update architecture/roadmap and record tests and runtime limitations.

## Final checkpoint
- [ ] Focused and existing regression tests pass; JSON and qmlls are clean.
- [ ] Concurrent changes remain intact and only owned changes are committed.
- [ ] Conventional commits use JoseV. <contact@jessvega.me>.
