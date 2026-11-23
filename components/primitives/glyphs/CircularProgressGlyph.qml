import QtQuick
import qs.Common

Item {
    id: indicator

    property string progressState: "idle"          // "idle" | "charging" | "completed"
    property real progress: 0.0            // 0.0 .. 1.0
    property var styleTokens: null
    property var motionTokens: null
    property var iconsPadManager: null
    property string action: ""
    property url centerIcon: ""
    property real ringSize: 34

    readonly property real clampedProgress: {
        if (progressState === "completed")
            return 1.0
        if (progressState === "idle")
            return 0.0
        return Math.max(0.0, Math.min(1.0, progress))
    }

    property real animatedProgress: clampedProgress
    readonly property int animDuration: motionTokens ? motionTokens.durationFast : 120
    readonly property int animEasing: motionTokens ? motionTokens.easingSnappy : Easing.OutCubic
    readonly property color ringColor: styleTokens ? styleTokens.accentColor : Theme.primary

    Behavior on animatedProgress {
        NumberAnimation {
            duration: indicator.animDuration
            easing.type: indicator.animEasing
        }
    }

    onAnimatedProgressChanged: ringCanvas.requestPaint()
    onProgressStateChanged: ringCanvas.requestPaint()
    onRingColorChanged: ringCanvas.requestPaint()

    implicitWidth: ringSize
    implicitHeight: ringSize

    Canvas {
        id: ringCanvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2
            const cy = height / 2
            const r = Math.min(cx, cy) - 2.5

            // Track base
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.lineWidth = 2.5
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.20)
            ctx.stroke()

            // Arco de progreso
            if (indicator.animatedProgress > 0.005) {
                const start = -Math.PI / 2
                const end = start + Math.PI * 2 * indicator.animatedProgress
                ctx.beginPath()
                ctx.arc(cx, cy, r, start, end)
                ctx.lineWidth = 2.8
                ctx.lineCap = "round"
                ctx.strokeStyle = indicator.ringColor
                ctx.stroke()
            }
        }
    }

    Image {
        anchors.centerIn: parent
        width: 18
        height: 18
        sourceSize.width: 18
        sourceSize.height: 18
        visible: indicator.centerIcon.toString() !== ""
        source: indicator.centerIcon
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    InputGlyph {
        anchors.centerIn: parent
        visible: indicator.centerIcon.toString() === "" && indicator.action !== ""
        iconsPadManager: indicator.iconsPadManager
        styleTokens: indicator.styleTokens
        action: indicator.action
    }
}
