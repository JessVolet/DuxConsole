import QtQuick
import qs.Common
import "../primitives/surfaces"

Item {
    id: frame

    property var styleTokens: null
    property real preferredWidth: 520
    property real preferredHeight: 350
    property string accessibleLabel: ""
    default property alias body: panel.content

    z: 40
    Accessible.role: Accessible.Dialog
    Accessible.name: accessibleLabel

    Rectangle {
        anchors.fill: parent
        color: frame.styleTokens?.scrimColor(1) ?? Theme.withAlpha(Theme.surface, 0.72)
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    SlantedSurface {
        id: panel

        anchors.centerIn: parent
        width: Math.max(0, Math.min(frame.preferredWidth, frame.width - Theme.spacingXL * 2))
        height: Math.max(0, Math.min(frame.preferredHeight, frame.height - Theme.spacingXL * 2))
        styleTokens: frame.styleTokens
        skewAngle: 0
    }
}
