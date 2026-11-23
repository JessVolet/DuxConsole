pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../../core/interaction"
import "../../components/widgets"
import "../../components/primitives/buttons"
import "../../components/primitives/text"

FixtureModalFrame {
    id: modal

    property var entry: null
    property var layerManager: null
    property var navigationManager: null
    property var iconsPadManager: null
    property string title: ""
    property string focusLabel: ""

    signal activationRequested(var id)

    preferredWidth: 420
    preferredHeight: contentColumn.implicitHeight + Theme.spacingXL * 2
    accessibleLabel: title
    visible: layerManager?.topLayer === "mock-window-options"

    Column {
        id: contentColumn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingM

        DisplayTitle {
            width: parent.width
            text: modal.entry?.title || modal.title
            textFormat: Text.PlainText
            elide: Text.ElideRight
            styleTokens: modal.styleTokens
        }

        FocusZone {
            id: focusOption
            zoneId: "mock-window-focus-option"
            layerName: "mock-window-options"
            layerManager: modal.layerManager
            navigationManager: modal.navigationManager
            defaultFocus: true
            showFocusRing: false
            width: focusButton.implicitWidth
            height: focusButton.implicitHeight
            enabled: modal.entry !== null
            actionHints: [{ action: "I.Accept", labelKey: "windows.hint_focus", fallback: "Focus window" }]

            onActivated: {
                if (modal.entry)
                    modal.activationRequested(modal.entry.id)
            }

            ActionPill {
                id: focusButton
                anchors.fill: parent
                text: modal.focusLabel
                glyphAction: "I.Accept"
                highlighted: focusOption.active
                primary: true
                iconsPadManager: modal.iconsPadManager
                styleTokens: modal.styleTokens
                enabled: !focusOption.inert && focusOption.enabled
                onClicked: {
                    if (focusOption.requestZoneFocus())
                        focusOption.activate()
                }
            }
        }
    }
}
