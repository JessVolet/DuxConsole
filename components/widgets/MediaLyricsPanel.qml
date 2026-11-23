pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Modules.DDash.Media
import "../primitives/surfaces"
import "../primitives/surfaces/SlantedGeometry.js" as SlantedGeometry

// Excepción localizada al contrato recto de SlantedSurface:
// aplica una inclinación sutil configurable únicamente al contenido visual
// de letras (sin controles ni geometría de foco) dentro de una máscara inclinada real.
Item {
    id: panel

    property var styleTokens: null
    property var motionTokens: null
    property bool lyricsActive: false
    property real skewAngle: styleTokens ? styleTokens.skewAngle : -8
    property real contentSkewAngle: skewAngle * 0.45
    property real radius: 18

    readonly property bool supportsLayerMask: GraphicsInfo.api !== GraphicsInfo.Software
    readonly property real _skewPad: Math.min(width * 0.2, SlantedGeometry.horizontalShearOffset(height, skewAngle))
    readonly property real _innerX: skewAngle < 0 ? _skewPad : 0
    readonly property real _innerWidth: Math.max(1, width - _skewPad)
    readonly property real _contentShearX: Math.tan(contentSkewAngle * Math.PI / 180)

    SlantedSurface {
        x: panel._innerX
        y: 0
        width: panel._innerWidth
        height: panel.height
        styleTokens: panel.styleTokens
        motionTokens: panel.motionTokens
        role: "card"
        surfaceOpacity: 0.65
        skewAngle: panel.skewAngle
        radius: panel.radius
        borderWidth: 1
    }

    Item {
        id: maskWrapper
        anchors.fill: parent
        visible: false
        layer.enabled: panel.supportsLayerMask

        SlantedSurface {
            x: panel._innerX
            y: 0
            width: panel._innerWidth
            height: panel.height
            skewAngle: panel.skewAngle
            radius: panel.radius
        }
    }

    Item {
        anchors.fill: parent
        clip: !panel.supportsLayerMask
        layer.enabled: panel.supportsLayerMask
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskWrapper
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.2
        }

        Item {
            id: skewedLyricsViewport
            x: panel._innerX + Theme.spacingM
            y: Theme.spacingM
            width: Math.max(1, panel._innerWidth - Theme.spacingM * 2)
            height: Math.max(1, panel.height - Theme.spacingM * 2)

            transform: Matrix4x4 {
                matrix: Qt.matrix4x4(
                    1, panel._contentShearX, 0, 0,
                    0, 1,                    0, 0,
                    0, 0,                    1, 0,
                    0, 0,                    0, 1
                )
            }

            LyricsOverlay {
                anchors.fill: parent
                visible: panel.lyricsActive
            }
        }
    }

    SlantedSurface {
        x: panel._innerX
        y: 0
        width: panel._innerWidth
        height: panel.height
        styleTokens: panel.styleTokens
        motionTokens: panel.motionTokens
        role: "card"
        borderOnly: true
        skewAngle: panel.skewAngle
        radius: panel.radius
        borderWidth: 1
    }
}
