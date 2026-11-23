pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import "../surfaces"
import "../surfaces/SlantedGeometry.js" as SlantedGeometry

Item {
    id: bar

    property var styleTokens: null
    property var motionTokens: null
    property real position: 0
    property real length: 0
    property real progress: 0
    property bool canSeek: false
    property bool hasPlayer: false
    property real skewAngle: styleTokens ? styleTokens.skewAngle : -8
    property real trackHeight: 10

    signal seekRequested(real ratio)

    readonly property real clampedProgress: hasPlayer ? Math.max(0, Math.min(1, progress)) : 0
    readonly property color accentColor: styleTokens ? styleTokens.accentColor : Theme.primary
    readonly property color fgColor: styleTokens
        ? styleTokens.onSurfaceColor("card")
        : (Theme.surfaceText ?? "#F2F4F8")
    readonly property color mutedFg: styleTokens && !hasPlayer
        ? styleTokens.disabledOnSurfaceColor("card")
        : Qt.alpha(fgColor, canSeek ? 0.78 : 0.56)
    readonly property color trackColor: hasPlayer
        ? Qt.alpha(fgColor, 0.16)
        : (styleTokens ? styleTokens.disabledSurfaceColor("card") : Qt.rgba(1, 1, 1, 0.08))
    readonly property color fillColor: hasPlayer
        ? (canSeek ? accentColor : Qt.alpha(accentColor, 0.65))
        : (styleTokens ? styleTokens.disabledOnSurfaceColor("card") : "#64748B")
    readonly property real _shearPad: Math.min(width * 0.08, SlantedGeometry.horizontalShearOffset(trackHeight, skewAngle))
    readonly property int animDuration: motionTokens ? motionTokens.durationFast : 120
    readonly property int animEasing: motionTokens ? motionTokens.easingSnappy : Easing.OutCubic

    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(seconds || 0))
        const mins = Math.floor(total / 60)
        const secs = total % 60
        return mins + ":" + (secs < 10 ? "0" + secs : String(secs))
    }

    implicitWidth: 320
    implicitHeight: trackContainer.height + 6 + timestampsRow.implicitHeight

    Item {
        id: trackContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Math.max(16, bar.trackHeight + 6)

        SlantedSurface {
            id: trackSurface
            anchors.verticalCenter: parent.verticalCenter
            x: bar.skewAngle < 0 ? bar._shearPad : 0
            width: Math.max(16, parent.width - bar._shearPad)
            height: bar.trackHeight
            radius: height / 2
            skewAngle: bar.skewAngle
            role: "card"
            borderWidth: 0
            styleTokens: bar.styleTokens
            motionTokens: bar.motionTokens
            disabled: !bar.hasPlayer

            backdrop: [
                Rectangle {
                    anchors.fill: parent
                    color: bar.trackColor
                },
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.round(parent.width * bar.clampedProgress)
                    radius: parent.height / 2
                    color: bar.fillColor

                    Behavior on width {
                        NumberAnimation {
                            duration: bar.animDuration
                            easing.type: bar.animEasing
                        }
                    }
                }
            ]
        }

        // Indicador de posición alineado sobre la pista inclinada
        Rectangle {
            id: thumb
            visible: bar.hasPlayer
            width: bar.trackHeight + 4
            height: bar.trackHeight + 4
            radius: height / 2
            anchors.verticalCenter: trackSurface.verticalCenter
            x: Math.max(
                trackSurface.x,
                Math.min(
                    trackSurface.x + trackSurface.width - width,
                    trackSurface.x + trackSurface.width * bar.clampedProgress - width / 2
                )
            )
            color: bar.canSeek ? "#FFFFFF" : Qt.alpha("#FFFFFF", 0.7)
            border.width: 2
            border.color: bar.fillColor

            Behavior on x {
                NumberAnimation {
                    duration: bar.animDuration
                    easing.type: bar.animEasing
                }
            }
        }

        TapHandler {
            enabled: bar.hasPlayer && bar.canSeek
            onTapped: eventPoint => {
                const ratio = Math.max(0, Math.min(1, (eventPoint.position.x - trackSurface.x) / Math.max(1, trackSurface.width)))
                bar.seekRequested(ratio)
            }
        }
    }

    Item {
        id: timestampsRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: trackContainer.bottom
        anchors.topMargin: 4
        implicitHeight: posText.implicitHeight
        height: implicitHeight

        StyledText {
            id: posText
            anchors.left: parent.left
            text: bar.formatTime(bar.position)
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: bar.mutedFg
        }

        StyledText {
            anchors.right: parent.right
            text: bar.formatTime(bar.length)
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: bar.mutedFg
        }
    }
}
