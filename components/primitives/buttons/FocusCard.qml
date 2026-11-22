import QtQuick
import qs.Common
import qs.Widgets

StyledRect {
    id: card

    property string title: ""
    property string subtitle: ""
    property bool selected: false
    property bool focused: false

    implicitWidth: 148
    implicitHeight: 88
    radius: Theme.cornerRadius
    color: selected ? Theme.primaryContainer : (focused ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
    border.width: selected ? 2 : 0
    border.color: Theme.primary

    Column {
        anchors.centerIn: parent
        spacing: 4

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.title
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Bold
            color: card.selected ? Theme.onPrimaryContainer : Theme.onSurface
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: card.subtitle !== ""
            text: card.subtitle
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.onSurfaceVariant
        }
    }
}
