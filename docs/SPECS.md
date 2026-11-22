# DuxConsole — Especificaciones Técnicas

## 1. Visión y Arquitectura General (2 piezas desacopladas)

### Frontend (`DuxConsole` — Plugin Quickshell / DMS)
- Responsabilidad exclusiva: interfaz gráfica, navegación por foco, animaciones, internacionalización y glifos.
- Consume servicios nativos de DMS (`qs.Services`: `AudioService`, `BrightnessService`, `BluetoothService`, `NightModeService`, `PowerProfileWatcher`, `MprisController`, `NiriService`/`HyprlandService`).
- Se comunica con el backend `dconsole` mediante cliente **Unix Socket** (`services/DconsoleBridge.qml`).

### Backend (`dconsole` — Binario único en Go: CLI + daemon `systemd --user`)
- **Orquestador de InputPlumber** por D-Bus (`org.shadowblip.InputPlumber`):
  - Cambio de perfiles (`desktop`, `xbox`, `xbox360`, `ds4`, `generic`).
  - Detección de giroscopio opcional (`null` si el dispositivo no es compatible).
  - Remapeo tipo Steam Input y captura global del botón `Guide`.
- **Fail-safe de mando**: si el Unix Socket con Quickshell se desconecta o el overlay falla, el daemon libera InputPlumber automáticamente a modo `gamepad` en milisegundos.
- **Ecosistema Gaming y Servicios**:
  - Lectura de manifiestos de Steam (`.vdf` / `.acf`) y caché local de SteamDB / ProtonDB.
  - Logros (Steam + RetroAchievements).
  - Discord IPC, `gpu-screen-recorder` (replay 30s) y KDE Connect.
- **CLI**: subcomandos `dconsole daemon`, `dconsole profile <name>`, `dconsole input release`, `dconsole status`, `dconsole sync`.

---

## 2. Contratos de Configuración Data-Driven

Todos los archivos JSON se cargan con `Quickshell.Io.FileView` (`watchChanges: true`) para recarga en caliente:

| Archivo | Consumidor | Responsabilidad |
| :--- | :--- | :--- |
| `inputconfig.json` | `core/shell/InputManager.qml` | Mapeo `keyboard` y `gamepad` a acciones semánticas (`I.*`), `gestures` (`repeatInitialMs`, `repeatIntervalMs`, `repeatable`, `holds`, `chords`). |
| `iconsconfig.json` | `core/shell/IconsPadManager.qml` | Mapeo por dispositivo (`keyboard`, `xbox`, `playstation`, `switch`, `steamdeck`) con variantes `mono` (`filled`/`outline`) y `colored` (`filled`/`outline`) apuntando a `assets/InputIcons/`. |
| `uiconfig.json` | `core/shell/I18n.qml` / `StyleTokens.qml` / `MotionTokens.qml` | Idioma (`language`), animaciones (`animations.enabled`, `animations.speed`, `animations.fadeInMs`, `animations.fadeOutMs`), tema (`theme.*`) y glifos (`icons.colorMode`: `"dms"` \| `"colored"` \| `"custom"`, con migración `"native"` → `"colored"`; `icons.style`: `"filled"` \| `"outline"`; `icons.customColor`; `icons.showBackdrop`: `bool`). |
| `locales/<lang>.json` | `core/shell/I18n.qml` | Diccionarios por idioma (`es.json`, `en.json`, ...) resueltos mediante `t(key, fallback)`. |

---

## 3. Contrato de Capas y Navegación (`LayerManager` + `NavigationManager` + `FocusZone`)

