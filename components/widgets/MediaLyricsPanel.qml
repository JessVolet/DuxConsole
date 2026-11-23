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
SlantedSurface {
    id: panel

    property bool lyricsActive: false
    property real contentSkewAngle: skewAngle * 0.35

    readonly property bool supportsLayerMask: GraphicsInfo.api !== GraphicsInfo.Software
    readonly property real contentShearX: Math.tan(contentSkewAngle * Math.PI / 180)
    readonly property real safeInset: SlantedGeometry.safeHorizontalInset(height, skewAngle, radius, Theme.spacingM)

    role: "card"
    radius: 18
    borderWidth: 1

    Item {
        id: maskWrapper
        anchors.fill: parent
        visible: false
        layer.enabled: panel.supportsLayerMask

        SlantedSurface {
            anchors.fill: parent
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
            anchors.fill: parent
            anchors.leftMargin: panel.safeInset
            anchors.rightMargin: panel.safeInset
            anchors.topMargin: Theme.spacingM
            anchors.bottomMargin: Theme.spacingM

            transform: Matrix4x4 {
                matrix: Qt.matrix4x4(
                    1, panel.contentShearX, 0, 0,
                    0, 1,                   0, 0,
                    0, 0,                   1, 0,
                    0, 0,                   0, 1
                )
            }

            LyricsOverlay {
                anchors.fill: parent
                visible: panel.lyricsActive
            }
        }
    }
}
