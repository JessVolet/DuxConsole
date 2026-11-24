import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: section

    property string title: ""
    property string subtitle: ""
    property string badgeText: ""
    property string role: "card"
    property var styleTokens: null
    property real titleSize: Theme.fontSizeMedium

    spacing: 2

    Row {
        width: section.width
        spacing: Theme.spacingM

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: section.badgeText !== "" ? Math.min(implicitWidth, Math.max(0, section.width - badgeLabel.implicitWidth - Theme.spacingM)) : section.width
            text: section.title
            font.pixelSize: section.titleSize
            font.weight: Font.Bold
            elide: Text.ElideRight
            color: section.styleTokens
                   ? section.styleTokens.onSurfaceColor(section.role)
                   : (Theme.surfaceText ?? "#F2F4F8")
        }

        StyledText {
            id: badgeLabel
            anchors.verticalCenter: parent.verticalCenter
            visible: section.badgeText !== ""
            text: section.badgeText
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.DemiBold
            color: section.styleTokens
                   ? Qt.alpha(section.styleTokens.onSurfaceColor(section.role), 0.7)
                   : (Theme.surfaceVariantText ?? "#9CA3AF")
        }
    }

    StyledText {
        width: section.width
        visible: section.subtitle !== ""
        text: section.subtitle
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeSmall
        color: section.styleTokens?.m3OnSurfaceVariant
               ?? Theme.onSurfaceVariant
               ?? Theme.surfaceVariantText
               ?? "#9CA3AF"
    }
}
