import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: toast

    property string message: ""
    property var styleTokens: null
    property var motionTokens: null

    implicitWidth: label.implicitWidth + Theme.spacingL * 2
    implicitHeight: label.implicitHeight + Theme.spacingM * 2
    radius: Theme.cornerRadius
    color: styleTokens ? styleTokens.surfaceColor("chrome") : Theme.surfaceContainerHigh
    visible: opacity > 0
    opacity: message.length > 0 ? 1 : 0
    Accessible.role: Accessible.AlertMessage
    Accessible.ignored: !visible || !message.length
    Accessible.name: message

    Behavior on opacity {
        NumberAnimation {
            duration: toast.motionTokens ? toast.motionTokens.durationFast : 0
        }
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        text: toast.message
        color: toast.styleTokens ? toast.styleTokens.onSurfaceColor("chrome") : Theme.surfaceText
    }
}
