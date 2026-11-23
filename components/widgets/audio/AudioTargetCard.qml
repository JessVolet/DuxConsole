pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Widgets
import "../../primitives/surfaces"

SlantedSurface {
    id: card
    property var itemData: null
    property var i18n: null
    property real density: 1
    signal chosen()
    contained: true
    contentPadding: Theme.spacingS * density
    function tr(key, fallback) { return i18n ? i18n.t(key, fallback) : fallback }
    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: Theme.spacingXS
        StyledText {
            width: parent.width
            text: card.itemData?.title || card.tr("audio.unavailable", "Unavailable")
            color: card.styleTokens ? card.styleTokens.onSurfaceColor("card") : Theme.surfaceText
            font.weight: Font.Bold
            font.pixelSize: Math.max(10, Theme.fontSizeMedium * card.density)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
        StyledText {
            width: parent.width
            text: card.itemData ? (card.itemData.muted ? card.tr("audio.muted", "Muted") : Math.round(card.itemData.volume * 100) + "%")
                + (card.itemData.active ? " · " + card.tr("audio.active", "Active") : "")
                + (card.itemData.pinned ? " · " + card.tr("audio.pinned", "Pinned") : "") : ""
            color: card.styleTokens ? card.styleTokens.onSurfaceColor("card") : Theme.surfaceText
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Math.max(9, Theme.fontSizeSmall * card.density)
            elide: Text.ElideRight
        }
    }
    TapHandler { onTapped: card.chosen() }
}
