pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/surfaces"
import "../primitives/text"

Item {
    id: gallery

    property var entries: []
    property int currentIndex: 0
    property bool focused: false
    property bool interactive: true
    property var styleTokens: null
    property var motionTokens: null
    property var i18n: null

    signal entryRequested(int index)

    readonly property color foreground: styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText

    function tr(key, fallback) {
        return i18n?.t(key, fallback) ?? fallback
    }

    SectionTitle {
        id: heading

        width: parent.width
        title: gallery.tr("mockup.capture.gallery", "Screenshots and recordings")
        styleTokens: gallery.styleTokens
    }

    QueueCarousel {
        id: carousel

        anchors.top: heading.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        selectedId: gallery.entries[gallery.currentIndex]?.id
        entries: gallery.entries
        interactive: gallery.interactive
        onCardClicked: itemId => gallery.entryRequested(gallery.entries.findIndex(entry => entry.id === itemId))
        focused: gallery.focused
        motionTokens: gallery.motionTokens
        visibleBudget: width >= 1000 ? 5 : 3
        centerContent: true
        skewAngle: -11
        leadingCount: Math.floor(visibleBudget / 2)
        cardWidth: Math.min(285, width / 4.9)
        selectedWidth: Math.min(330, width / 3.7)
        cardHeight: Math.min(142, Math.max(0, gallery.height - heading.height) * 0.72)
        selectedHeight: Math.min(156, Math.max(0, gallery.height - heading.height) * 0.92)
        spacing: Theme.spacingXL

        cardDelegate: SlantedImage {
            id: card

            property var itemData: null
            property bool interactive: false

            styleTokens: gallery.styleTokens
            motionTokens: gallery.motionTokens
            source: card.itemData?.artwork ?? ""
            skewAngle: carousel.skewAngle
            fallbackText: gallery.tr("mockup.capture.unavailable", "Preview unavailable")

            StyledText {
                id: caption

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Theme.spacingS
                text: card.itemData?.title ?? gallery.tr(card.itemData?.titleKey, "")
                elide: Text.ElideRight
                color: gallery.foreground
                font.pixelSize: Theme.fontSizeSmall
            }

            Accessible.role: Accessible.Button
            Accessible.name: caption.text
            Accessible.ignored: !card.interactive || !enabled || !visible
            Accessible.focused: focused && !Accessible.ignored
            Accessible.selected: selected
            Accessible.onPressAction: {
                if (!Accessible.ignored)
                    gallery.entryRequested(gallery.entries.findIndex(entry => entry.id === card.itemData?.id))
            }

        }
    }

    StatusMessage {
        anchors.centerIn: carousel
        visible: gallery.entries.length === 0
        styleTokens: gallery.styleTokens
        text: gallery.tr("mockup.capture.empty", "No captures yet")
    }
}
