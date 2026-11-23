# AGENTS.md — Reglas de Ingeniería para `DuxConsole`

Guía operativa estricta para cualquier agente de código o desarrollador que trabaje en `quickshell/dms-plugins/DuxConsole/`.

---

## 1. Regla Anti-UI Inline (Modularidad Estricta)

- **Prohibido** construir botones, tarjetas, barras de hints o modales inline con `StyledRect`/`StyledText`/`Row` repetidos dentro de `screens/slides/`, `screens/modals/` o `screens/overlays/`.
- Las pantallas (`screens/`) **solo** ensamblan `components/widgets/` y `components/primitives/`, enlazan datos de `services/` y conectan vecinos de `FocusZone` (`navUp`, `navDown`, `navLeft`, `navRight`).
- Si una pantalla necesita un control que aún no existe (botón, tarjeta, slider, barra de hints, modal), **primero** se crea el componente reutilizable en `components/primitives/`, `components/chrome/`, `components/widgets/` o `screens/modals/`, y luego se consume desde la pantalla.

---

## 2. Regla de Cero Hardcodeo (Data-Driven)

- **Teclas y botones** → `inputconfig.json` vía `core/shell/InputManager.qml`.
- **Iconos y glifos** → `iconsconfig.json` + `assets/InputIcons/` vía `core/shell/IconsPadManager.qml` y `components/primitives/glyphs/InputGlyph.qml`.
- **Textos visibles** → `locales/<lang>.json` vía `core/shell/I18n.qml` (`tr(key, fallback)` en `ScreenBase`).
- **Tiempos y curvas de animación** → `uiconfig.json` vía `core/motion/MotionTokens.qml` / `MotionManager` (respetando siempre `animations.enabled` y `animations.speed`).

---

## 3. Dirección de Dependencias (Inmutable)

```text
screens/               ──▶ components/, core/, services/
components/widgets/    ──▶ components/primitives/, core/interaction/, core/motion/
components/primitives/ ──▶ core/motion/, qs.Common, qs.Widgets
core/                  ──▶ (NUNCA importa components/, screens/ ni services/)
```

- **Única excepción permitida**: `core/shell/ConsoleOverlay.qml` actúa como *Composition Root* y puede importar `../../components/chrome` (para montar `Bg` y `FocusRing`) y `../../services` (para conectar `DconsoleBridge`).

---

## 4. Filosofía ControlFriendly

- **Macro-navegación** entre zonas/secciones: `I.Dpad.*`.
- **Micro-navegación rápida** dentro de listas, carruseles o selectores: `I.ActionOption.L` / `I.ActionOption.R` (`LT`/`RT`) sin robar la cruceta.
- **Expansión a vista completa**: `I.Select` empuja una capa al `LayerManager` (activando la regla `inert` sobre la capa inferior), donde `I.Dpad.*` toma el control total y `I.Refuse` ejecuta `pop()` restaurando el foco exacto de origen.

---

## 5. Flujo de Trabajo y Validación Obligatoria

- Antes de cerrar cualquier tarea:
  1. Validar sintaxis de todos los `.json` (`inputconfig.json`, `iconsconfig.json`, `uiconfig.json`, `plugin.json`, `locales/*.json`).
  2. Revisar diagnósticos con `qmlls` (`0` errores de sintaxis y `0` warnings locales).
- Mantener `docs/ROADMAP.md` y `docs/ARCHITECTURE.md` actualizados cuando se complete o agregue un módulo.
- Al terminar cada modificación, realizar un commit convencional en git a nombre de `JoseV. <contact@jessvega.me>`.

---

## 6. Review findings and implementation contracts

- Read this file, `docs/SPECS.md`, `docs/ARCHITECTURE.md` and
  `docs/ROADMAP.md` before changing code. Inspect the working tree and preserve
  other agents' edits and untracked files. Keep commits limited to one purpose.
- Write new code, identifiers and necessary comments in English. Prefer clear
  names and short functions; comments explain constraints or intent rather
  than narrating the code. Avoid unrelated style rewrites during bug fixes.
- Screen composition may instantiate existing controls and modal components;
  reusable control visuals belong in primitives, widget composition in widgets,
  and backend operations in injected services. Widgets must not import screens.
  Primitive drawing with QtQuick shapes is valid; do not move it into screens.
- Reuse Theme/StyleTokens for shared visual values and MotionTokens for motion.
  Local geometry ratios and algorithmic tolerances may be named constants;
  they are not a reason to create a second theme/configuration system.
- Every action glyph must describe the actual dispatched action: audio target
  browsing uses `I.ActionOption.L/R`, mute uses `I.PressStick.R`. A mouse button
  must not advertise LB/RB or X when those buttons execute different actions.
- A public selection key, its displayed carousel index and its action target
  must stay synchronized after external selection, model updates and removal.
  Use guarded updates with one selection authority; test their agreement.
- Bound option lists to the available panel viewport. Provide scrolling and
  reveal the focused row when content exceeds it. Clamping only the outer
  surface height does not constrain its children. Test long workspace lists.
- Measure transform content at a stable destination width independent of the
  animated surface width. Never feed animated child implicit size back into
  the geometry driving that same animation. Coalesce geometry notifications
  where needed and avoid identical writes or reentrant updates. `Qt.callLater`
  alone does not prove convergence or fix a cyclic dependency.
- Preserve the approved controls: Home's window shortcuts are intentional;
  the expanded player's D-pad options are only available Lyrics/Repeat/Shuffle.
  Y opens its player selector. Its volume icon remains reserved for a future
  right-stick knob. Do not broaden these exceptions to other screens.
- Test rapid reversal, model changes and focus return for transition changes.
  Passing offscreen tests does not prove live responsiveness or performance;
  report measured evidence separately from manual acceptance and hypotheses.
- Distinguish local qmlls diagnostics from unavailable external `qs.*` imports.
  Fix local unused imports and fixture warnings; do not claim zero diagnostics
  when they remain. Report sandbox restrictions separately from test failures.
- Keep documentation internally consistent, including configured deadzones and
  completed versus pending modules. Hardware checks must state what was tested;
  synthetic tests do not establish physical hotplug acceptance.
