import QtQuick
import qs.Common
import qs.Widgets
import "../surfaces"

SlantedSurface {
    id: card

    property string title: ""
    property string subtitle: ""
    property var motionTokens: null

    role: "card"
    implicitWidth: 180
    implicitHeight: 120

    Behavior on width {
        NumberAnimation {
            duration: card.motionTokens ? card.motionTokens.durationNormal : 0
            easing.type: card.motionTokens ? card.motionTokens.easingSnappy : Easing.Linear
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: card.motionTokens ? card.motionTokens.durationNormal : 0
            easing.type: card.motionTokens ? card.motionTokens.easingSnappy : Easing.Linear
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
