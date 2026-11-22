import QtQuick
import qs.Common
import qs.Widgets
import "../surfaces"

SlantedSurface {
    id: card

    property var motionTokens: null
    property string title: ""
    property string subtitle: ""

    role: "card"
    implicitWidth: selected ? 188 : 148
    implicitHeight: 92

    Behavior on implicitWidth {
        NumberAnimation {
            duration: card.motionTokens ? card.motionTokens.durationNormal : 220
            easing.type: card.motionTokens ? card.motionTokens.easingSnappy : Easing.OutCubic
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 4

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.title
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Bold
            color: card.styleTokens ? card.styleTokens.onSurfaceColor("card") : Theme.onSurface
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: card.subtitle !== ""
            text: card.subtitle
            font.pixelSize: Theme.fontSizeSmall
            color: card.styleTokens ? card.styleTokens.accentColor : Theme.onSurfaceVariant
        }
    }
}
