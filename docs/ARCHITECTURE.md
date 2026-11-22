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
│   ├── shell/                       # ConsoleOverlay, InputManager, IconsPadManager, I18n, ScreenBase, ScreenRegistry, SlideManager
│   ├── interaction/                 # FocusZone, LayerManager
│   └── motion/                      # MotionTokens, CarouselView, MorphModal, SlideTransition
├── locales/                         # Traducciones JSON (es.json, en.json, ...)
├── screens/
│   ├── slides/                      # Vistas principales (capa "dashboard")
│   ├── overlays/                    # Ruedas orbitales (capa "wheel")
│   └── modals/                      # Menús expandidos y diálogos (capa "modal")
├── services/                        # DconsoleBridge (socket Go) y wrappers de qs.Services
├── docs/
│   └── ARCHITECTURE.md
├── ConsoleDaemon.qml
├── inputconfig.json                 # Config editable de teclas, mando, holds y combos
├── iconsconfig.json                 # Config editable de glifos por dispositivo (keyboard, xbox, playstation)
├── uiconfig.json                    # Config editable de UI (idioma, animaciones on/off, velocidad, tema/escala)
└── plugin.json
```

## Resumen de módulos y rutas

| Módulo | Ruta | Responsabilidad |
| :--- | :--- | :--- |
| Daemon | `ConsoleDaemon.qml` | Registro del plugin DMS e `IpcHandler` (`duxConsole`) |
| Config de entrada | `inputconfig.json` | Mapa de teclado/gamepad, repetición, holds y chords |
| Config de glifos | `iconsconfig.json` | Mapa data-driven de iconos/etiquetas por dispositivo (`keyboard`, `xbox`, `playstation`) |
| Config de UI | `uiconfig.json` | Idioma (`language`), animaciones on/off, velocidad y escala/tema |
| Locales | `locales/es.json`, `locales/en.json` | Diccionarios de traducción por sección |
| Assets | `assets/` | Recursos estáticos (incluye `assets/InputIcons/` — Kenney Input Prompts CC0) |
| Overlay shell | `core/shell/ConsoleOverlay.qml` | Composition Root: `PanelWindow`, captura de teclas, `Bg` y `FocusRing` |
| Registro de pantallas | `core/shell/ScreenRegistry.qml` | Catálogo de slides en `../../screens/slides/` con `labelKey` para `I18n` |
| Gestor de slides | `core/shell/SlideManager.qml` | `Loader` dinámico de slides e inyección de `inputManager`, `layerManager`, `iconsPadManager` e `i18n` |
| Base de pantalla | `core/shell/ScreenBase.qml` | Contenedor base con acceso a servicios inyectados |
| Entrada | `core/shell/InputManager.qml` | Traducción teclado/gamepad con `../../inputconfig.json` y gestos |
| Glifos | `core/shell/IconsPadManager.qml` | Cruce data-driven entre `inputManager.config` e `iconsconfig.json` vía `resolve(action)` |
| Internacionalización | `core/shell/I18n.qml` | Carga reactiva de `uiconfig.json` y `locales/<lang>.json` con `t(key, fallback)` |
| Capas | `core/interaction/LayerManager.qml` | Pila `dashboard` → `wheel`/`modal` (`topLayer`) y memoria de foco por capa |
| Foco | `core/interaction/FocusZone.qml` | Navegación D-Pad, ciclo `LT`/`RT`, expansión (`I.Select`) y bloqueo `inert` |
| Motion | `core/motion/` | Tokens de animación y transiciones |
| Chrome | `components/chrome/` | `Bg.qml`, `FocusRing.qml` |
| Primitivas | `components/primitives/` | `buttons/`, `sliders/`, `glyphs/` (`InputGlyph.qml`) y `text/` (`TestText.qml`) |
| Widgets | `components/widgets/` | Bloques compuestos reutilizables |
| Slides | `screens/slides/` | `TestScreen.qml`, `TestScreen2.qml` |
| Overlays / Modals | `screens/overlays/`, `screens/modals/` | Ruedas orbitales (`"wheel"`) y modales (`"modal"`) |
| Servicios | `services/` | `DconsoleBridge` (socket Go) y wrappers de `qs.Services` |

## Regla de dependencias

- `core/` **no** importa `components/` ni `screens/`, con la única excepción del Composition Root en `core/shell/ConsoleOverlay.qml` (`import "../../components/chrome"` para montar `Bg` y `FocusRing`).
- Los componentes y pantallas no hardcodean teclas ni textos visibles: usan `InputGlyph` (`IconsPadManager.resolve(action)`) e `I18n.t(key, fallback)`.

## Cómo agregar un nuevo idioma

1. Crea `locales/<code>.json` (por ejemplo `locales/fr.json`) replicando las claves de `locales/es.json` o `locales/en.json`.
2. Cambia `"language": "<code>"` en `uiconfig.json` (o usa `"auto"` si `effectiveLanguage` contempla ese código). `I18n.qml` recarga el archivo automáticamente gracias a `watchChanges: true`.

## Flujo de entrada y capas

1. `ConsoleOverlay` (`core/shell/ConsoleOverlay.qml`) captura eventos de teclado (y gamepad vía `services/` / `dconsole`) y los delega a `InputManager` (`core/shell/InputManager.qml`).
2. `InputManager` traduce códigos crudos usando `../../inputconfig.json` y emite `triggered(action, payload)`.
3. `ConsoleOverlay` enruta las acciones:
   - `I.Refuse`: intenta cerrar la capa superior con `layerManager.pop()`; si `topLayer` ya es `"dashboard"`, cierra el overlay.
   - `I.ActionSlide.L` / `I.ActionSlide.R`: cambian de pantalla en `SlideManager` solo cuando `layerManager.topLayer === "dashboard"`.
   - D-Pad, `I.ActionOption.L/R`, `I.Accept`, `I.Action`, `I.Select`: se delegan a `LayerManager.handleAction(...)`.
4. `LayerManager` (`core/interaction/LayerManager.qml`) mantiene la pila de capas (`dashboard` -> `wheel` / `modal`) y recuerda la última `FocusZone` activa de cada capa.
5. `FocusZone` (`core/interaction/FocusZone.qml`) aplica la regla `inert` cuando su `layerName` no coincide con `layerManager.topLayer`, bloqueando navegación, activación, expansión y ciclo rápido `LT`/`RT`.
6. `FocusRing` (`components/chrome/FocusRing.qml`) sigue suavemente la geometría de `layerManager.activeZone` en el espacio de coordenadas del overlay.
