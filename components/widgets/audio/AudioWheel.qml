pragma ComponentBehavior: Bound
import QtQuick
import qs.Common

// Stable-item wheel: every entry keeps one delegate and animates its offset,
// so wrapping never recreates a card at the other end (no teleport).
Item {
    id: wheel

    property var model: null
    property int currentIndex: 0
    property real cardWidth: 250
    property real cardHeight: 66
    property real selectedWidth: 290
    property real selectedHeight: 90
    property real spacing: 24
    property var motionTokens: null
    property var styleTokens: null
    property var i18n: null
    property bool focused: false

    readonly property int count: model && typeof model.count === "number" ? model.count : 0
    readonly property real step: cardHeight + spacing
    readonly property Item selectedItem: count > 0 ? repeater.itemAt(currentIndex) : null

    signal chosen(int index)

    clip: true

    function distanceTo(index) {
        if (count <= 0)
            return 0
        let delta = index - currentIndex
        if (delta > count / 2)
            delta -= count
        else if (delta < -count / 2)
            delta += count
        return delta
    }

    function itemDataAt(index) {
        return model && typeof model.get === "function" ? model.get(index) : null
    }

    Repeater {
        id: repeater
        model: wheel.model

        delegate: AudioTargetCard {
            id: card
            required property int index

            readonly property int distance: wheel.distanceTo(index)
            readonly property int behaviorDuration: wheel.motionTokens ? wheel.motionTokens.durationNormal : 0

            itemData: wheel.itemDataAt(index)
            i18n: wheel.i18n
            styleTokens: wheel.styleTokens
            motionTokens: wheel.motionTokens
            selected: wheel.currentIndex === index
            focused: wheel.focused && selected
            width: selected ? wheel.selectedWidth : wheel.cardWidth
            height: selected ? wheel.selectedHeight : wheel.cardHeight
            x: (wheel.width - width) / 2
            y: (wheel.height - height) / 2 + distance * wheel.step
            z: selected ? 10 : 1
            opacity: selected ? 1 : Math.max(0.3, 0.78 - Math.abs(distance) * 0.16)
            visible: Math.abs(distance) <= 3

            Behavior on y {
                NumberAnimation {
                    duration: card.behaviorDuration
                    easing.type: wheel.motionTokens ? wheel.motionTokens.easingSnappy : Easing.Linear
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: card.behaviorDuration
                    easing.type: wheel.motionTokens ? wheel.motionTokens.easingSnappy : Easing.Linear
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: card.behaviorDuration
                    easing.type: wheel.motionTokens ? wheel.motionTokens.easingSnappy : Easing.Linear
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: wheel.motionTokens ? wheel.motionTokens.fadeInDuration : 0
                    easing.type: wheel.motionTokens ? wheel.motionTokens.fadeInEasing : Easing.Linear
                }
            }

            onChosen: wheel.chosen(card.index)
        }
    }
}
