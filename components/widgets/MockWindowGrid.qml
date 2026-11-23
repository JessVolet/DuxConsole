pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../../core/interaction"

Grid {
    id: grid

    property var entries: []
    property var selectedId
    property var layerManager: null
    property var navigationManager: null
    property var styleTokens: null
    property var motionTokens: null
    property string layerName: "mock-windows"
    property string optionsLabel: ""

    signal activationRequested(var id)
    signal optionsRequested(var id)
    signal activeRowChanged(real top, real height)

    spacing: Theme.spacingL
    columns: width < 650 ? 2 : 3

    Repeater {
        model: grid.entries

        delegate: FocusZone {
            id: cell

            required property var modelData

            width: (grid.width - grid.spacing * (grid.columns - 1)) / grid.columns
            height: Math.min(210, width * 0.63)
            zoneId: "mock-grid-window-" + modelData.id
            layerName: grid.layerName
            layerManager: grid.layerManager
            navigationManager: grid.navigationManager
            defaultFocus: modelData.id === grid.selectedId
            showFocusRing: false
            actionHints: [
                { action: "I.Accept", labelKey: "windows.hint_focus", fallback: "Focus window" },
                { action: "I.Options", labelKey: "windows.hint_options", fallback: "Window options" }
            ]

            onActivated: grid.activationRequested(modelData.id)
            onOptionsTriggered: grid.optionsRequested(modelData.id)
            onActiveChanged: {
                if (active)
                    grid.activeRowChanged(y, height)
            }

            MockWindowCard {
                id: card
                anchors.fill: parent
                itemData: cell.modelData
                selected: true
                focused: cell.active
                interactive: !cell.inert
                styleTokens: grid.styleTokens
                motionTokens: grid.motionTokens
                optionsLabel: grid.optionsLabel
                onOptionsRequested: {
                    if (cell.requestZoneFocus())
                        cell.triggerOptions()
                }
            }

            TapHandler {
                enabled: !cell.inert
                onTapped: eventPoint => {
                    if (!card.optionsContain(eventPoint.position) && cell.requestZoneFocus())
                        cell.activate()
                }
            }
        }
    }
}
