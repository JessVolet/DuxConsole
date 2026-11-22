# DuxConsole Architecture

## Estructura modular

```text
DuxConsole/
├── assets/                          # Recursos estáticos (SVGs de mando Xbox/PS, iconos)
├── components/
│   ├── chrome/                      # Marco persistente (Bg, FocusRing, BarraMenu, StatusBar, ActionHints)
│   ├── primitives/                  # Átomos UI por familia de control
│   │   ├── buttons/                 # ActionButton, FocusCard, PillButton, ToggleChip
│   │   ├── sliders/                 # ConsoleSlider, VolumeSlider, ProgressBar
│   │   ├── glyphs/                  # InputGlyph (<kbd> vs SVG), StatusBadge, AvatarBadge
│   │   └── text/                    # TestText, SectionTitle, MetricLabel
│   └── widgets/                     # Bloques compuestos (WindowCarousel, MediaPlayerCard, AudioMixerRow...)
├── core/
│   ├── shell/                       # ConsoleOverlay, InputManager, ScreenBase, ScreenRegistry, SlideManager
│   ├── interaction/                 # FocusZone, LayerManager
│   └── motion/                      # MotionTokens, CarouselView, MorphModal, SlideTransition
├── screens/
│   ├── slides/                      # Vistas principales (capa "dashboard")
│   ├── overlays/                    # Ruedas orbitales (capa "wheel")
│   └── modals/                      # Menús expandidos y diálogos (capa "modal")
├── services/                        # DconsoleBridge (socket Go) y wrappers de qs.Services
├── docs/
│   └── ARCHITECTURE.md
├── ConsoleDaemon.qml
├── inputconfig.json                 # Config editable de teclas, mando, holds y combos
├── uiconfig.json                    # Config editable de UI (animaciones on/off, velocidad, tema/escala)
└── plugin.json
```

## Resumen de módulos y rutas

| Módulo | Ruta | Responsabilidad |
| :--- | :--- | :--- |
| Daemon | `ConsoleDaemon.qml` | Registro del plugin DMS e `IpcHandler` (`duxConsole`) |
| Config de entrada | `inputconfig.json` | Mapa de teclado/gamepad, repetición, holds y chords |
| Config de UI | `uiconfig.json` | Animaciones on/off, velocidad y escala/tema |
| Assets | `assets/` | Recursos estáticos (SVGs Xbox/PS, iconos) |
| Overlay shell | `core/shell/ConsoleOverlay.qml` | `PanelWindow` Wayland, captura de teclas, `Bg` y `FocusRing` |
| Registro de pantallas | `core/shell/ScreenRegistry.qml` | Catálogo de slides en `../../screens/slides/` |
| Gestor de slides | `core/shell/SlideManager.qml` | `Loader` dinámico de slides e inyección de `inputManager` y `layerManager` |
| Base de pantalla | `core/shell/ScreenBase.qml` | Contenedor base con márgenes `Theme.spacingXL` |
| Entrada | `core/shell/InputManager.qml` | Traducción teclado/gamepad con `../../inputconfig.json` y gestos |
| Capas | `core/interaction/LayerManager.qml` | Pila `dashboard` → `wheel`/`modal` y memoria de foco por capa |
| Foco | `core/interaction/FocusZone.qml` | Navegación D-Pad, ciclo `LT`/`RT` y bloqueo `inert` |
| Motion | `core/motion/` | Tokens de animación y transiciones (`MotionTokens`, `CarouselView`, `MorphModal`, `SlideTransition`) |
| Chrome | `components/chrome/` | Marco persistente (`Bg.qml`, `FocusRing.qml`, etc.) |
| Primitivas | `components/primitives/` | `buttons/`, `sliders/`, `glyphs/` y `text/` (`TestText.qml`) |
| Widgets | `components/widgets/` | Bloques compuestos reutilizables |
| Slides | `screens/slides/` | Vistas principales (`TestScreen.qml`, `TestScreen2.qml`) |
| Overlays / Modals | `screens/overlays/`, `screens/modals/` | Ruedas orbitales (`"wheel"`) y modales (`"modal"`) |
| Servicios | `services/` | `DconsoleBridge` (socket Go) y wrappers de `qs.Services` |

## Flujo de entrada y capas

1. `ConsoleOverlay` (`core/shell/ConsoleOverlay.qml`) captura eventos de teclado (y gamepad vía `services/` / `dconsole`) y los delega a `InputManager` (`core/shell/InputManager.qml`).
2. `InputManager` traduce códigos crudos usando `../../inputconfig.json` y emite la señal semántica `triggered(action, payload)`.
3. `ConsoleOverlay` enruta las acciones:
   - `I.Refuse`: intenta cerrar la capa superior con `layerManager.pop()`; si ya está en `"dashboard"`, cierra el overlay.
   - `I.ActionSlide.L` / `I.ActionSlide.R`: cambian de pantalla en `SlideManager` solo cuando la capa `"dashboard"` está activa.
   - D-Pad, `I.ActionOption.L/R`, `I.Accept`, `I.Action`: se delegan a `LayerManager.handleAction(...)`.
4. `LayerManager` (`core/interaction/LayerManager.qml`) mantiene la pila de capas (`dashboard` -> `wheel` / `modal`) y recuerda la última `FocusZone` activa de cada capa.
5. `FocusZone` (`core/interaction/FocusZone.qml`) aplica la regla `inert` cuando su `layerName` no coincide con `layerManager.activeLayer`, bloqueando navegación, activación y ciclo rápido `LT`/`RT`.
6. `FocusRing` (`components/chrome/FocusRing.qml`) sigue suavemente la geometría de `layerManager.activeZone` en el espacio de coordenadas del overlay.
