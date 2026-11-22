import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: section

    property string title: ""
    property string subtitle: ""
    property string role: "card"
    property var styleTokens: null

    spacing: 2

    StyledText {
        text: section.title
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: section.styleTokens
               ? section.styleTokens.onSurfaceColor(section.role)
               : Theme.onSurface
    }

    StyledText {
        visible: section.subtitle !== ""
        text: section.subtitle
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.onSurfaceVariant
    }
}
