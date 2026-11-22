pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../../core/shell"
import "../../core/interaction"
import "../../components/chrome"
import "../../components/primitives/buttons"
import "../../components/primitives/text"
import "../../components/widgets"
import "../modals"

ScreenBase {
    id: root
    screenId: "test1"
    title: root.tr("nav.home", "Home")

    property string lastModalSelection: ""
    readonly property var _devices: ["keyboard", "xbox", "playstation"]
    readonly property var _themeModes: ["hybrid", "dark", "light"]

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
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.spacingL

        TestText {
            label: root.tr("demo.title", "DuxConsole — ControlFriendly Demo")
        }

        Row {
            spacing: Theme.spacingM

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

        // Zona 3: Carrusel infinito con FocusCard inclinadas (LT/RT) + modal (I.Select)
        FocusZone {
            id: zoneCarousel
            zoneId: "zone-carousel"
            layerName: "dashboard"
            layerManager: root.layerManager
            navigationManager: root.navigationManager
            expandable: true
            subItemCount: carousel.count
            actionHints: [
                { action: "I.ActionOption.L", labelKey: "hints.cycle", fallback: "Cycle item" },
                { action: "I.ActionOption.R", labelKey: "hints.cycle", fallback: "Cycle item" },
                { action: "I.Select", labelKey: "hints.expand", fallback: "Expand" }
            ]
            width: parent.width
            height: carousel.implicitHeight
            ringRadius: Theme.cornerRadius

            onExpandRequested: root.layerManager?.push("modal")

            CarouselView {
                id: carousel
                anchors.fill: parent
                currentIndex: zoneCarousel.currentSubIndex
                motionTokens: root.motionTokens
                focused: zoneCarousel.active
                model: 6
                delegate: FocusCard {
                    property int index: 0
                    styleTokens: root.styleTokens
                    title: root.tr("demo.item_prefix", "Item") + " #" + (index + 1)
                    subtitle: selected ? root.lastModalSelection : ""
                }
            }
        }
    }

    ActionHints {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        iconsPadManager: root.iconsPadManager
        i18n: root.i18n
        hints: root.navigationManager ? root.navigationManager.activeHints : []
    }

    ItemOptionsModal {
        layerManager: root.layerManager
        i18n: root.i18n
        title: root.tr("demo.modal_title", "Item Options") + " (#" + (zoneCarousel.currentSubIndex + 1) + ")"
        options: [
            { labelKey: "demo.modal_option_1", fallback: "Launch" },
            { labelKey: "demo.modal_option_2", fallback: "Pin" },
            { labelKey: "demo.modal_option_3", fallback: "Details" }
        ]
        onOptionSelected: (_, label) => root.lastModalSelection = label
    }
}
