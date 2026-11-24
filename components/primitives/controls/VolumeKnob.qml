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
    property string caption: ""
    property string mutedText: ""
    property var styleTokens: null
    signal valueRequested(real value)
    signal muteToggleRequested()
    readonly property real fraction: maximum > minimum ? Math.max(0, Math.min(1, (value - minimum) / (maximum - minimum))) : 0
    readonly property color accent: styleTokens ? styleTokens.m3Primary : Theme.primary
    readonly property color track: styleTokens ? styleTokens.m3SurfaceHighest : Theme.surfaceContainerHighest
    readonly property color foreground: styleTokens ? styleTokens.m3OnSurface : Theme.onSurface
    readonly property color variant: styleTokens ? styleTokens.m3OnSurfaceVariant : Theme.onSurfaceVariant
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
        background: Item {
            readonly property real radius: dial.width / 2 - knob.strokeWidth
            Shape {
                anchors.fill: parent
                ShapePath {
                    strokeColor: knob.track
                    strokeWidth: knob.strokeWidth
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: dial.width / 2; centerY: dial.height / 2
                        radiusX: dial.width / 2 - knob.strokeWidth; radiusY: radiusX
                        startAngle: 135; sweepAngle: 270
                    }
                }
                ShapePath {
                    strokeColor: knob.muted ? Qt.alpha(knob.accent, 0.4) : knob.accent
                    strokeWidth: knob.strokeWidth
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: dial.width / 2; centerY: dial.height / 2
                        radiusX: dial.width / 2 - knob.strokeWidth; radiusY: radiusX
                        startAngle: 135; sweepAngle: 270 * knob.fraction
                    }
                }
            }
            Column {
                anchors.centerIn: parent
                spacing: 2
                width: parent.width * 0.66
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    visible: knob.caption !== ""
                    text: knob.caption
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    color: knob.variant
                    font.pixelSize: Theme.fontSizeSmall
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: knob.muted && knob.mutedText ? knob.mutedText : Math.round(knob.value * 100) + "%"
                    color: knob.foreground
                    font.pixelSize: Math.round(dial.width * 0.15)
                    font.bold: true
                }
            }
        }
        handle: Item {}
    }
}
