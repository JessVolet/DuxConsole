import QtQuick
import qs.Common
import qs.Widgets
import "../../core/interaction"
import "../../components/primitives/buttons"

Rectangle {
    id: modal

    property var layerManager: null
    property var i18n: null
    property string layerName: "modal"
    property string title: ""
    // Lista de { labelKey: "...", fallback: "..." }
    property var options: []

    signal optionSelected(int index, string label)

    readonly property bool open: layerManager?.topLayer === layerName

    anchors.fill: parent
    visible: open
    color: Theme.withAlpha(Theme.surface, 0.72)

    StyledRect {
        id: card
        anchors.centerIn: parent
        width: 360
        height: col.implicitHeight + Theme.spacingXL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHighest

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingXL
            spacing: Theme.spacingM

            StyledText {
                text: modal.title
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                color: Theme.surfaceText ?? "#F2F4F8"
            }

            Repeater {
                id: optRepeater
                model: modal.options
                delegate: FocusZone {
                    id: optZone
                    required property int index
                    required property var modelData

                    readonly property string resolvedLabel: modal.i18n
                        ? modal.i18n.t(modelData.labelKey, modelData.fallback ?? "")
                        : (modelData.fallback ?? "")

                    zoneId: "modal-opt-" + index
                    layerName: modal.layerName
                    layerManager: modal.layerManager
                    visible: modal.open
                    navUp: index > 0 ? "modal-opt-" + (index - 1) : null
                    navDown: index < (modal.options.length - 1) ? "modal-opt-" + (index + 1) : null
                    width: col.width
                    height: 48
                    ringRadius: Theme.cornerRadius

                    onActivated: {
                        modal.optionSelected(index, resolvedLabel)
                        modal.layerManager?.pop()
                    }

                    ActionButton {
                        anchors.fill: parent
                        focused: optZone.active
                        label: optZone.resolvedLabel
                    }
                }
            }
        }
    }
}
