pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../../core/interaction"
import "../primitives/text"

FocusZone {
    id: shelf

    property var items: []
    property int selectedIndex: 0
    property var styleTokens: null
    property var motionTokens: null
    property string emptyLabel: ""
    property real aspectRatio: 2
    property int maxVisibleItems: 5
    property int leadingItems: -1
    property real featuredWidth: 0
    property real featuredHeight: 0
    property real sideWidthLimit: Number.POSITIVE_INFINITY
    property real sideHeightLimit: Number.POSITIVE_INFINITY
    property real cardGap: Theme.spacingM
    property real cardSkew: styleTokens?.skewAngle ?? -8
    property bool badgeLayout: false
    property bool detailsEnabled: true
    property bool expandedNavigation: false

    signal picked(int itemIndex)
    signal openItem(int itemIndex)

    implicitHeight: carousel.implicitHeight
    subItemCount: expandedNavigation ? 0 : items.length
    currentSubIndex: expandedNavigation ? 0 : selectedIndex
    enabled: items.length > 0
    showFocusRing: false
    expandable: detailsEnabled && enabled
    actionHints: {
        const hints = [{ action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" }]
        if (expandable)
            hints.push({ action: "I.Select", labelKey: "mockCollection.details", fallback: "Details" })
        if (items.length > 1 && expandedNavigation)
            hints.push(
                { action: "I.Dpad.Left", labelKey: "mockCollection.browse", fallback: "Browse" },
                { action: "I.Dpad.Right", labelKey: "mockCollection.browse", fallback: "Browse" }
            )
        if (items.length > 1 && !expandedNavigation)
            hints.push(
                { action: "I.ActionOption.L", labelKey: "mockCollection.browse", fallback: "Browse" },
                { action: "I.ActionOption.R", labelKey: "mockCollection.browse", fallback: "Browse" }
            )
        return hints
    }

    onSubItemCycled: newIndex => picked(newIndex)
    onActivated: itemIndex => openItem(expandedNavigation ? selectedIndex : itemIndex)
    onDpadUnhandled: direction => {
        if (!expandedNavigation || items.length < 2 || (direction !== "left" && direction !== "right"))
            return
        const delta = direction === "left" ? -1 : 1
        picked((selectedIndex + delta + items.length) % items.length)
    }

    StatusMessage {
        anchors.centerIn: parent
        width: Math.min(parent.width, implicitWidth)
        visible: shelf.items.length === 0
        text: shelf.emptyLabel
        styleTokens: shelf.styleTokens
    }

    QueueCarousel {
        id: carousel
        anchors.fill: parent
        entries: shelf.items
        selectedId: shelf.items[shelf.selectedIndex]?.id
        motionTokens: shelf.motionTokens
        focused: shelf.active
        interactive: !shelf.inert && shelf.enabled
        visibleBudget: Math.min(shelf.maxVisibleItems, Math.max(2, Math.floor(width / 168)))
        leadingCount: shelf.leadingItems >= 0 ? shelf.leadingItems : Math.floor(visibleBudget / 2)
        skewAngle: shelf.cardSkew
        cardWidth: Math.min(shelf.sideWidthLimit, width / visibleBudget, height * 0.83 * shelf.aspectRatio,
            shelf.featuredWidth > 0 ? sideBudget : Number.POSITIVE_INFINITY)
        cardHeight: Math.min(shelf.sideHeightLimit, cardWidth / shelf.aspectRatio)
        selectedWidth: shelf.featuredWidth > 0
            ? Math.min(width, shelf.featuredWidth) : Math.min(width * 0.92, cardWidth * 1.25)
        selectedHeight: shelf.featuredHeight > 0
            ? Math.min(height, shelf.featuredHeight) : Math.min(height * 0.93, cardHeight * 1.16)
        spacing: shelf.cardGap

        readonly property int sideCount: Math.max(1, placements.length - 1)
        readonly property real sideBudget: Math.max(1,
            (width - selectedWidth - Math.abs(Math.tan(skewAngle * Math.PI / 180)) * height) / sideCount - spacing)

        onCardClicked: itemId => {
            const itemIndex = shelf.items.findIndex(entry => entry.id === itemId)
            if (itemIndex < 0 || !shelf.requestZoneFocus())
                return
            if (itemIndex === shelf.selectedIndex)
                shelf.openItem(itemIndex)
            else
                shelf.picked(itemIndex)
        }

        cardDelegate: ShowcaseCard {
            styleTokens: shelf.styleTokens
            motionTokens: shelf.motionTokens
            badgeLayout: shelf.badgeLayout
            skewAngle: shelf.cardSkew
            title: itemData?.title ?? ""
            subtitle: itemData?.subtitle ?? ""
            iconName: itemData?.icon ?? ""
            source: itemData?.art ?? ""
            onPicked: itemId => carousel.cardClicked(itemId)
        }
    }
}
