pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../../core/shell"
import "../../core/interaction"
import "../../components/primitives/buttons"
import "../../components/primitives/surfaces"
import "../../components/primitives/text"
import "../../components/widgets"
import "../modals"

ScreenBase {
    id: root
    screenId: "test1"
    title: root.tr("nav.home", "Home")

    property int modalTargetWindowId: -1
    property string ipcErrorNotice: ""
    readonly property var _devices: ["keyboard", "xbox", "playstation"]
    readonly property var _themeModes: ["hybrid", "dark", "light"]

    readonly property url previewImageUrl: {
        const dev = root.inputManager?.activeDevice ?? "keyboard"
        if (dev === "xbox")
            return Qt.resolvedUrl("../../assets/InputIcons/Preview Xbox Series.png")
        if (dev === "playstation")
            return Qt.resolvedUrl("../../assets/InputIcons/Preview PlayStation Series.png")
        return Qt.resolvedUrl("../../assets/InputIcons/Preview Keyboard & Mouse.png")
    }

    function cycleDevice() {
        if (!root.inputManager)
            return
        const idx = _devices.indexOf(root.inputManager.activeDevice)
        root.inputManager.activeDevice = _devices[(idx + 1) % _devices.length]
    }

    function cycleThemeMode() {
        if (!root.styleTokens)
            return
        const idx = _themeModes.indexOf(root.styleTokens.themeMode)
        root.styleTokens.themeMode = _themeModes[(idx + 1) % _themeModes.length]
    }

    Column {
        id: layoutCol
        anchors.fill: parent
        spacing: Theme.spacingL

        // Área principal de contenido (controles a la izquierda + SlantedImage a la derecha)
        Row {
            width: layoutCol.width
            spacing: Theme.spacingXL

            Column {
                width: Math.min(440, layoutCol.width * 0.55)
                spacing: Theme.spacingM

                SectionTitle {
                    styleTokens: root.styleTokens
                    title: root.tr("demo.controls_section", "Lab Controls")
                    subtitle: root.tr("demo.title", "DuxConsole — ControlFriendly Demo")
                }

                // Zona 1: Botón para rotar dispositivo de glifos
                FocusZone {
                    id: zoneButton
                    zoneId: "zone-button"
                    layerName: "dashboard"
                    layerManager: root.layerManager
                    navigationManager: root.navigationManager
                    defaultFocus: true
                    actionHints: [
                        { action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" }
                    ]
                    width: btnDevice.width
                    height: btnDevice.height
                    ringRadius: Theme.cornerRadius

                    onActivated: root.cycleDevice()

                    ActionButton {
                        id: btnDevice
                        focused: zoneButton.active
                        styleTokens: root.styleTokens
                        motionTokens: root.motionTokens
                        iconsPadManager: root.iconsPadManager
                        action: "I.Accept"
                        label: root.tr("demo.button_label", "Switch glyph device")
                               + " (" + (root.inputManager?.activeDevice ?? "keyboard") + ")"
                    }
                }

                // Zona 2: Botón para rotar theme.mode (hybrid -> dark -> light)
                FocusZone {
                    id: zoneTheme
                    zoneId: "zone-theme"
                    layerName: "dashboard"
                    layerManager: root.layerManager
                    navigationManager: root.navigationManager
                    actionHints: [
                        { action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" }
                    ]
                    width: btnTheme.width
                    height: btnTheme.height
                    ringRadius: Theme.cornerRadius

                    onActivated: root.cycleThemeMode()

                    ActionButton {
                        id: btnTheme
                        focused: zoneTheme.active
                        styleTokens: root.styleTokens
                        motionTokens: root.motionTokens
                        iconsPadManager: root.iconsPadManager
                        action: "I.Accept"
                        label: {
                            const mode = root.styleTokens?.themeMode ?? "hybrid"
                            return root.tr("demo.theme_label", "Theme mode")
                                   + " (" + root.tr("demo.theme_modes." + mode, mode) + ")"
                        }
                    }
                }
            }

            Column {
                width: Math.max(240, layoutCol.width - Math.min(440, layoutCol.width * 0.55) - Theme.spacingXL)
                spacing: Theme.spacingM

                SectionTitle {
                    styleTokens: root.styleTokens
                    title: root.tr("demo.preview_section", "Slanted Preview")
                }

                SlantedImage {
                    width: Math.min(420, parent.width)
                    height: 160
                    styleTokens: root.styleTokens
                    motionTokens: root.motionTokens
                    source: root.previewImageUrl
                    fallbackText: root.tr("demo.preview_fallback", "No preview")
                    focused: false
                }
            }
        }

        // Sección de carrusel real de ventanas Niri (FocusZone única con LT/RT + I.Accept + I.Options)
        SectionTitle {
            styleTokens: root.styleTokens
            title: root.tr("demo.carousel_section", "ControlFriendly Carousel (LT / RT)")
            subtitle: root.ipcErrorNotice !== ""
                      ? root.ipcErrorNotice
                      : (windowCarousel.selectedWindow
                         ? windowCarousel.selectedWindow.appName + " — " + windowCarousel.selectedWindow.title
                         : "")
        }

        WindowCarousel {
            id: windowCarousel
            width: layoutCol.width
            windowManager: root.windowManager
            layerManager: root.layerManager
            navigationManager: root.navigationManager
            styleTokens: root.styleTokens
            motionTokens: root.motionTokens
            i18n: root.i18n

            onActivateWindowRequested: winId => {
                root.ipcErrorNotice = ""
                root.windowManager?.focusWindow(winId, (ok, err) => {
                    if (ok)
                        root.closeOverlayRequested()
                    else
                        root.ipcErrorNotice = root.tr("windows.errors." + String(err), root.tr("windows.errors.unknown", "The window action could not be completed."))
                })
            }

            onWindowOptionsRequested: winId => {
                root.ipcErrorNotice = ""
                root.modalTargetWindowId = winId
                root.layerManager?.push("modal")
            }
        }
    }

    WindowOptionsModal {
        sourceItem: windowCarousel.selectedCardItem
        windowManager: root.windowManager
        layerManager: root.layerManager
        navigationManager: root.navigationManager
        styleTokens: root.styleTokens
        motionTokens: root.motionTokens
        iconsPadManager: root.iconsPadManager
        i18n: root.i18n
        targetWindowId: root.modalTargetWindowId
    }
}
