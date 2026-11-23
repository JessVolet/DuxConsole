# DuxConsole visual prototype architecture

Status: implemented as an isolated QML preview. Visual acceptance is tracked in the roadmap. Use the existing web mockup as the baseline for visual details and as a separate host for any later frontend extraction. DOM and QML views are separate renderers.

## Native file map

Paths are relative to DuxConsole. Reuse existing files where listed. Introduce new files only in the stage that needs them.

| Module | QML files and boundaries |
| --- | --- |
| M01 | `core/shell/{ConsoleOverlay,ScreenRegistry,SlideManager}.qml` register and mount the opt-in composition using the existing registry/source pattern. `components/chrome/{Bg,TopBar,FooterBar}.qml` keep ownership of persistent chrome. `components/chrome/CaptureQuickActions.qml` emits the three semantic capture intents via the composition root. |
| M02 | `core/shell/{StyleTokens,I18n,IconsPadManager}.qml`, `core/motion/MotionTokens.qml`, existing config files and locales. `components/primitives/{surfaces/SlantedSurface,text/DisplayTitle,glyphs/InputGlyph,buttons/ActionButton}.qml` own treatment and glyph rendering. Add `components/primitives/meters/ValueMeter.qml` for a reusable gauge/progress view. |
| M03 | Reuse `core/shell/InputManager.qml` and `core/interaction/{NavigationManager,FocusZone,LayerManager}.qml`. Keep one routing authority. Screens register capabilities and receive semantic signals. Extend existing contracts only when a demonstrated gap requires it. |
| M04 | `components/widgets/QueueCarousel.qml` and `CarouselLayout.js` own placement and transitions in fixture screens. Home, Audio, Capture, Launcher and Achievements supply delegates and selected IDs. The production `WindowCarousel.qml` and lab keep the existing `CarouselView.qml` PathView contract. Migration to the queue requires a separate compatibility check. |
| M05 | `screens/slides/MockHomeScreen.qml` assembles `components/widgets/{SessionHero,WindowCarousel,MediaPlayerCard,SocialStatusCard,AchievementDigest}.qml`. Keep active session and focused window as separate inputs. |
| M06 | `screens/slides/AudioScreen.qml` assembles `components/widgets/{AudioMixer,DeviceStrip,MediaPlayerCard}.qml` and the shared meter. Widgets emit intents with device and channel IDs; fixture service owns values. |
| M07 | `screens/slides/CaptureScreen.qml` assembles `components/widgets/{CaptureActions,CaptureGallery,CapturePreview}.qml`. Gallery delegates use QueueCarousel. Capture action handlers live at the injected mock service boundary. |
| M08 | `screens/slides/LauncherScreen.qml` assembles `components/widgets/{SessionHero,LibraryShelf,FilterBar}.qml`. App IDs, selection and filter state stay independent from renderer instances. |
| M09 | `screens/slides/AchievementsScreen.qml` assembles `components/widgets/{AchievementShelf,AchievementDetail}.qml` with QueueCarousel and the shared meter. |
| M10 | `screens/overlays/OrbitalMenu.qml` binds `components/widgets/{OrbitWheel,CommandPreview}.qml` to semantic command data and actions. Mount the overlay through registry-provided sources or a screen-owned Loader; keep the core import rule intact. |
| M11 | `screens/modals/{MediaDetailModal,CaptureViewerModal,CommandDetailsModal}.qml` assemble shared `components/chrome/{ModalPanel,Toast}.qml` and widgets supplied with view state. LayerManager restores focus. |
| M12 | `services/MockSession.qml` owns fixture state and action results using data from `fixtures/mockup/*.json`. Inject it through the existing composition root and screen property pattern. No widgets import the service or fixture directory. |

## Running the native preview

Run `./preview/run.sh` inside a Wayland session. The script stages the QML and fixture assets in a temporary directory and prints its shell path. In a second terminal, use that path for the isolated IPC target.

```sh
qs -p /path/printed/by/preview/shell.qml ipc call duxConsoleMock scene capture-viewer
qs -p /path/printed/by/preview/shell.qml ipc call duxConsoleMock state
qs -p /path/printed/by/preview/shell.qml ipc call duxConsoleMock frame /tmp/dux-frame.png
qs -p /path/printed/by/preview/shell.qml ipc call duxConsoleMock close
qs kill -p /path/printed/by/preview/shell.qml
```

