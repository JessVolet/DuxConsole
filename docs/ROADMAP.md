# DuxConsole — Roadmap por Fases

## FASE 0 — Fundamentos y Estructura Base
- [x] Estructura modular definitiva (`core/{shell,interaction,motion}`, `components/{chrome,primitives,widgets}`, `screens/{slides,overlays,modals}`, `services/`, `locales/`, `assets/InputIcons/`).
- [x] `ConsoleDaemon.qml`, `plugin.json` y `core/shell/ConsoleOverlay.qml` (`wlr-layer-shell` fullscreen + `WlrKeyboardFocus.Exclusive`).
- [x] `core/shell/ScreenRegistry.qml`, `core/shell/SlideManager.qml`, `core/shell/ScreenBase.qml`.
- [x] Créditos de Kenney Input Prompts (`CREDITS.md`) y arquitectura base (`docs/ARCHITECTURE.md`).
- [x] `AGENTS.md`, `docs/SPECS.md` y `docs/ROADMAP.md`.

## FASE 1 — Núcleo de Entrada, Capas, Glifos e I18n (`core/shell` + `core/interaction`)
- [x] `core/shell/InputManager.qml` + `inputconfig.json` (teclado, mapa gamepad, holds, acordes Guide+acción, repetición controlada, recarga en caliente).
- [x] `core/interaction/LayerManager.qml` (pila de capas, `topLayer`, memoria de foco por capa, despacho de `I.Select`).
- [x] `core/interaction/FocusZone.qml` (D-Pad macro, LT/RT micro, `activated`, `secondaryTriggered`, `expandRequested`).
- [x] `core/shell/IconsPadManager.qml` + `iconsconfig.json` (34 SVGs Xbox/PS de Kenney + fallback teclado).
- [x] `core/shell/I18n.qml` + `locales/es.json` y `locales/en.json` + `"language"` en `uiconfig.json`.
- [ ] Pulir `core/shell/ScreenBase.qml`: fijar `anchors.fill: parent` y centralizar helper `tr(key, fallback)` para eliminar duplicación en slides.
- [ ] Soporte opcional `lockDevice` en `core/shell/InputManager.qml` para depuración de glifos con teclado sin sobreescribir `activeDevice`.

## FASE 2 — Motor de Movimiento Configurable (`core/motion/`)
- [ ] `core/motion/MotionTokens.qml` (singleton / manager conectado a `uiconfig.json`: `animationsEnabled`, `speedScale`, presets Instantáneo / Rápido / Normal / Cinemático, curvas estándar).
- [ ] Conectar `components/chrome/FocusRing.qml` a `MotionTokens` (eliminar duraciones hardcodeadas).
- [ ] `core/motion/CarouselView.qml` (contenedor deslizante horizontal reutilizable controlado por `FocusZone.currentSubIndex`).
- [ ] `core/motion/MorphModal.qml` (wrapper animado que expande/contrae desde el rectángulo de la `FocusZone` origen vía `mapToItem()`).
- [ ] `core/motion/SlideTransition.qml` (transición direccional izquierda/derecha en `SlideManager.qml`).

## FASE 3 — Sistema de Diseño: Primitives y Chrome (`components/`)
- [x] `components/chrome/Bg.qml` y `components/chrome/FocusRing.qml`.
- [x] `components/primitives/glyphs/InputGlyph.qml` y `components/primitives/text/TestText.qml`.
- [ ] `components/primitives/buttons/`: `ActionButton.qml`, `FocusCard.qml`, `PillButton.qml`, `ToggleChip.qml`.
- [ ] `components/primitives/sliders/`: `ConsoleSlider.qml`, `VolumeSlider.qml`, `ProgressBar.qml`.
- [ ] `components/primitives/text/`: `SectionTitle.qml`, `MetricLabel.qml`.
- [ ] `components/primitives/glyphs/`: `StatusBadge.qml`, `AvatarBadge.qml`.
- [ ] `components/chrome/`: `BarraMenu.qml` (tabs dinámicas desde `ScreenRegistry` + `I18n`), `StatusBar.qml` (reloj, batería, red), `ActionHints.qml` (barra inferior contextual dinámica según la `FocusZone` activa).
- [ ] Refactorizar `screens/slides/TestScreen.qml` para consumir únicamente primitives, `ActionHints` y un modal reutilizable (0 UI inline).

## FASE 4 — Servicios del Sistema (`services/` — Integración DMS)
- [ ] `services/SystemServices.qml`: wrapper limpio sobre `qs.Services` (`AudioService`, `BrightnessService`, `BluetoothService`, `NightModeService`, `PowerProfileWatcher`, `MprisController`, `NiriService`/`HyprlandService`).
- [ ] `services/StartupCheck.qml`: validación de dependencias opcionales (`dconsole` daemon, InputPlumber, `gpu-screen-recorder`).

## FASE 5 — Widgets y Pantallas Reales (`components/widgets/` + `screens/`)
- [ ] Widgets (`components/widgets/`): `WindowCarousel.qml`, `MediaPlayerCard.qml`, `AudioMixerRow.qml`, `DeviceSelectorCard.qml`, `CaptureControls.qml`, `DiscordStatusCard.qml`, `AchievementCard.qml`.
- [ ] Modales (`screens/modals/`): `WindowGridModal.qml`, `DeviceGridModal.qml`, `ItemOptionsModal.qml`, `ConfirmDialog.qml`.
- [ ] Ruedas Orbitales (`screens/overlays/`): `OrbitalMenu.qml` (`SystemWheel` con hold `I.Guide` y `QuickWheel` con acorde `I.Guide + I.ActionSlide.R`).
- [ ] Slides (`screens/slides/`):
  - [ ] `HomeScreen.qml` (ventanas activas, reproductor MPRIS, captura rápida, estado).
  - [ ] `SoundScreen.qml` (dispositivos salida/entrada con LT/RT + mezclador por app).
  - [ ] `CaptureScreen.qml` (captura de pantalla, grabación, replay 30s).
  - [ ] `LauncherScreen.qml` (biblioteca Steam + ROMs + estado ProtonDB/SteamDB).
  - [ ] `AchievementsScreen.qml` (logros Steam + RetroAchievements).
  - [ ] `SettingsScreen.qml` (idioma en vivo, velocidad/toggle de animaciones, perfiles de mando, remapeo).

## FASE 6 — Backend `dconsole` en Go (CLI + Daemon `systemd --user`)
- [ ] Proyecto Go `dconsole` con subcomandos CLI (`daemon`, `profile`, `input release`, `status`, `sync`) y unidad `systemd --user` (`Restart=on-failure`).
- [ ] Cliente D-Bus para `org.shadowblip.InputPlumber`: perfiles (`desktop`, `xbox`, `xbox360`, `ds4`, `generic`), detección de giroscopio (`null` si no existe) y captura global del botón `Guide`.
- [ ] Mecanismo **Fail-Safe** sobre Unix Socket: liberación instantánea del mando al desconectarse Quickshell.
- [ ] `services/DconsoleBridge.qml`: cliente Unix Socket en QML conectado a `InputManager.handleRawPress/Release/Analog`.
- [ ] Integraciones externas con caché en disco: Steam (`.vdf`/`.acf`), SteamDB/ProtonDB, RetroAchievements, Discord IPC y `gpu-screen-recorder`.
