import QtQuick
import QtQuick.Effects
import qs.Common

Item {
    id: surface

    property var styleTokens: null
    property var motionTokens: null
    property string role: "card" // "card" | "chrome"
    property real skewAngle: styleTokens ? styleTokens.skewAngle : -8
    property bool focused: false
    property bool selected: false
    property bool disabled: !enabled
    property bool borderOnly: false
    property int focusedBorderWidth: 3
    property int selectedBorderWidth: 2
    property real radius: Theme.cornerRadius
    property real surfaceOpacity: 1.0
    property int borderWidth: !disabled && focused
        ? focusedBorderWidth
        : (!disabled && selected ? selectedBorderWidth : 1)
    property alias backdrop: backdropContainer.data
    default property alias content: contentContainer.data

    readonly property real _shearX: Math.tan(skewAngle * Math.PI / 180)
    readonly property int _animDuration: motionTokens ? motionTokens.durationFast : 120
    readonly property int _animEasing: motionTokens ? motionTokens.easingSnappy : Easing.OutCubic

    // Superficies sólidas (alfa 1.0), sin transparencia ni opacity sobre contenedores
    readonly property color resolvedSurfaceColor: {
        if (borderOnly)
            return "transparent"
        if (disabled) {
            return styleTokens
                ? styleTokens.disabledSurfaceColor(role)
                : "#1D202B"
        }
        return styleTokens
            ? styleTokens.surfaceColor(role, surfaceOpacity)
            : Theme.surfaceContainerHigh
    }

    readonly property color resolvedBorderColor: {
        if (disabled)
            return styleTokens ? styleTokens.borderColor(role) : Theme.outlineVariant
        if (focused || selected)
            return styleTokens ? styleTokens.accentColor : Theme.primary
        return styleTokens ? styleTokens.borderColor(role) : Theme.outlineVariant
    }

    Rectangle {
        id: bgShape
        anchors.fill: parent
        radius: surface.radius
        color: surface.resolvedSurfaceColor
        border.width: surface.borderWidth
        border.color: surface.resolvedBorderColor
        antialiasing: true

        Behavior on color {
            ColorAnimation { duration: surface._animDuration; easing.type: surface._animEasing }
        }
        Behavior on border.color {
            ColorAnimation { duration: surface._animDuration; easing.type: surface._animEasing }
        }

        transform: Matrix4x4 {
            matrix: Qt.matrix4x4(
                1, surface._shearX, 0, 0,
                0, 1,               0, 0,
                0, 0,               1, 0,
                0, 0,               0, 1
            )
        }

        Rectangle {
            id: bgMask
            anchors.fill: parent
            radius: surface.radius
            visible: false
            layer.enabled: true
        }

        Item {
            id: backdropContainer
            anchors.fill: parent
            visible: children.length > 0
            layer.enabled: children.length > 0
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: bgMask
            }
        }
    }

    Item {
        id: contentContainer
        anchors.fill: parent
    }
}