`MockPreview.qml` is the standalone composition entry. The staging process exposes the minimum `qs.Common` and `qs.Widgets` theme/text contracts plus an icon adapter from `preview/compat`. This keeps the desktop theme singleton and compositor service out of the temporary process. The process uses a real Quickshell Wayland surface. `viewport WIDTH HEIGHT` constrains the captured content for layout comparisons, and `action I.ActionOption.R` drives the normal semantic dispatcher. Scene names and reference times are in `fixtures/mockup/scenes.json`. Native production still uses its normal DMS modules.

## Host lifecycle

Model dashboard visibility separately from host visibility. In fixture mode the host is visible while the dashboard or a wheel is open. A wheel can open from the backdrop without making the dashboard visible. Release exclusive keyboard focus when both are closed; keep the host hidden and preserve return focus for the next open. The fixture entry point mounts mock service objects instead of the production Niri and dconsole clients. Keep the existing IPC target and production composition available when fixture mode is disabled.

## Existing web reference

Inspected local source: `/home/vsynlo/Proyectos/Self/Mockups/DuxShell-Console/duxshell-web` at `6f0076fedd7bf8d2838cda4e25a3f0cee2c5ce07`. Its source tree was clean on inspection. It already uses Vite, TypeScript, DOM markup and `@m3e/web`. Preserve that stack if extracting reusable web modules later. Treat the recording as the visual acceptance source and inspect the web source for CSS values, fonts, easing, content variants and assets provenance.

| Web reference files | Reuse and boundary |
| --- | --- |
| `index.html`, `src/style.css`, `src/main.ts`, `src/media.css` | Measure shell, hero, palette, card geometry and media. `main.ts` combines multiple concerns, so translate each behavior into the mapped screen/widget rather than moving the entry point. |
| `src/carousel.ts`, `src/focus-ring.ts` | Reference wrapping and motion. Separate DOM writes from geometry for any future web extraction. Native QML keeps its own carousel and focus controls. |
| `src/{input,gamepad,pad-mapping,home-navigation,sound-navigation}.ts` | Inspect command semantics. QML adapts them to ControlFriendly, including D-pad zones and LT/RT item selection. |
| `src/{sound-hud,capture-hud,achievement-hud,action-wheels,viewer,panels}.ts` and paired CSS | Inspect module states and look. Move reusable state/intent contracts across hosts, while composing visual primitives in each host. |
| `src/data.ts`, `public/assets/{sources,extra-sources}.json` | Inventory fixture needs and asset provenance. Reuse approved assets and keep demo data outside portable view code. |

## Optional web extraction map

If another web host needs these components, extract in the existing web repository under `src/` with the boundaries below. The paths are relative to that repository. Use TypeScript DOM renderer modules instead of introducing a new framework. IDs point to [SPECS.md](SPECS.md).

