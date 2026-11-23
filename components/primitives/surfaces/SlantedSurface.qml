pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import qs.Common
import "SlantedGeometry.js" as SlantedGeometry

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
    property bool contained: false
    property real contentPadding: 0
    property int borderWidth: !disabled && focused
        ? focusedBorderWidth
        : (!disabled && selected ? selectedBorderWidth : 1)
    property alias backdrop: backdropContainer.data
    default property alias content: contentContainer.data

    readonly property real _requestedShear: Math.tan(skewAngle * Math.PI / 180)
    readonly property real _shearX: contained && height > 0
        ? Math.max(-width / (2 * height), Math.min(width / (2 * height), _requestedShear))
        : _requestedShear
    readonly property real shapeInset: contained ? Math.abs(_shearX) * height : 0
    readonly property real safeHorizontalInset: SlantedGeometry.safeHorizontalInset(height, skewAngle, radius, 0)
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
        x: surface.contained && surface._shearX < 0 ? surface.shapeInset : 0
        width: Math.max(0, surface.width - surface.shapeInset)
        height: surface.height
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
            layer.enabled: backdropContainer.children.length > 0
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
        x: surface.shapeInset + surface.contentPadding
        y: surface.contentPadding
        width: Math.max(0, surface.width - 2 * (surface.shapeInset + surface.contentPadding))
        height: Math.max(0, surface.height - 2 * surface.contentPadding)
    }
}
