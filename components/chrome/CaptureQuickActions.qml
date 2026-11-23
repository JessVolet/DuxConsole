pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets as DCommon

Row {
    id: shortcuts

    property var styleTokens: null
    property var i18n: null
    property bool recording: false
    property int elapsed: 0
    property bool showShortcuts: true
    property bool controlsEnabled: true
    signal actionRequested(string intent)

    spacing: Theme.spacingS

    Repeater {
        model: shortcuts.showShortcuts ? [
            { intent: "capture.screenshot", icon: "photo_camera", label: "mockup.screenshot" },
            { intent: "capture.record", icon: shortcuts.recording ? "stop_circle" : "videocam", label: "mockup.record" },
            { intent: "capture.replay", icon: "replay", label: "mockup.replay" }
        ] : []
        delegate: Rectangle {
            id: shortcut
            required property var modelData

            width: Theme.iconSize + Theme.spacingS
            height: width
            radius: width / 2
            color: shortcuts.styleTokens ? shortcuts.styleTokens.surfaceColor("chrome") : Theme.surfaceContainerHigh
            enabled: shortcuts.controlsEnabled
            Accessible.role: Accessible.Button
            Accessible.name: shortcuts.i18n?.t(modelData.label) ?? modelData.label
            Accessible.ignored: !shortcuts.controlsEnabled
            Accessible.onPressAction: {
                if (shortcuts.controlsEnabled)
                    shortcuts.actionRequested(modelData.intent)
            }

            DCommon.DIcon {
                anchors.centerIn: parent
                name: shortcut.modelData.icon
                size: Theme.iconSize * 0.7
                color: shortcuts.styleTokens ? shortcuts.styleTokens.onSurfaceColor("chrome") : Theme.surfaceText
            }
            TapHandler {
                onTapped: shortcuts.actionRequested(shortcut.modelData.intent)
            }
        }
    }
    Rectangle {
        visible: shortcuts.recording
        implicitWidth: recordingLabel.implicitWidth + Theme.spacingM * 2
        implicitHeight: Theme.iconSize + Theme.spacingS
        radius: height / 2
        color: shortcuts.styleTokens?.surfaceColor("chrome") ?? Theme.surfaceContainerHigh
        Accessible.role: Accessible.StaticText
        Accessible.name: recordingLabel.text

        StyledText {
            id: recordingLabel
            anchors.centerIn: parent
            text: {
                const minutes = Math.floor(shortcuts.elapsed / 60).toString().padStart(2, "0")
                const seconds = (shortcuts.elapsed % 60).toString().padStart(2, "0")
                return "● " + minutes + ":" + seconds
            }
            color: shortcuts.styleTokens?.onSurfaceColor("chrome") ?? Theme.surfaceText
            font.weight: Font.DemiBold
        }
    }

}
