import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets
import "../primitives/surfaces"

SlantedSurface {
    id: digest

    property var achievement: null
    property string recentLabel: ""
    property string progressLabel: ""
    property string unavailableLabel: ""

    role: "chrome"
    implicitWidth: 480
    implicitHeight: 74

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingXL
        spacing: Theme.spacingM

        Column {
            width: Math.max(0, (parent.width - parent.spacing) / 2)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXS

            StyledText {
                width: parent.width
                text: digest.recentLabel
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
                color: digest.styleTokens?.disabledOnSurfaceColor("chrome") ?? Theme.surfaceVariantText
            }

            StyledText {
                width: parent.width
                text: digest.achievement?.title || digest.unavailableLabel
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font.weight: Font.DemiBold
                color: digest.styleTokens?.onSurfaceColor("chrome") ?? Theme.surfaceText
            }
        }

        Column {
            width: Math.max(0, (parent.width - parent.spacing) / 2)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXS

            StyledText {
                width: parent.width
                text: digest.progressLabel
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
                color: digest.styleTokens?.disabledOnSurfaceColor("chrome") ?? Theme.surfaceVariantText
            }

            StyledText {
                width: parent.width
                text: digest.achievement?.nextTitle ?? ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font.weight: Font.DemiBold
                color: digest.styleTokens?.onSurfaceColor("chrome") ?? Theme.surfaceText
            }

            ProgressBar {
                width: parent.width
                from: 0
                to: Math.max(1, digest.achievement?.total ?? 0)
                value: Math.max(0, Math.min(to, digest.achievement?.progress ?? 0))
                Accessible.name: digest.progressLabel
                visible: digest.achievement !== null
            }
        }
    }
}
