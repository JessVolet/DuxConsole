import QtQuick
import qs.Common
import "../primitives/surfaces"

Item {
    id: frame

    property var styleTokens: null
    property real preferredWidth: 520
    property real preferredHeight: 350
    property string accessibleLabel: ""
    property bool accessibilityActive: visible
    property int entranceDuration: 0
    property int entranceEasing: Easing.OutCubic
    property real panelProgress: 1

    onVisibleChanged: {
        if (visible && entranceDuration > 0)
            entrance.restart()
        else {
            entrance.stop()
            panelProgress = 1
        }
    }

    onEntranceDurationChanged: {
        if (entranceDuration === 0) {
            entrance.stop()
            panelProgress = 1
        }
    }

    NumberAnimation {
        id: entrance
        target: frame
        property: "panelProgress"
        duration: frame.entranceDuration
        from: 0
        to: 1
        easing.type: frame.entranceEasing
    }
    default property alias body: panel.content

    z: 40
    Accessible.role: Accessible.Dialog
    Accessible.name: accessibleLabel
    Accessible.ignored: !visible || !accessibilityActive

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
        anchors.verticalCenterOffset: (1 - frame.panelProgress) * Theme.spacingM
        opacity: frame.panelProgress
        width: Math.max(0, Math.min(frame.preferredWidth, frame.width - Theme.spacingXL * 2))
        height: Math.max(0, Math.min(frame.preferredHeight, frame.height - Theme.spacingXL * 2))
        styleTokens: frame.styleTokens
        skewAngle: 0
    }
}