- **Separación estricta de 3 niveles ControlFriendly**:
  - **Macro-navegación (`I.Dpad.*`)**: navega exclusivamente entre `FocusZone`s de la capa activa (cono direccional o overrides `navUp`/`navDown`/`navLeft`/`navRight`). No altera `currentSubIndex`.
  - **Micro-navegación (`I.ActionOption.L/R` — LT/RT o `1`/`3`)**: cicla sub-ítems dentro de la `FocusZone` activa solo cuando `subItemCount > 0`, manteniendo el foco global y con wrap-around circular.
  - **Slides (`I.ActionSlide.L/R` — LB/RB o `Q`/`E`)**: cambia de pantalla en `SlideManager` únicamente cuando `layerManager.topLayer === "dashboard"`.
- **Pila de capas**: `dashboard` → `wheel` → `modal` (`LayerManager.topLayer` / `activeLayer`).
- **Autoridad única (`NavigationManager`)**: centraliza registro de zonas, `ensureFocus(layerName)`, `move(direction)`, validación de capacidades y `activeHints`. `FocusZone` encapsula capacidades (`defaultFocus`, `expandable`, `subItemCount`, `actionHints`) y `LayerManager` administra la pila y `focusMemory`.
- **Memoria de foco y prioridad**: al empujar (`push(layer)`) una capa nueva, `LayerManager` guarda la `FocusZone` activa en `focusMemory`. Al restaurar o entrar a una capa, `NavigationManager.ensureFocus()` prioriza: 1) foco recordado válido en `focusMemory`, 2) zona con `defaultFocus: true`, 3) fallback espacial arriba-izquierda.
- **Regla `inert`**: toda `FocusZone` cuyo `layerName !== layerManager.topLayer` queda bloqueada (`inert: true`), ignorando D-Pad, `LT`/`RT`, activación y expansión.
- **Enrutamiento global en `ConsoleOverlay.qml`**:
  - `I.Refuse` ejecuta `layerManager.pop()`; solo cierra el overlay si `topLayer` ya es `"dashboard"`.
  - `I.ActionSlide.L` y `I.ActionSlide.R` quedan bloqueados cuando `topLayer !== "dashboard"`.
  - `I.Select` se despacha desde `NavigationManager.handleAction()` hacia `FocusZone.requestExpand()` solo si `expandable === true`.
  - `I.Options` se despacha desde `NavigationManager.handleAction()` hacia `FocusZone.triggerOptions()` (`optionsTriggered`) para abrir el menú contextual de la ventana seleccionada.

---

## 4. Contrato del Adaptador `WindowManager` (`services/WindowManager.qml`)

- **Protocolo**: Niri IPC (`$NIRI_SOCKET`), compatible con `niri 26.04` mediante dos sockets separados (`eventSocket` con `"EventStream"` reactivo sin polling + `cmdSocket` serializado para `Outputs` y `Action`s). Reconexión automática cada `2000 ms` y estado `unavailable` cuando no hay socket.
- **Modelo normalizado**: `windows` (`{ id, title, appId, appName, workspaceId, workspaceIndex, workspaceName, output, isFocused, isFloating, isFullscreen, pid }`), `workspaces` (`{ id, idx, name, output, isActive, isFocused }`), `outputs` (`{ name, make, model, logicalWidth, logicalHeight }`).
- **Acciones por ID explícito**: `focusWindow(id)`, `moveWindowToMonitor(id, output)`, `moveWindowToWorkspace(id, wsId)`, `toggleFullscreen(id)`, `closeWindow(id)`.
- **Terminación forzada (`forceKillWindow`)**: capacidad separada que exige `pid > 1`, verificación de propietario (`Uid` en `/proc/<pid>/status`) y exclusión de procesos protegidos (`niri`, `quickshell`, `dms`, `dconsole`, `systemd`, etc.). Si Niri IPC no expone `pid`, `canForceKill()` retorna `false` y la UI muestra la acción deshabilitada.

---

## 4. Contrato Visual y Primitivas

