import QtQuick
import qs.Common
import qs.Widgets
import "../surfaces"

SlantedSurface {
    id: card

    property string title: ""
    property string subtitle: ""

    role: "card"
    implicitWidth: 180
    implicitHeight: 120

    Column {
        anchors.centerIn: parent
        spacing: 4

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.title
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Bold
            color: card.styleTokens ? card.styleTokens.onSurfaceColor("card") : (Theme.surfaceText ?? "#F2F4F8")
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: card.subtitle !== ""
            text: card.subtitle
            font.pixelSize: Theme.fontSizeSmall
            color: card.styleTokens ? card.styleTokens.accentColor : (Theme.surfaceVariantText ?? "#9CA3AF")
        }
    }
}
