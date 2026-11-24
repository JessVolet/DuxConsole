import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.Common
import qs.Widgets
import "../glyphs"

AbstractButton {
    id: pill

    property var styleTokens: null
    property var iconsPadManager: null
    property string glyphAction: ""
    property url iconSource: ""
    property real iconSize: 18
    property bool highlighted: false
    property bool primary: false
    readonly property string role: primary ? "chrome" : "card"
    readonly property color containerColor: styleTokens
        ? (primary ? styleTokens.m3Primary : styleTokens.m3SurfaceContainer)
        : (primary ? Theme.primary : Theme.surfaceContainer)
    readonly property color onContainerColor: styleTokens
        ? (primary ? styleTokens.m3OnPrimary : styleTokens.m3OnSurface)
        : (primary ? Theme.onPrimary : Theme.onSurface)

    implicitHeight: Math.max(36, labels.implicitHeight + Theme.spacingS * 2)
    implicitWidth: labels.implicitWidth + Theme.spacingM * 2
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    Accessible.ignored: !enabled || !visible
    Accessible.focused: highlighted && !Accessible.ignored

    background: Rectangle {
        radius: height / 2
        color: pill.containerColor
        border.color: pill.styleTokens?.m3Primary ?? Theme.primary
        border.width: pill.highlighted ? 2 : 0
    }

    contentItem: Item {
        implicitWidth: labels.implicitWidth
        implicitHeight: labels.implicitHeight

        Row {
            id: labels
            anchors.centerIn: parent
            spacing: Theme.spacingS

            InputGlyph {
                visible: pill.glyphAction !== "" && pill.iconsPadManager !== null
                iconsPadManager: pill.iconsPadManager
                styleTokens: pill.styleTokens
                action: pill.glyphAction
            }

            Image {
                visible: pill.iconSource.toString() !== ""
                anchors.verticalCenter: labels.verticalCenter
                width: pill.iconSize
                height: pill.iconSize
                source: pill.iconSource
                sourceSize: Qt.size(pill.iconSize * 2, pill.iconSize * 2)
                fillMode: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: pill.onContainerColor
                }
            }

            StyledText {
                visible: pill.text !== ""
                anchors.verticalCenter: labels.verticalCenter
                text: pill.text
                font.pixelSize: Theme.fontSizeMedium
                color: pill.onContainerColor
            }
        }
    }
}
