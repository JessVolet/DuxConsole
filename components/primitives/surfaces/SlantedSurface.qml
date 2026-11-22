import QtQuick
import qs.Common

Item {
    id: surface

    property var styleTokens: null
    property string role: "card" // "card" | "chrome"
    property real skewAngle: styleTokens ? styleTokens.skewAngle : -8
    property bool focused: false
    property bool selected: false
    property real radius: Theme.cornerRadius
    default property alias content: contentContainer.data

    readonly property real _shearX: Math.tan(skewAngle * Math.PI / 180)
    readonly property color resolvedSurfaceColor: styleTokens
        ? styleTokens.surfaceColor(role)
        : Theme.surfaceContainerHigh
    readonly property color resolvedBorderColor: (focused || selected)
        ? (styleTokens ? styleTokens.accentColor : Theme.primary)
        : (styleTokens ? styleTokens.borderColor(role) : Theme.outlineVariant)

    Rectangle {
        id: bgShape
        anchors.fill: parent
        radius: surface.radius
        color: surface.resolvedSurfaceColor
        border.width: (surface.focused || surface.selected) ? 2 : 1
        border.color: surface.resolvedBorderColor
        antialiasing: true

        transform: Matrix4x4 {
            matrix: Qt.matrix4x4(
                1, surface._shearX, 0, 0,
                0, 1,               0, 0,
                0, 0,               1, 0,
                0, 0,               0, 1
            )
        }
    }

    Item {
        id: contentContainer
        anchors.fill: parent
    }
}
