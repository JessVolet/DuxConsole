import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: section

    property string title: ""
    property string subtitle: ""
    property string role: "card"
    property var styleTokens: null
    property real titleSize: Theme.fontSizeMedium

    spacing: 2

    StyledText {
        width: section.width
        text: section.title
        font.pixelSize: section.titleSize
        font.weight: Font.Bold
        elide: Text.ElideRight
        color: section.styleTokens
               ? section.styleTokens.onSurfaceColor(section.role)
               : (Theme.surfaceText ?? "#F2F4F8")
    }

    StyledText {
        width: section.width
        visible: section.subtitle !== ""
        text: section.subtitle
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText ?? "#9CA3AF"
    }
}
