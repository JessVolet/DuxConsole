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
    surfaceOpacity: prominent ? 0.82 : 1.0
    implicitHeight: compact ? (prominent ? 128 : 64) : (prominent ? 160 : 88)

    Column {
        anchors.fill: parent
        anchors.margins: infoCard.compact ? Theme.spacingS : Theme.spacingM
        spacing: Theme.spacingS

        StyledText {
            width: parent.width
            text: infoCard.label
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: infoCard.styleTokens
                   ? infoCard.styleTokens.disabledOnSurfaceColor("card")
                   : (Theme.surfaceVariantText ?? "#9CA3AF")
            elide: Text.ElideRight
        }

        StyledText {
            width: parent.width
            text: infoCard.value
            font.pixelSize: infoCard.prominent ? Theme.fontSizeLarge * 1.5 : Theme.fontSizeLarge
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
