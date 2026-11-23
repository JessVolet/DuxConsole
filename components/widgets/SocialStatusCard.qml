pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/surfaces"

SlantedSurface {
    id: social

    property var status: null
    property string unavailableLabel: ""
    readonly property int avatarSize: Math.min(34, Math.max(20, Math.round(height * 0.46)))

    implicitWidth: 240
    implicitHeight: 66
    skewAngle: 0
    radius: height * 0.34

    Row {
        anchors.centerIn: parent
        spacing: Theme.spacingXS

        Repeater {
            model: Array.isArray(social.status?.members) ? social.status.members.slice(0, 4) : []

            delegate: Rectangle {
                required property string modelData
                width: social.avatarSize
                height: width
                radius: width / 2
                color: social.styleTokens?.surfaceColor("chrome") ?? Theme.surfaceContainerHigh

                StyledText {
                    anchors.centerIn: parent
                    text: parent.modelData.slice(0, 2).toUpperCase()
                    textFormat: Text.PlainText
                    font.pixelSize: Theme.fontSizeSmall
                    color: social.styleTokens?.onSurfaceColor("chrome") ?? Theme.surfaceText
                }
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: social.status?.room || social.unavailableLabel
            textFormat: Text.PlainText
            font.pixelSize: Theme.fontSizeSmall
            color: social.styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText
        }
    }
}
