# DuxConsole — Roadmap por Fases

## FASE 0 — Fundamentos y Estructura Base
- [x] Estructura modular definitiva (`core/{shell,interaction,motion}`, `components/{chrome,primitives,widgets}`, `screens/{slides,overlays,modals}`, `services/`, `locales/`, `assets/InputIcons/`).
- [x] `ConsoleDaemon.qml`, `plugin.json` y `core/shell/ConsoleOverlay.qml` (`wlr-layer-shell` fullscreen + `WlrKeyboardFocus.Exclusive`).
- [x] `core/shell/ScreenRegistry.qml`, `core/shell/SlideManager.qml`, `core/shell/ScreenBase.qml`.
- [x] Créditos de Kenney Input Prompts (`CREDITS.md`) y arquitectura base (`docs/ARCHITECTURE.md`).
- [x] `AGENTS.md`, `docs/SPECS.md` y `docs/ROADMAP.md`.

## FASE 1 — Núcleo de Entrada, Capas, Glifos e I18n (`core/shell` + `core/interaction`)
- [x] `core/shell/InputManager.qml` + `inputconfig.json` (teclado, mapa gamepad, holds, acordes Guide+acción, repetición controlada, recarga en caliente).
- [x] `core/interaction/LayerManager.qml` (pila de capas, `topLayer`, `focusMemory` por capa).
- [x] `core/interaction/NavigationManager.qml` (autoridad única de registro, `defaultFocus`, navegación espacial, capacidades y `activeHints`).
- [x] `core/interaction/FocusZone.qml` (D-Pad macro, LT/RT micro, `defaultFocus`, `expandable`, `actionHints`, `activated`, `secondaryTriggered`, `expandRequested`).
- [x] `core/shell/IconsPadManager.qml` + `iconsconfig.json` (34 SVGs Xbox/PS de Kenney + fallback teclado).
- [x] `core/shell/I18n.qml` + `locales/es.json` y `locales/en.json` + `"language"` en `uiconfig.json`.
- [x] Pulir `core/shell/ScreenBase.qml`: fijar `anchors.fill: parent` y centralizar helper `tr(key, fallback)` para eliminar duplicación en slides.
- [ ] Soporte opcional `lockDevice` en `core/shell/InputManager.qml` para depuración de glifos con teclado sin sobreescribir `activeDevice`.

## FASE 2 — Motor de Movimiento Configurable (`core/motion/`)
- [x] `core/motion/MotionTokens.qml` (singleton / manager conectado a `uiconfig.json`: `animationsEnabled`, `speedScale`, curvas estándar y duraciones configurables de fade in/out).
- [x] `core/shell/StyleTokens.qml` (recarga en vivo vía `uiconfig.json`: `accentColor`, `skewAngle`, `surfaceColor`, `iconTintEnabled`).
- [x] Conectar `components/chrome/FocusRing.qml` a `MotionTokens` y `StyleTokens.accentColor` (eliminar duraciones hardcodeadas).
- [x] `components/primitives/surfaces/`: `SlantedSurface.qml` y `SlantedImage.qml` (`FocusCard.qml` basada en `SlantedSurface`).
- [x] `core/motion/ContainerTransform.qml` + `ContainerGeometry.js` and reusable `TransformSurface`: anchored, reversible container transition with global tokens and bounded geometry.
- [x] Adopt `TransformSurface` in `WindowOptionsModal`, `MediaPlayerPicker` and `AudioDeviceOptions`, retaining consumer-owned input, layers and focus restoration.
- [ ] Migrate `MediaPlayerModal` from `ContainerTransform` to `TransformSurface`.
- [x] Expanded media player: Y opens a `TransformSurface` player picker, with manual/automatic selection, session pinning, inert background and focus return.
- [x] Rectangular lyrics panel with native synchronized lines and no shader mask or text shear.
- [x] Symmetric expanded media controls: top Y selector, centered Lyrics/Repeat/Shuffle row and bottom-right volume icon.
- [ ] `core/motion/SlideTransition.qml` (transición direccional izquierda/derecha en `SlideManager.qml`).

## FASE 3 — Sistema de Diseño: Primitives y Chrome (`components/`)
- [x] `components/chrome/Bg.qml` y `components/chrome/FocusRing.qml`.
- [x] `components/primitives/glyphs/InputGlyph.qml`, `components/primitives/glyphs/CircularProgressGlyph.qml` y `components/primitives/text/TestText.qml`.
- [x] `components/primitives/buttons/`: `ActionButton.qml`, `FocusCard.qml` (`PillButton.qml`, `ToggleChip.qml` pendientes).
- [x] `components/widgets/CarouselView.qml` (escala al ancho disponible, muestra hasta seis y mantiene hasta dos en caché para fades de entrada/salida al rotar modelos mayores).
- [x] `components/primitives/sliders/`: `MediaProgressBar.qml` (`ConsoleSlider.qml`, `VolumeSlider.qml` pendientes).
- [ ] `components/primitives/text/`: `MetricLabel.qml`; [x] `DisplayTitle.qml`, `SectionTitle.qml`, `StatusMessage.qml`, `TestText.qml`.
- [ ] `components/primitives/glyphs/`: `StatusBadge.qml`, `AvatarBadge.qml`.
- [x] `components/chrome/`: `TopBar.qml` (identidad + tabs dinámicas + estado), `FooterBar.qml` + `ActionHints.qml` (tarjetas individuales abajo a la derecha), `ErrorBanner.qml`, `ModalPanel.qml`; [ ] `StatusBar.qml` dedicado si se desacopla.
- [x] Refactorizar `screens/slides/TestScreen.qml` para consumir únicamente primitives, `ActionHints` y un modal reutilizable (0 UI inline).

