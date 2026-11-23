import QtQuick
import QtQuick.Shapes
import qs.Common
import qs.Widgets

Item {
    id: meter

    property string label: ""
    property string unit: ""
    property real minimum: 0
    property real maximum: 100
    property real value: 0
    property bool radial: false
    property var styleTokens: null
    property var motionTokens: null
    readonly property color accent: styleTokens ? styleTokens.accentColor : Theme.primary
    readonly property color surface: styleTokens ? styleTokens.surfaceColor("card") : Theme.surfaceContainerHigh
    readonly property color foreground: styleTokens ? styleTokens.onSurfaceColor("card") : Theme.surfaceText
    readonly property real fraction: maximum > minimum ? Math.max(0, Math.min(1, (value - minimum) / (maximum - minimum))) : 0
    readonly property real diameter: Math.min(width, height)
    property real shownFraction: fraction

    implicitWidth: radial ? 220 : 160
    implicitHeight: radial ? 220 : Theme.spacingS
    Accessible.role: Accessible.ProgressBar
    Accessible.ignored: !visible || !enabled
    Accessible.name: label
    Accessible.description: Math.round(value) + unit

    Behavior on shownFraction {
        NumberAnimation {
            duration: meter.motionTokens?.durationNormal ?? 0
            easing.type: meter.motionTokens?.easingSnappy ?? Easing.Linear
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: meter.diameter
        height: width
        radius: width / 2
        color: meter.surface
        visible: meter.radial
    }

    Shape {
        anchors.fill: parent
        visible: meter.radial
        antialiasing: true

        ShapePath {
            strokeColor: Theme.withAlpha(meter.accent, 0.27)
            strokeWidth: Theme.spacingM
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: meter.width / 2
                centerY: meter.height / 2
                radiusX: Math.max(1, (meter.diameter - Theme.spacingM) / 2)
                radiusY: radiusX
                startAngle: 135
                sweepAngle: 270
            }
        }

        ShapePath {
            strokeColor: meter.accent
            strokeWidth: Theme.spacingM
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: meter.width / 2
                centerY: meter.height / 2
                radiusX: Math.max(1, (meter.diameter - Theme.spacingM) / 2)
                radiusY: radiusX
                startAngle: 135
                sweepAngle: 270 * meter.shownFraction
            }
        }
    }

    Column {
        anchors.centerIn: parent
        width: meter.diameter * 0.68
        spacing: Theme.spacingXS
        visible: meter.radial

        StyledText {
            width: parent.width
            text: meter.label
            horizontalAlignment: Text.AlignHCenter
            color: meter.foreground
            elide: Text.ElideRight
        }

        StyledText {
            width: parent.width
            text: Math.round(meter.value) + meter.unit
            horizontalAlignment: Text.AlignHCenter
            color: meter.foreground
            font.pixelSize: Math.max(Theme.fontSizeLarge, meter.diameter * 0.24)
            font.weight: Font.Bold
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.withAlpha(meter.accent, 0.27)
        visible: !meter.radial

        Rectangle {
            width: parent.width * meter.shownFraction
            height: parent.height
            radius: parent.radius
            color: meter.accent
        }
    }
}
