pragma ComponentBehavior: Bound
import QtQuick
import qs.Common

// Translucent section surface for the Sound tab. It is only a background:
// content keeps its own layout and interaction.
Item {
    id: panel

    property real padding: Theme.spacingL
    property real radius: Theme.cornerRadius
    property real backgroundOpacity: 0.72
    property var styleTokens: null

    default property alias content: inner.data

    Rectangle {
        anchors.fill: parent
        radius: panel.radius
        color: panel.styleTokens
               ? panel.styleTokens.surfaceColor("card", panel.backgroundOpacity)
               : Qt.alpha(Theme.surfaceContainerHigh, 0.62)
        border.width: 1
        border.color: panel.styleTokens
                      ? panel.styleTokens.borderColor("card")
                      : Qt.alpha(Theme.outlineVariant, 0.5)
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: panel.padding
    }
}
