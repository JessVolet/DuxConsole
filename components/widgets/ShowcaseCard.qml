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
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -caption.height / 3
        visible: !card.hasImage && card.iconName !== ""
        name: card.iconName
        size: Math.min(42, card.height / 3)
        color: card.styleTokens?.accentColor ?? Theme.primary
    }

    Column {
        id: caption
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingM
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
