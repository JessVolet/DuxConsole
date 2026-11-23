pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/buttons"
import "../primitives/surfaces"

SlantedSurface {
    id: row
    property string title: ""
    property string subtitle: ""
    property string pinLabel: ""
    property bool automatic: false
    property bool pinned: false
    property var iconsPadManager: null
    signal chosen()
    signal pinRequested()
    contained: true
    skewAngle: 0
    contentPadding: Theme.spacingM
    implicitHeight: 80

    Item {
        anchors.fill: parent
        Column {
            anchors.left: parent.left
            anchors.right: row.automatic ? parent.right : pinButton.left
            anchors.rightMargin: Theme.spacingS
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXS
            StyledText {
                width: parent.width
                text: row.title
                color: row.styleTokens ? row.styleTokens.onSurfaceColor("card") : Theme.surfaceText
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            StyledText {
                width: parent.width
                text: row.subtitle
                color: row.styleTokens ? row.styleTokens.onSurfaceColor("card") : Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
            }
        }
        MouseArea {
            anchors.fill: parent
            anchors.rightMargin: row.automatic ? 0 : pinButton.width + Theme.spacingS
            cursorShape: Qt.PointingHandCursor
            onClicked: row.chosen()
        }
        ActionPill {
            id: pinButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !row.automatic
            text: row.pinLabel
            primary: row.pinned
            glyphAction: "I.Action"
            iconsPadManager: row.iconsPadManager
            styleTokens: row.styleTokens
            onClicked: row.pinRequested()
        }
    }
}
