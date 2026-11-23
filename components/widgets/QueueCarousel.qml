pragma ComponentBehavior: Bound

import QtQuick
import "CarouselLayout.js" as Layout

Item {
    id: carousel

    property var entries: []
    property var selectedId
    property Component cardDelegate: null
    property var cardControlContains: null
    property var motionTokens: null
    property bool focused: false
    property bool interactive: enabled
    property int visibleBudget: 5
    property int leadingCount: 1
    property real cardWidth: 158
    property real cardHeight: 156
    property real selectedWidth: 330
    property real selectedHeight: 222
    property real spacing: 36
    property bool centerContent: false
    property real skewAngle: -8
    readonly property int count: entries.length
    readonly property var placements: Layout.placements(entries, selectedId, visibleBudget, leadingCount)
    readonly property real skewPadding: Math.abs(Math.tan(skewAngle * Math.PI / 180)) * Math.max(cardHeight, selectedHeight)
    readonly property real naturalWidth: selectedWidth + Math.max(0, placements.length - 1) * (cardWidth + spacing) + skewPadding
    readonly property real naturalHeight: Math.max(cardHeight, selectedHeight)
    readonly property real layoutScale: Math.max(0, Math.min(1, width / Math.max(1, naturalWidth), height / Math.max(1, naturalHeight)))
    readonly property int moveDuration: motionTokens?.durationNormal ?? 0
    readonly property int fadeInDuration: motionTokens?.fadeInDuration ?? 0
    readonly property int fadeOutDuration: motionTokens?.fadeOutDuration ?? 0
    property var slots: new Map()
    property int lastIndex: -1

    signal cardClicked(var itemId)

    implicitWidth: selectedWidth + skewPadding
    implicitHeight: naturalHeight
    clip: true

    function sync() {
        const center = placements.find(placement => placement.offset === 0)
        const move = Layout.direction(lastIndex, center?.index ?? -1, count)
        lastIndex = center?.index ?? -1
        const next = new Map(placements.map(placement => [placement.entry.id, placement]))
        for (const [id, slot] of slots) {
            const target = next.get(id)
            if (!target) {
                slot.retire(null)
                continue
            }
            next.delete(id)
            const previous = slot.placement
            if (slot.retiring && target.offset === 0) {
                slot.reactivate(target)
            } else if (slot.retiring || (move !== 0 && target.offset !== 0
                                  && Math.sign(target.offset - previous.offset) === move)) {
                slot.retire(target)
            } else {
                slot.placement = target
            }
        }
        for (const [id, placement] of next) {
            const slot = slotFactory.createObject(carousel, { placement })
            if (slot)
                slots.set(id, slot)
        }
        for (const [id, slot] of slots) {
            if (slots.size <= visibleBudget * 2)
                break
            if (slot.retiring && !slot.pendingPlacement) {
                slots.delete(id)
                slot.destroy()
            }
        }
    }

    function slotX(placement) {
        const widened = placement.offset > 0 ? selectedWidth - cardWidth : 0
        const leftPadding = skewAngle < 0 ? skewPadding : 0
        const offset = centerContent ? Math.max(0, (width - naturalWidth * layoutScale) / 2) : 0
        return offset + (leftPadding + placement.slot * (cardWidth + spacing) + widened) * layoutScale
    }

    onPlacementsChanged: if (slots) sync()
    Component.onCompleted: sync()

    Component {
        id: slotFactory

        Item {
            id: slot

            required property var placement
            property var pendingPlacement: null
            property bool shown: false
            property bool retiring: false
            property bool teleporting: true
            readonly property bool selected: placement.offset === 0 && !retiring

            x: carousel.slotX(placement)
            y: (carousel.height - height) / 2
            width: (placement.offset === 0 ? carousel.selectedWidth : carousel.cardWidth) * carousel.layoutScale
            height: (placement.offset === 0 ? carousel.selectedHeight : carousel.cardHeight) * carousel.layoutScale
            opacity: shown ? 1 : 0
            z: selected ? 2 : 1

            function retire(target) {
                pendingPlacement = target
                if (retiring)
                    return
                retiring = true
                shown = false
                if (carousel.fadeOutDuration > 0)
                    retireTimer.restart()
                else
                    finishRetirement()
            }

            function reactivate(target) {
                retireTimer.stop()
                pendingPlacement = null
                placement = target
                retiring = false
                shown = true
            }

            function finishRetirement() {
                if (!pendingPlacement) {
                    carousel.slots.delete(placement.entry.id)
                    destroy()
                    return
                }
                teleporting = true
                placement = pendingPlacement
                pendingPlacement = null
                retiring = false
                reveal()
            }

            function reveal() {
                Qt.callLater(() => {
                    teleporting = false
                    if (!retiring)
                        shown = true
                })
            }

            Timer {
                id: retireTimer
                interval: Math.max(1, carousel.fadeOutDuration)
                onTriggered: slot.finishRetirement()
            }

            Behavior on x {
                enabled: !slot.teleporting
                NumberAnimation {
                    duration: carousel.moveDuration
                    easing.type: carousel.motionTokens?.easingSnappy ?? Easing.Linear
                }
            }

            Behavior on width {
                enabled: !slot.teleporting
                NumberAnimation { duration: carousel.moveDuration }
            }

            Behavior on height {
                enabled: !slot.teleporting
                NumberAnimation { duration: carousel.moveDuration }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: slot.shown ? carousel.fadeInDuration : carousel.fadeOutDuration
                    easing.type: slot.shown
                        ? (carousel.motionTokens?.fadeInEasing ?? Easing.Linear)
                        : (carousel.motionTokens?.fadeOutEasing ?? Easing.Linear)
                }
            }

            Loader {
                id: cardLoader
                anchors.fill: parent
                sourceComponent: carousel.cardDelegate

                Binding {
                    target: cardLoader.item
                    property: "itemData"
                    value: slot.placement.entry
                    when: cardLoader.item !== null
                }

                Binding {
                    target: cardLoader.item
                    property: "selected"
                    value: slot.selected
                    when: cardLoader.item !== null
                }

                Binding {
                    target: cardLoader.item
                    property: "focused"
                    value: slot.selected && carousel.focused
                    when: cardLoader.item !== null
                }
            }

            TapHandler {
                enabled: carousel.interactive && slot.shown && !slot.retiring
                onTapped: eventPoint => {
                    if (!carousel.cardControlContains?.(cardLoader.item, eventPoint.position))
                        carousel.cardClicked(slot.placement.entry.id)
                }
            }

            Component.onCompleted: reveal()
        }
    }
}
