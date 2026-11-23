# Anchored container transform

## Contract

`core/motion/ContainerTransform.qml` owns geometry and progress only. It never
imports UI or services. `components/primitives/surfaces/TransformSurface.qml`
adds the reusable surface and an optional stationary origin delegate.

- Place the transform in a viewport-sized overlay host, without anchors on the
  transform itself. Its `x`, `y`, `width` and `height` are animation outputs.
- Pass `sourceItem`, or set `sourceRect` in the host's coordinate space.
  Opening captures the source with `mapToItem`; closing uses the same snapshot.
  Reversing mid-flight does not recapture the source or recreate the content.
- Keep the source mounted. Hide its drawing during the transform, not its host.
  If the source moves while open, closing returns to the captured location.
- `anchorOffset` is the original anchor in the animated container's local
  coordinates. `originContent` uses it to keep a glyph stationary throughout
  both directions. A Y/B glyph should resolve `I.Options`/`I.Refuse` through
  `InputGlyph`; input handling belongs to the consumer, never the transition.
- `horizontalDirection`: `auto`, `left`, `right`, `center`.
  `verticalDirection`: `auto`, `up`, `down`, `center`.
  Auto grows toward the viewport half with more room.
- Requested size is constrained to `bounds`. Bounds take priority over the
  chosen expansion edge. The anchor remains fixed, but callers must keep the
  source inside the viewport and ensure its delegate fits the destination.
- Global defaults live in `uiconfig.json.containerTransform`; per-instance
  properties override them. Duration/curve live under `animations` and honor
  global enable, suppression and speed through `MotionTokens`.
- `shape`: `slanted`, `rounded`, `rectangle`. Slanted angles default to
  `StyleTokens.skewAngle`; source/target angles and radii may differ.
- `contentOpacity` stages detail presentation. Bind detail `enabled` to
  `contentReady`; hidden content must not respond during opening or closing.
- `LayerManager`, `inert`, focus restoration and scrim remain consumer-owned.
  A shape transition must never push/pop layers or steal input by itself.

## Composition

```qml
TransformSurface {
    id: menuTransform
    sourceItem: optionsButton
    motionTokens: screen.motionTokens
    styleTokens: screen.styleTokens
    expanded: screen.optionsOpen
    expandedSize: Qt.size(340, 300)
    horizontalDirection: "auto"
    verticalDirection: "auto"
    originContent: Component {
        InputGlyph {
            action: menuTransform.expanded ? "I.Refuse" : "I.Options"
            iconsPadManager: screen.iconsPadManager
        }
    }
    OptionsContent {
        anchors.fill: parent
        opacity: menuTransform.contentOpacity
        enabled: menuTransform.contentReady
    }
}
```

`OptionsContent` denotes a consumer widget, not a newly introduced global type.
Leave room for the origin delegate when arranging details.

## Surface compatibility and audit

Audit baseline: `cad01cb..b137963`. Media progress, lyrics and icon resolution
are modularized. The unused Effects import in MediaProgressBar was removed.
The previous horizontal safe inset used half the full-height shear despite a
top-origin shear; it now reserves the full displacement. Existing SlantedImage
and MediaLyricsPanel masks use independent compensation and retain their
existing behavior; migrating them is not required for the new transition.

`SlantedSurface.contained` is opt-in. It fits the inclined shape inside its
declared rectangle, keeps content upright, and reserves symmetric safe insets
plus `contentPadding`. Extreme slopes are limited to leave a nonnegative
interior. Legacy surfaces keep their original drawing geometry. Do not add
external shear compensation to a contained surface.

The new transition is available for composition; existing media/options modals
are not automatically migrated. No claim of real compositor performance is
made from geometry tests alone.

## Verification

```sh
QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME= QT_QUICK_CONTROLS_STYLE=Basic \
  /usr/lib64/qt6/bin/qmltestrunner -import tests/support -input tests/motion
```

Tests cover all four viewport corners, exact anchor coordinates during motion,
reverse mid-flight, oversize destinations and disabled animation.
Surface composition tests use a minimal Theme fixture because the standalone
Qt test runner does not load Quickshell's embedded plugin. They exercise the
actual surface/transform components, not DMS integration or shader rendering.
