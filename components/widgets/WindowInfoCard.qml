import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/surfaces"

SlantedSurface {
    id: infoCard

    property string label: ""
    property string value: ""
    property bool prominent: false
    property bool compact: false

    role: "card"
    implicitHeight: compact ? (prominent ? 72 : 56) : (prominent ? 112 : 80)

    Column {
        anchors.fill: parent
        anchors.margins: infoCard.compact ? Theme.spacingXS : Theme.spacingM
        spacing: Theme.spacingXS

        StyledText {
            width: parent.width
            text: infoCard.label
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: infoCard.styleTokens
                   ? infoCard.styleTokens.disabledOnSurfaceColor("card")
                   : (Theme.surfaceVariantText ?? "#9CA3AF")
            elide: Text.ElideRight
        }

        StyledText {
            width: parent.width
            text: infoCard.value
            font.pixelSize: infoCard.prominent ? Theme.fontSizeLarge : Theme.fontSizeMedium
            font.weight: infoCard.prominent ? Font.Bold : Font.Medium
            color: infoCard.styleTokens
                   ? infoCard.styleTokens.onSurfaceColor("card")
                   : (Theme.surfaceText ?? "#F2F4F8")
            elide: Text.ElideRight
            maximumLineCount: infoCard.prominent ? 2 : 1
            wrapMode: infoCard.prominent ? Text.Wrap : Text.NoWrap
        }
    }
}
