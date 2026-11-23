import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets
import "../glyphs"

AbstractButton {
    id: pill

    property var styleTokens: null
    property var iconsPadManager: null
    property string glyphAction: ""
    property bool highlighted: false
    property bool primary: false
    readonly property string role: primary ? "chrome" : "card"

    implicitHeight: Math.max(36, labels.implicitHeight + Theme.spacingS * 2)
    implicitWidth: labels.implicitWidth + Theme.spacingM * 2
    hoverEnabled: true
    focusPolicy: Qt.NoFocus

    background: Rectangle {
        radius: height / 2
        color: pill.styleTokens?.surfaceColor(pill.role) ?? Theme.surfaceContainerHigh
        border.color: pill.styleTokens?.accentColor ?? Theme.primary
        border.width: pill.highlighted || pill.hovered ? 2 : 0
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

            StyledText {
                anchors.verticalCenter: labels.verticalCenter
                text: pill.text
                font.pixelSize: Theme.fontSizeMedium
                color: pill.styleTokens?.onSurfaceColor(pill.role) ?? Theme.surfaceText
            }
        }
    }
}
