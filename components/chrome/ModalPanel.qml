import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: panel

    property var styleTokens: null
    default property alias content: contentArea.data

    StyledRect {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: panel.styleTokens ? panel.styleTokens.surfaceColor("card") : Theme.surfaceContainerHighest
        border.width: 1
        border.color: panel.styleTokens ? panel.styleTokens.borderColor("card") : Theme.outlineVariant
    }

    Item {
        id: contentArea
        anchors.fill: parent
    }
}
