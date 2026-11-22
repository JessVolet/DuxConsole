import QtQuick
import qs.Common
import qs.Widgets

StyledText {
    id: displayTitle

    property var styleTokens: null
    property string role: "card"

    font.pixelSize: Theme.fontSizeXXLarge
    font.weight: Font.Bold
    color: styleTokens
           ? styleTokens.onSurfaceColor(role)
           : (Theme.surfaceText ?? "#F2F4F8")
}
