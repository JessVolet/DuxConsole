pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import qs.Common

Item {
    id: knob
    property real value: 0
    property real minimum: 0
    property real maximum: 1
    property bool muted: false
    property string targetKey: ""
    property string label: ""
    property string mutedText: ""
    property var styleTokens: null
    signal valueRequested(real value)
    signal muteToggleRequested()
    readonly property real fraction: maximum > minimum ? Math.max(0, Math.min(1, (value - minimum) / (maximum - minimum))) : 0
    readonly property color accent: styleTokens ? styleTokens.accentColor : Theme.primary
    readonly property color foreground: styleTokens ? styleTokens.onSurfaceColor("card") : Theme.surfaceText
    readonly property real strokeWidth: styleTokens?.knobStrokeWidth ?? 8
    implicitWidth: 180
    implicitHeight: 180
    function mute() { if (enabled && targetKey !== "") muteToggleRequested() }

    Dial {
        id: dial
        anchors.centerIn: parent
        width: Math.min(knob.width, knob.height)
        height: width
        from: knob.minimum
        to: knob.maximum
        Binding { target: dial; property: "value"; value: knob.value; when: !dial.pressed }
        focusPolicy: Qt.NoFocus
        wrap: false
        onMoved: knob.valueRequested(value)
        Accessible.name: knob.label
        Accessible.description: (knob.muted ? knob.mutedText + " " : "") + Math.round(knob.value * 100) + "%"
        background: Rectangle {
            radius: width / 2
            color: knob.styleTokens ? knob.styleTokens.surfaceColor("card") : Theme.surfaceContainerHigh
            Shape {
                anchors.fill: parent
                ShapePath {
                    strokeColor: Qt.alpha(knob.foreground, 0.2)
                    strokeWidth: knob.strokeWidth
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: dial.width / 2; centerY: dial.height / 2; radiusX: dial.width / 2 - 8; radiusY: radiusX; startAngle: 135; sweepAngle: 270 }
                }
                ShapePath {
                    strokeColor: knob.muted ? Qt.alpha(knob.accent, 0.35) : knob.accent
                    strokeWidth: knob.strokeWidth
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: dial.width / 2; centerY: dial.height / 2; radiusX: dial.width / 2 - 8; radiusY: radiusX; startAngle: 135; sweepAngle: 270 * knob.fraction }
                }
            }
            Item {
                anchors.fill: parent
                rotation: -135 + 270 * knob.fraction
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 18; width: 4; height: parent.height * 0.18; radius: 2; color: knob.foreground }
            }
            Text { anchors.centerIn: parent; text: knob.muted && knob.mutedText ? knob.mutedText : Math.round(knob.value * 100) + "%"; color: knob.foreground; font.pixelSize: Theme.fontSizeLarge; font.bold: true }
        }
        handle: Item {}
    }
}