| Module | Files | Ownership and reuse |
| --- | --- | --- |
| M01 | `src/app/App.ts`, `src/app/scenes.ts`, `src/ui/chrome/{OverlayShell,TopBar,FooterHints}.ts` | App is the composition root and resolves ports. Chrome receives state and semantic intents. A consuming app can mount the same Chrome with its own slots. |
| M02 | `src/theme/{tokens.json,motion.json,theme.css}`, `src/locales/{en,es}.json`, `src/ui/primitives/{Surface,Pill,ActionButton,InputGlyph,ValueMeter}.ts` | Export presentation primitives. Semantic tokens generate CSS custom properties through the theme entry. Glyphs resolve through config at the host boundary. |
| M03 | `src/core/{actions,focus,layers}.ts`, `src/ui/interaction/FocusZone.ts`, `src/config/{input,icons}.json` | Pure action and focus/layer state transitions, a DOM boundary for registration and focus effects, and provider-owned key/glyph maps. |
| M04 | `src/core/carousel.ts`, `src/ui/widgets/{Carousel,CarouselCard}.ts` | Pure viewport and ordered-ID calculation, visual transition ownership in the view. Render callback supplies each card's content. |
| M05 | `src/screens/HomeScreen.ts`, `src/ui/widgets/{SessionHero,WindowShelf,SocialCard,AchievementDigest}.ts` | Screen assembly. Home widgets accept normalized state and optional callbacks. |
| M06 | `src/screens/AudioScreen.ts`, `src/ui/widgets/{Mixer,DeviceStrip}.ts` | Screen assembles shared meter and media components with device widgets. |
| M07 | `src/screens/CaptureScreen.ts`, `src/ui/widgets/{CaptureActions,CaptureGallery,CapturePreview}.ts` | Gallery composes the shared carousel. Preview accepts resources, never produces captures itself. |
| M08 | `src/screens/LauncherScreen.ts`, `src/ui/widgets/{LibraryShelf,FilterBar}.ts` | Reuse SessionHero and Carousel with launcher presets and slots. |
| M09 | `src/screens/AchievementsScreen.ts`, `src/ui/widgets/{AchievementShelf,AchievementDetail}.ts` | Use common selection and progress primitives with achievement-specific renderers. |
| M10 | `src/screens/overlays/WheelOverlay.ts`, `src/ui/widgets/{OrbitWheel,CommandPreview}.ts`, `src/config/commands.ts` | Screen binds registered command definitions to generic wheel arcs and preview slots. |
| M11 | `src/screens/modals/DetailLayer.ts`, `src/ui/widgets/MediaPlayer.ts`, `src/ui/chrome/{Dialog,Toast}.ts` | Shared chrome and player receive view data. Screens choose detail composition and bind action intents. |
| M12 | `src/contracts/{session,ports}.ts`, `src/adapters/{mockSession,browserInput}.ts`, `src/fixtures/{dashboard,audio,capture,library,achievements,wheels}.ts`, `public/fixtures/` | Contracts define normalized serializable state and injected ports. Adapter owns demo mutations and input event subscriptions. Fixtures and assets live outside reusable code. |

## Dependency direction and public interfaces

- `app → screens, chrome, adapters, config`. Screens assemble widgets and bind injected intents. Screen CSS handles placement. Widgets use primitives, core interactions, theme roles and contract types. Primitives use theme and view props. Core imports contract types only. Adapters depend on ports and fixtures. The composition root injects effectful dependencies. No screen-to-screen imports.
- `SessionPort` exposes `getSnapshot(): SessionSnapshot`, `subscribe(listener): unsubscribe` and `dispatch(intent): Promise<ActionResult>`. Use identified records for windows, sessions, devices, media, captures, library entries and achievements. `ActionResult` discriminates success, unavailable and error and carries a message key and optional interpolation values. Treat invalid IDs as unavailable.
- `FocusZone` registers a stable zone ID, layer, optional neighbors, ordered item IDs, default focus and capabilities. The focus controller handles `dispatch(action)` and yields the active zone, selected item and hint list. Pointer activation uses the same intents as gamepad. Visual hover is local and never silently changes controller ownership.
- `Carousel` accepts item IDs, selected ID, layout preset, motion tokens, `renderCard(id, state)` and selection/activation callbacks. Keep render keys stable by ID. Derive the visible budget from count and geometry. Cache only transition slots necessary for enter/exit, and prevent duplicate visible IDs. Side cards and title labels remain upright inside slanted surfaces.
- Reuse by moving primitives and widgets with their explicit theme, locale and motion dependencies into another web host. Provide a second composition route with an independent fixture set to prove reuse before extracting a package. No DuxShell brand, game fixtures or browser globals inside pure core or portable widgets.

## DuxConsole correspondence

| Web contract | Native reference |
| --- | --- |
| Shell, status and hints | `ConsoleOverlay`, `TopBar`, `FooterBar`, `NavigationManager.activeHints` |
| Input, focus and layers | `InputManager`, `FocusZone`, `NavigationManager`, `LayerManager` |
| Style, motion and glyphs | `StyleTokens`, `MotionTokens`, `I18n`, `IconsPadManager`, `InputGlyph` |
| Carousel and media compositions | `CarouselView`, `WindowCarousel`, `MediaPlayerCard` |
| Window fixture shape | Normalized window identity and metadata from `WindowManager`; no socket access in the web host |

Keep the native dependency rules and composition-root exception in root `AGENTS.md`. Run native IPC and focus regression checks whenever plugin composition changes. Each host retains its platform-specific adapters.