- **Composición del Overlay (`components/chrome/Bg.qml` + `StyleTokens.qml`)**: `Bg` usa `StyleTokens.scrimColor()` (configurable vía `theme.scrimOpacity`, default `0.58`) para mantener visible el juego/escritorio detrás sin lavados blancos accidentales. Soporta modos `hybrid` (chrome claro, cards oscuras translúcidas), `dark` y `light`, y roles semánticos `surfaceColor(role)` / `onSurfaceColor(role)` / `borderColor(role)`.
- **Chrome persistente (`TopBar.qml` + `FooterBar.qml`)**: Instanciado una sola vez en `ConsoleOverlay.qml` fuera del `Loader` de `SlideManager.qml`, por lo que permanece montado al cambiar entre slides. `SlideManager` se ancla entre `topBar.bottom` y `footerBar.top`.
  - `TopBar`: 3 cápsulas sólidas/opacas independientes sobre un `Item` transparente (sin barra continua compartida): **Brand** izquierda (`CircularProgressGlyph` Guide + `assets/dux-logo.svg` + `DUXSHELL`/`CONSOLE`), **Navigation** centrada (`LB`/`RB` fuera de la cápsula + píldora de acento para el slide activo de `ScreenRegistry`), **Status** derecha (batería mando `--` si desconectado + `UPower` + `SystemClock` + `CircularProgressGlyph` Start + perfil).
  - `FooterBar` + `ActionHints`: tarjetas individuales en `Flow` (`Qt.RightToLeft`) ancladas abajo a la derecha consumiendo `NavigationManager.activeHints`. Como `wlr-layer-shell` en Quickshell no expone blur por tarjeta individual, cada tarjeta usa una superficie sólida/opaca de alto contraste como fallback legible sin `MultiEffect` falso.
- **`SlantedSurface.qml`**: `role` (`"card"` | `"chrome"`), `skewAngle`, `focused`, `selected`, `disabled`, `radius`, `borderWidth`, `motionTokens`. Aplica `Matrix4x4` shear solo a `bgShape`; `content` permanece recto y sin deformación de hit-testing.
- **`SlantedImage.qml`**: recorta una `Image` recta (sin shear) usando `MultiEffect` (`maskEnabled: true`) contra la máscara inclinada y redondeada de `SlantedSurface`; soporta `fillMode`, estados `Loading`/fallback, gradiente inferior y `overlayContent`. Limitación conocida: requiere `layer.enabled: true` en el contenedor enmascarado.

---

## 4. Mapa de Directorios

```text
DuxConsole/
├── AGENTS.md                        # Reglas operativas estrictas para agentes y devs
├── CREDITS.md                       # Créditos y licencias (Kenney Input Prompts CC0)
├── ConsoleDaemon.qml                # PluginComponent DMS + IpcHandler ("duxConsole")
├── inputconfig.json                 # Config editable de entrada y gestos
├── iconsconfig.json                 # Config editable de glifos por dispositivo
├── uiconfig.json                    # Config editable de UI e idioma
├── plugin.json                      # Manifiesto del plugin DMS
├── assets/
│   └── InputIcons/                  # Kenney Input Prompts (SVGs Xbox, PS, Keyboard, etc.)
├── components/
│   ├── chrome/                      # Marco persistente (Bg.qml, FocusRing.qml, ...)
│   ├── primitives/                  # Átomos UI (buttons/, sliders/, glyphs/, text/)
│   └── widgets/                     # Bloques compuestos reutilizables
├── core/
│   ├── shell/                       # ConsoleOverlay, InputManager, IconsPadManager, I18n, ScreenBase, ScreenRegistry, SlideManager
│   ├── interaction/                 # LayerManager, FocusZone
│   └── motion/                      # Tokens y transiciones configurables
├── locales/                         # Traducciones (es.json, en.json)
├── screens/
│   ├── slides/                      # Vistas principales (capa "dashboard")
│   ├── overlays/                    # Ruedas orbitales (capa "wheel")
│   └── modals/                      # Modales y diálogos (capa "modal")
├── services/                        # DconsoleBridge y wrappers de qs.Services
└── docs/
    ├── ARCHITECTURE.md
    ├── SPECS.md
    └── ROADMAP.md
```
