pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Widgets
import qs.Services
import "../primitives/surfaces"
import "../primitives/surfaces/SlantedGeometry.js" as SlantedGeometry

// Excepción localizada al contrato recto de SlantedSurface:
// aplica una inclinación sutil configurable únicamente al contenido visual
// de letras (sin controles ni geometría de foco) dentro de una máscara inclinada real,
// consumiendo directamente LyricsService.controller nativo de DMS sin caja opaca interna.
Item {
    id: panel

    property var styleTokens: null
    property var motionTokens: null
    property bool lyricsActive: false
    property real skewAngle: styleTokens ? styleTokens.skewAngle : -8
    property real contentSkewAngle: skewAngle * 0.45
    property real radius: 18

    readonly property var lyricsCtrl: LyricsService.controller
    readonly property bool isSynced: Boolean(lyricsCtrl?.synced)
    readonly property var lineModel: isSynced
        ? (lyricsCtrl?.lines ?? [])
        : (lyricsCtrl?.plainLines ?? [])
    readonly property int activeLineIndex: isSynced ? (lyricsCtrl?.activeIndex ?? -1) : -1
    readonly property color fgColor: styleTokens
        ? styleTokens.onSurfaceColor("card")
        : (Theme.surfaceText ?? "#F2F4F8")
    readonly property color accentColor: styleTokens ? styleTokens.accentColor : Theme.primary
    readonly property bool supportsLayerMask: GraphicsInfo.api !== GraphicsInfo.Software
    readonly property real _skewPad: Math.min(width * 0.2, SlantedGeometry.horizontalShearOffset(height, skewAngle))
    readonly property real _innerX: skewAngle < 0 ? _skewPad : 0
    readonly property real _innerWidth: Math.max(1, width - _skewPad)
    readonly property real _contentShearX: Math.tan(contentSkewAngle * Math.PI / 180)
    readonly property int animFast: motionTokens ? motionTokens.durationFast : 120
    readonly property int animNormal: motionTokens ? motionTokens.durationNormal : 220

    SlantedSurface {
        x: panel._innerX
        y: 0
        width: panel._innerWidth
        height: panel.height
        styleTokens: panel.styleTokens
        motionTokens: panel.motionTokens
        role: "card"
        surfaceOpacity: 0.55
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
            x: panel._innerX + Theme.spacingL
            y: Theme.spacingL
            width: Math.max(1, panel._innerWidth - Theme.spacingL * 2)
            height: Math.max(1, panel.height - Theme.spacingL * 2)

            transform: Matrix4x4 {
                matrix: Qt.matrix4x4(
                    1, panel._contentShearX, 0, 0,
                    0, 1,                    0, 0,
                    0, 0,                    1, 0,
                    0, 0,                    0, 1
                )
            }

            ListView {
                id: lyricsList
                anchors.fill: parent
                clip: true
                interactive: false
                spacing: Theme.spacingM
                visible: panel.lyricsActive
                model: panel.lineModel
                currentIndex: panel.activeLineIndex
                preferredHighlightBegin: height * 0.36
                preferredHighlightEnd: height * 0.54
                highlightRangeMode: ListView.StrictlyEnforceRange
                highlightMoveDuration: panel.animNormal

                delegate: StyledText {
                    required property int index
                    required property var modelData

                    readonly property bool isCurrent: panel.isSynced && index === lyricsList.currentIndex
                    readonly property string lineText: panel.isSynced
                        ? String(modelData?.x ?? "")
                        : String(modelData ?? "")

                    width: lyricsList.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: lineText
                    font.pixelSize: isCurrent ? Theme.fontSizeXLarge : Theme.fontSizeLarge
                    font.weight: isCurrent ? Font.Bold : Font.Medium
                    color: isCurrent ? panel.fgColor : Qt.alpha(panel.fgColor, panel.isSynced ? 0.42 : 0.82)

                    Behavior on color {
                        ColorAnimation { duration: panel.animFast }
                    }
                }
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
