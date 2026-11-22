import QtQuick
import qs.Common
import qs.Widgets

StyledRect {
    id: card

    property string label: "Texto:D"

    implicitWidth: txt.implicitWidth + Theme.spacingXL * 2
    implicitHeight: txt.implicitHeight + Theme.spacingL * 2
    radius: Theme.cornerRadius
    color: Theme.surfaceContainerHigh

    StyledText {
        id: txt
        anchors.centerIn: parent
        text: card.label
        font.pixelSize: Theme.fontSizeXXLarge
        font.weight: Font.Bold
        color: Theme.primary
    }
}