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
