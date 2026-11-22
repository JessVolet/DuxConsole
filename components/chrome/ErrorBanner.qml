import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: banner

    property var i18n: null
    property string errorMessage: ""
    property string sourcePath: ""

    visible: errorMessage !== ""
    anchors.fill: parent
    z: 999
    color: Qt.rgba(0.06, 0.03, 0.04, 0.92)

    StyledRect {
        anchors.centerIn: parent
        width: Math.min(760, banner.width - Theme.spacingXL * 2)
        height: col.implicitHeight + Theme.spacingXL * 2
        radius: Theme.cornerRadius
        color: "#1B1114"
        border.width: 2
        border.color: "#EF4444"

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingXL
            spacing: Theme.spacingM

            StyledText {
                text: banner.i18n ? banner.i18n.t("error.title", "") : ""
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                color: "#FCA5A5"
            }

            StyledText {
                visible: banner.sourcePath !== ""
                width: col.width
                wrapMode: Text.WrapAnywhere
                text: banner.sourcePath
                font.pixelSize: Theme.fontSizeSmall
                color: "#FDE68A"
            }

            StyledText {
                width: col.width
                wrapMode: Text.Wrap
                text: banner.errorMessage
                font.pixelSize: Theme.fontSizeMedium
                color: "#F8FAFC"
            }

            StyledText {
                text: banner.i18n ? banner.i18n.t("error.close_hint", "") : ""
                font.pixelSize: Theme.fontSizeSmall
                color: "#94A3B8"
            }
        }
    }
}