## FASE 4 — Servicios del Sistema (`services/` — Integración DMS)
- [x] AudioControlService + AudioDevicePreferences: normalized application/output/input targets, volume/mute, activation and persistent independent multi-pin ordering.
- [x] `services/WindowManager.qml`: adaptador reactivo Niri IPC (`$NIRI_SOCKET` `EventStream` + cola de comandos `FocusWindow`, `MoveWindowToMonitor`, `MoveWindowToWorkspace`, `FullscreenWindow` y `CloseWindow`); no expone PID ni termina procesos.
- [x] `services/WindowIconProvider.qml`: resolución de iconos XDG inyectada desde el Composition Root.
- [x] `services/MediaService.qml` y `services/CavaService.qml`: adaptador MPRIS real (`Quickshell.Services.Mpris`) y espectro Cava bajo demanda para el reproductor expandido.
- [ ] `services/SystemServices.qml`: wrapper limpio sobre `qs.Services` (`AudioService`, `BrightnessService`, `BluetoothService`, `NightModeService`, `PowerProfileWatcher`, `MprisController`).
- [ ] `services/StartupCheck.qml`: validación de dependencias opcionales (`dconsole` daemon, InputPlumber, `gpu-screen-recorder`).

## FASE 5 — Widgets y Pantallas Reales (`components/widgets/` + `screens/`)
- [x] Independent AppVolumeMixer (vertical, up to five), AudioOutputSelector and AudioInputSelector; anchored device options, reusable VolumeKnob and assembled Sound screen.
- [x] Angular 270-degree knob controller with configurable deadzone/hysteresis, target rearming and R3 mute; frontend normalized-axis receiver.
- [x] Right-stick axis production in the separate dconsole daemon (ABS_X/Y/RX/RY normalized, sent only while grabbed, released on disconnect/failure).
- [x] Verify real stick control with a physical pad: axes reach the daemon only while grabbed, a second reader of the device receives nothing, app volume follows the stick and R3 mutes without changing volume. Physical hotplug/reconnect remains covered only by unit tests.
- [x] Widgets (`components/widgets/`): `CarouselView.qml`, `WindowCarousel.qml`, `CarouselActionAnchor.qml`, `WindowActionsPanel.qml`, `WindowInfoCard.qml`, `WindowInfoCards.qml`, `MediaPlayerCard.qml`, `MediaPlayerExpanded.qml`, `MediaLyricsPanel.qml`, `audio/AppVolumeMixer.qml`, `audio/AudioOutputSelector.qml`, `audio/AudioInputSelector.qml`; [ ] `CaptureControls.qml`, `DiscordStatusCard.qml`, `AchievementCard.qml`.
- [ ] Modales (`screens/modals/`): `WindowGridModal.qml`, `DeviceGridModal.qml`, `ConfirmDialog.qml`; [x] `ItemOptionsModal.qml`, `WindowOptionsModal.qml`, `MediaPlayerModal.qml`, `MediaPlayerPicker.qml`.
- [ ] Perilla de volumen multimedia controlada con stick derecho en `MediaPlayerExpanded.qml` (icono reservado).
- [ ] Ruedas Orbitales (`screens/overlays/`): `OrbitalMenu.qml` (`SystemWheel` con hold `I.Guide` y `QuickWheel` con acorde `I.Guide + I.ActionSlide.R`).
- [ ] Slides (`screens/slides/`):
  - [x] `HomeScreen.qml` (título/descripción de ventana seleccionada, carrusel `iconOnly` centrado abajo y `MediaPlayerCard` abajo a la derecha).
  - [x] `AudioScreen.qml` (dispositivos salida/entrada independientes con LT/RT y activación con A, mezclador vertical por app y perilla reutilizable).
  - [ ] `CaptureScreen.qml` (captura de pantalla, grabación, replay 30s).
  - [ ] `LauncherScreen.qml` (biblioteca Steam + ROMs + estado ProtonDB/SteamDB).
  - [ ] `AchievementsScreen.qml` (logros Steam + RetroAchievements).
  - [ ] `SettingsScreen.qml` (idioma en vivo, velocidad/toggle de animaciones, perfiles de mando, remapeo).

## FASE 6 — Backend `dconsole` en Go (CLI + Daemon `systemd --user`)
- [ ] Proyecto Go `dconsole` con subcomandos CLI (`daemon`, `profile`, `input release`, `status`, `sync`) y unidad `systemd --user` (`Restart=on-failure`).
- [ ] Cliente D-Bus para `org.shadowblip.InputPlumber`: perfiles (`desktop`, `xbox`, `xbox360`, `ds4`, `generic`), detección de giroscopio (`null` si no existe) y captura global del botón `Guide`.
- [ ] Mecanismo **Fail-Safe** sobre Unix Socket: liberación instantánea del mando al desconectarse Quickshell.
- [x] `services/DconsoleBridge.qml`: cliente Unix Socket en QML conectado a `InputManager.handleRawPress/Release`.
- [ ] Integraciones externas con caché en disco: Steam (`.vdf`/`.acf`), SteamDB/ProtonDB, RetroAchievements, Discord IPC y `gpu-screen-recorder`.
