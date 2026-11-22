import QtQuick
import qs.Common
import "../../core/shell"
import "../../core/interaction"
import "../../components/chrome"
import "../../components/primitives/buttons"
import "../../components/primitives/text"
import "../modals"

ScreenBase {
    id: root
    screenId: "test1"
    title: root.tr("nav.home", "Home")

    property string lastModalSelection: ""
    readonly property var _devices: ["keyboard", "xbox", "playstation"]

    function cycleDevice() {
        if (!root.inputManager)
            return
        const idx = _devices.indexOf(root.inputManager.activeDevice)
        root.inputManager.activeDevice = _devices[(idx + 1) % _devices.length]
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.spacingL

        TestText {
            label: root.tr("demo.title", "DuxConsole — ControlFriendly Demo")
        }

        // Zona 1: Botón simple (I.Accept) -> rota dispositivo de glifos
        FocusZone {
            id: zoneButton
            zoneId: "zone-button"
            layerName: "dashboard"
            layerManager: root.layerManager
            navDown: zoneCarousel
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

        // Zona 2: Carrusel de 4 ítems (LT/RT) + expansión a modal (I.Select)
        ActionHints {
            iconsPadManager: root.iconsPadManager
            i18n: root.i18n
            hints: [
                { action: "I.ActionOption.L", labelKey: "hints.cycle", fallback: "Cycle item" },
                { action: "I.ActionOption.R", labelKey: "hints.cycle", fallback: "Cycle item" },
                { action: "I.Select", labelKey: "hints.expand", fallback: "Expand" }
            ]
        }

        FocusZone {
            id: zoneCarousel
            zoneId: "zone-carousel"
            layerName: "dashboard"
            layerManager: root.layerManager
            navUp: zoneButton
            subItemCount: 4
            width: carouselRow.implicitWidth + Theme.spacingM * 2
            height: 112
            ringRadius: Theme.cornerRadius

            onExpandRequested: root.layerManager?.push("modal")

            Row {
                id: carouselRow
                anchors.centerIn: parent
                spacing: Theme.spacingM

                Repeater {
                    model: 4
                    delegate: FocusCard {
                        required property int index
                        selected: zoneCarousel.currentSubIndex === index
                        focused: zoneCarousel.active
                        title: root.tr("demo.item_prefix", "Item") + " #" + (index + 1)
                        subtitle: selected ? root.lastModalSelection : ""
                    }
                }
            }
        }
    }

    ActionHints {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        iconsPadManager: root.iconsPadManager
        i18n: root.i18n
        hints: [
            { action: "I.Dpad.Up", labelKey: "hints.navigate", fallback: "Navigate" },
            { action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" },
            { action: "I.Refuse", labelKey: "hints.back", fallback: "Back / Close" }
        ]
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
