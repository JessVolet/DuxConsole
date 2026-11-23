import QtQuick
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets as DCommon
import "../primitives/surfaces"

SlantedImage {
    id: card

    property var itemData: null
    property string title: ""
    property string subtitle: ""
    property string iconName: ""
    property bool interactive: true
    property bool badgeLayout: false
    signal picked(var itemId)

    Accessible.role: Accessible.Button
    Accessible.name: title
    Accessible.description: subtitle
    Accessible.ignored: !interactive
    Accessible.onPressAction: {
        if (interactive)
            picked(itemData?.id)
    }

    DCommon.DIcon {
        id: badge
        x: card.badgeLayout ? Theme.spacingL : (parent.width - width) / 2
        y: card.badgeLayout ? Theme.spacingM : (parent.height - height) / 2 - caption.height / 3
        visible: !card.hasImage && card.iconName !== ""
        name: card.iconName
        size: card.badgeLayout ? Math.min(28, card.height / 4) : Math.min(42, card.height / 3)
        color: card.styleTokens?.accentColor ?? Theme.primary
    }

    Column {
        id: caption
        anchors.left: parent.left
        anchors.right: parent.right
        y: card.badgeLayout ? badge.y + badge.height + Theme.spacingS : parent.height - height - Theme.spacingM
        anchors.margins: Theme.spacingL
        spacing: Theme.spacingXS

        StyledText {
            width: caption.width
            text: card.title
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Bold
            color: card.styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText
            elide: Text.ElideRight
        }

        StyledText {
            width: caption.width
            text: card.subtitle
            font.pixelSize: Theme.fontSizeSmall
            color: card.styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText
            opacity: 0.78
            elide: Text.ElideRight
        }
    }

}
