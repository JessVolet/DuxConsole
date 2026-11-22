import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/surfaces"
import "../primitives/text"

SlantedSurface {
    id: mediaCard

    property var i18n: null

    role: "card"
    implicitWidth: 320
    implicitHeight: 240

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingM

        SectionTitle {
            styleTokens: mediaCard.styleTokens
            title: mediaCard.i18n ? mediaCard.i18n.t("media.title", "Media Player") : "Media Player"
            subtitle: mediaCard.i18n ? mediaCard.i18n.t("media.idle_subtitle", "MPRIS reserved slot") : "MPRIS reserved slot"
        }

        StyledText {
            width: parent.width
            wrapMode: Text.Wrap
            text: mediaCard.i18n ? mediaCard.i18n.t("media.idle_body", "No active media player") : "No active media player"
            font.pixelSize: Theme.fontSizeSmall
            color: mediaCard.styleTokens
                   ? mediaCard.styleTokens.disabledOnSurfaceColor("card")
                   : (Theme.surfaceVariantText ?? "#9CA3AF")
        }
    }
}
