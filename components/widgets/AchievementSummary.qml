import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/text"

Column {
    id: summary

    property string title: ""
    property string subtitle: ""
    property string progressLabel: ""
    property real progress: 0
    property var styleTokens: null

    Accessible.role: Accessible.ProgressBar
    Accessible.name: progressLabel

    spacing: Theme.spacingS

    DisplayTitle {
        width: summary.width
        text: summary.title
        styleTokens: summary.styleTokens
        font.pixelSize: Math.round(Math.max(Theme.fontSizeXXLarge, Math.min(100, summary.width * 0.2)))
        elide: Text.ElideRight
    }

    StyledText {
        text: summary.subtitle
        color: summary.styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText
        opacity: 0.8
    }

    Row {
        width: summary.width
        spacing: Theme.spacingM

        StyledText {
            id: progressText
            anchors.verticalCenter: parent.verticalCenter
            text: summary.progressLabel
            font.weight: Font.DemiBold
            color: summary.styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, Math.min(185, summary.width - progressText.width - Theme.spacingM))
            height: 3
            radius: height / 2
            color: summary.styleTokens?.borderColor("card") ?? Theme.outlineVariant

            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, summary.progress))
                height: parent.height
                radius: height / 2
                color: summary.styleTokens?.accentColor ?? Theme.primary
            }
        }
    }
}
