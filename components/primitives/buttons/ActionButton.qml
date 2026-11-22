import QtQuick
import qs.Common
import qs.Widgets
import "../glyphs"
import "../surfaces"

SlantedSurface {
    id: button

    property string label: ""
    property string action: ""
    property var iconsPadManager: null

    role: "chrome"
    implicitWidth: Math.max(220, contentRow.implicitWidth + Theme.spacingXL * 2)
    implicitHeight: 52
    radius: Theme.cornerRadius

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: Theme.spacingM

        InputGlyph {
            anchors.verticalCenter: parent.verticalCenter
            visible: button.action !== ""
            iconsPadManager: button.iconsPadManager
            styleTokens: button.styleTokens
            action: button.action
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: button.label
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
            color: button.styleTokens
                   ? button.styleTokens.onSurfaceColor(button.role)
                   : Theme.onSurface
        }
    }
}
