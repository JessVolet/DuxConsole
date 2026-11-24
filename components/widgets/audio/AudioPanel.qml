pragma ComponentBehavior: Bound
import QtQuick
import qs.Common

// Material 3 section surface: tonal container, rounded, no outline. Content
// keeps its own layout and interaction.
Item {
    id: panel

    property real padding: Theme.spacingL
    property real radius: 28
    property real backgroundOpacity: 0.92
    property var styleTokens: null
    property bool outlined: false

    default property alias content: inner.data

    Rectangle {
        anchors.fill: parent
        radius: panel.radius
        color: panel.styleTokens
               ? panel.styleTokens.m3Alpha(panel.styleTokens.m3SurfaceLow, panel.backgroundOpacity)
               : Qt.alpha(Theme.surfaceContainerLow, panel.backgroundOpacity)
        border.width: panel.outlined ? 1 : 0
        border.color: panel.styleTokens ? panel.styleTokens.m3OutlineVariant : Theme.outlineVariant
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: panel.padding
    }
}
