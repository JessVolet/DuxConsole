# DuxConsole Architecture

## Estructura modular

```text
DuxConsole/
├── ConsoleDaemon.qml                 # Punto de entrada del plugin DMS e IpcHandler
├── inputconfig.json                  # Mapa de teclado/gamepad y gestos (holds, chords, repeat)
├── plugin.json                       # Metadatos del plugin DMS
├── core/
│   ├── shell/                        # Infraestructura del overlay, pantallas y entrada
│   │   ├── ConsoleOverlay.qml        # PanelWindow Wayland + orquestación global
│   │   ├── SlideManager.qml          # Carga y transición entre pantallas registradas
│   │   ├── ScreenRegistry.qml        # Catálogo de pantallas (rutas ../../screens/slides/...)
│   │   ├── ScreenBase.qml            # Contenedor base para todas las pantallas
│   │   └── InputManager.qml          # Normalización de entrada y carga de ../../inputconfig.json
│   └── interaction/                  # Sistema de capas y navegación por foco
│       ├── LayerManager.qml          # Pila de capas (dashboard -> wheel/modal) y memoria de foco
│       └── FocusZone.qml             # Zona navegable (D-Pad, ciclo LT/RT, regla inert)
├── components/                       # Componentes visuales reutilizables
│   ├── chrome/                       # Elementos estructurales del overlay
│   │   ├── Bg.qml                    # Fondo con gradientes adaptativos
│   │   └── FocusRing.qml             # Anillo de foco global animado sobre FocusZone activa
│   ├── primitives/                   # Primitivas atómicas de UI
│   │   ├── buttons/                  # Botones reutilizables
│   │   ├── glyphs/                   # Glifos adaptativos por dispositivo
│   │   ├── sliders/                  # Controles deslizantes
│   │   └── text/                     # Tipografía y etiquetas
│   │       └── TestText.qml          # Componente de texto de prueba
│   └── widgets/                      # Widgets compuestos de alto nivel
├── screens/                          # Vistas del sistema
│   ├── slides/                       # Pantallas principales del carrusel
│   │   ├── TestScreen.qml
│   │   └── TestScreen2.qml
│   ├── overlays/                     # Overlays secundarios (ej. wheels / HUDs)
│   └── modals/                       # Diálogos y modales bloqueantes
└── docs/
    └── ARCHITECTURE.md
```

## Resumen de módulos y rutas

| Módulo | Ruta | Responsabilidad |
| :--- | :--- | :--- |
| Daemon | `ConsoleDaemon.qml` | Registro del plugin DMS e `IpcHandler` (`duxConsole`) |
| Overlay shell | `core/shell/ConsoleOverlay.qml` | `PanelWindow` Wayland, captura de teclas, `Bg` y `FocusRing` |
| Registro de pantallas | `core/shell/ScreenRegistry.qml` | Catálogo de slides en `../../screens/slides/` |
| Gestor de slides | `core/shell/SlideManager.qml` | `Loader` dinámico de slides e inyección de `inputManager` y `layerManager` |
| Base de pantalla | `core/shell/ScreenBase.qml` | Contenedor base con márgenes `Theme.spacingXL` |
| Entrada | `core/shell/InputManager.qml` | Traducción teclado/gamepad con `../../inputconfig.json` y gestos |
| Capas | `core/interaction/LayerManager.qml` | Pila `dashboard` → `wheel`/`modal` y memoria de foco por capa |
| Foco | `core/interaction/FocusZone.qml` | Navegación D-Pad, ciclo `LT`/`RT` y bloqueo `inert` |
| Chrome | `components/chrome/` | `Bg.qml` y `FocusRing.qml` |
| Primitivas | `components/primitives/` | `buttons/`, `sliders/`, `glyphs/` y `text/` (`TestText.qml`) |
| Widgets | `components/widgets/` | Widgets compuestos |
| Slides | `screens/slides/` | `TestScreen.qml`, `TestScreen2.qml` |
| Overlays / Modals | `screens/overlays/`, `screens/modals/` | Vistas apiladas sobre `dashboard` |

## Flujo de entrada y capas

1. `ConsoleOverlay` (`core/shell/ConsoleOverlay.qml`) captura eventos de teclado (y en el futuro gamepad vía `dconsole`) y los delega a `InputManager` (`core/shell/InputManager.qml`).
2. `InputManager` traduce códigos crudos usando `../../inputconfig.json` y emite la señal semántica `triggered(action, payload)`.
3. `ConsoleOverlay` enruta las acciones:
   - `I.Refuse`: intenta cerrar la capa superior con `layerManager.pop()`; si ya está en `"dashboard"`, cierra el overlay.
   - `I.ActionSlide.L` / `I.ActionSlide.R`: cambian de pantalla en `SlideManager` solo cuando la capa `"dashboard"` está activa.
   - D-Pad, `I.ActionOption.L/R`, `I.Accept`, `I.Action`: se delegan a `LayerManager.handleAction(...)`.
4. `LayerManager` (`core/interaction/LayerManager.qml`) mantiene la pila de capas (`dashboard` -> `wheel` / `modal`) y recuerda la última `FocusZone` activa de cada capa.
5. `FocusZone` (`core/interaction/FocusZone.qml`) aplica la regla `inert` cuando su `layerName` no coincide con `layerManager.activeLayer`, bloqueando navegación, activación y ciclo rápido `LT`/`RT`.
6. `FocusRing` (`components/chrome/FocusRing.qml`) sigue suavemente la geometría de `layerManager.activeZone` en el espacio de coordenadas del overlay.
