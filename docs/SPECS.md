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

- **Pila de capas**: `dashboard` → `wheel` → `modal` (`LayerManager.topLayer` / `activeLayer`).
- **Autoridad única de selección (`NavigationManager`)**: `NavigationManager` centraliza el registro de zonas, `ensureFocus(layerName)`, la navegación espacial (`move(direction)`) y `activeHints`. `LayerManager` mantiene la pila y `focusMemory` sin seleccionar zonas por su cuenta.
- **Memoria de foco y prioridad**: al empujar (`push(layer)`) una capa nueva, `LayerManager` guarda la `FocusZone` activa en `focusMemory`. Al restaurar o entrar a una capa, `NavigationManager.ensureFocus()` prioriza: 1) foco recordado válido en `focusMemory`, 2) zona con `defaultFocus: true`, 3) fallback espacial arriba-izquierda.
- **Regla `inert`**: toda `FocusZone` cuyo `layerName !== layerManager.topLayer` queda bloqueada (`inert: true`), ignorando D-Pad, `LT`/`RT`, activación y expansión.
- **Enrutamiento global en `ConsoleOverlay.qml`**:
  - `I.Refuse` ejecuta `layerManager.pop()`; solo cierra el overlay si `topLayer` ya es `"dashboard"`.
  - `I.ActionSlide.L` y `I.ActionSlide.R` quedan bloqueados cuando `topLayer !== "dashboard"`.
  - `I.Select` se despacha desde `NavigationManager.handleAction()` hacia `FocusZone.requestExpand()` solo si `expandable === true`.

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
