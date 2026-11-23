pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/surfaces"
import "../primitives/text"

Item {
    id: strip

    property var devices: []
    property string selectedId: ""
    property int currentIndex: 0
    property string title: ""
    property bool focused: false
    property bool interactive: true
    property var i18n: null
    property var styleTokens: null
    property var motionTokens: null
    signal deviceRequested(int index)

    readonly property color foreground: styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText

    function tr(key, fallback) {
        return i18n?.t(key, fallback) ?? fallback
    }

    QueueCarousel {
        id: carousel

        anchors.fill: parent
        anchors.bottomMargin: Theme.spacingXL
        visibleBudget: 3
        leadingCount: 1
        cardWidth: width * 0.25
        cardHeight: Math.max(0, strip.height - Theme.spacingXL) * 0.65
        selectedWidth: width * 0.53
        selectedHeight: Math.max(0, strip.height - Theme.spacingXL) * 0.9
        spacing: Theme.spacingM
        entries: strip.devices
        selectedId: strip.devices[strip.currentIndex]?.id
        interactive: strip.interactive
        onCardClicked: itemId => strip.deviceRequested(strip.devices.findIndex(device => device.id === itemId))
        focused: strip.focused
        motionTokens: strip.motionTokens

        cardDelegate: SlantedSurface {
            id: card

            property var itemData: null

            role: selected ? "selectedCard" : "card"
            styleTokens: strip.styleTokens
            motionTokens: strip.motionTokens
            surfaceOpacity: selected ? 1 : 0.8

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingXS

                StyledText {
                    width: parent.width
                    text: card.itemData?.name ?? ""
                    color: strip.foreground
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                StyledText {
                    visible: card.selected
                    text: card.itemData?.id === strip.selectedId ? strip.tr("mockup.audio.active", "Active") : ""
                    color: Theme.withAlpha(strip.foreground, 0.72)
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

        }
    }

    StatusMessage {
        anchors.centerIn: carousel
        visible: strip.devices.length === 0
        styleTokens: strip.styleTokens
        text: strip.tr("mockup.audio.noDevices", "No devices")
    }

    StyledText {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        text: strip.title
        color: strip.foreground
        font.weight: Font.Bold
    }
}
