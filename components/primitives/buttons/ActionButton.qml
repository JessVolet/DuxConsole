import QtQuick
import qs.Common
import qs.Widgets
import "../glyphs"

StyledRect {
    id: button

    property string label: ""
    property bool focused: false
    property string action: ""
    property var iconsPadManager: null
    property var styleTokens: null

    implicitWidth: Math.max(220, contentRow.implicitWidth + Theme.spacingXL * 2)
    implicitHeight: 56
    radius: Theme.cornerRadius
    color: focused ? Theme.primaryContainer : Theme.surfaceContainerHigh

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
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.DemiBold
            color: button.focused ? Theme.onPrimaryContainer : Theme.onSurface
        }
    }
}
