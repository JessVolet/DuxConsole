pragma ComponentBehavior: Bound

import QtQuick
import qs.Common

Item {
    id: wheel

    property string side: "left"
    property var categories: []
    property var commands: []
    property var styleTokens: null
    property var motionTokens: null
    property int currentCategory: 0
    property int currentCommand: 0
    property bool categoryFocused: false
    property bool commandFocused: false
    property bool interactive: true
    property bool opened: false
    property string originIcon: ""
    property string closeLabel: ""

    signal categoryPicked(int categoryIndex)
    signal commandPicked(int commandIndex)
    signal closeRequested()

    readonly property real layoutScale: Math.min(1, width / 1360, height / 690)
    readonly property real outerRadius: 372 * layoutScale
    readonly property real innerRadius: 228 * layoutScale
    readonly property real originX: side === "left" ? 72 * layoutScale : width - 72 * layoutScale
    readonly property real originY: 48 * layoutScale
    readonly property real sideSign: side === "left" ? 1 : -1

    opacity: opened ? 1 : 0
    visible: opacity > 0

    function angle(index, count) {
        return (count < 2 ? 42 : 8 + (76 * index) / (count - 1)) * Math.PI / 180
    }

    Behavior on opacity {
        NumberAnimation {
            duration: wheel.opened ? (wheel.motionTokens?.fadeInDuration ?? 0) : (wheel.motionTokens?.fadeOutDuration ?? 0)
            easing.type: wheel.opened ? (wheel.motionTokens?.fadeInEasing ?? Easing.OutCubic) : (wheel.motionTokens?.fadeOutEasing ?? Easing.InCubic)
        }
    }

    Item {
        anchors.fill: parent
        transform: Scale {
            origin.x: wheel.originX
            origin.y: wheel.originY
            xScale: wheel.opened ? 1 : 0.38
            yScale: xScale

            Behavior on xScale {
                NumberAnimation {
                    duration: wheel.motionTokens?.durationMorph ?? 0
                    easing.type: wheel.motionTokens?.easingSnappy ?? Easing.OutCubic
                }
            }
        }

        Rectangle {
            x: wheel.originX - width / 2
            y: wheel.originY - height / 2
            width: wheel.outerRadius * 2
            height: width
            radius: width / 2
            color: "transparent"
            border.width: Math.round(104 * wheel.layoutScale)
            border.color: wheel.styleTokens?.surfaceColor("chrome") ?? Theme.surfaceContainerHighest
            opacity: 0.88
        }

        Rectangle {
            x: wheel.originX - width / 2
            y: wheel.originY - height / 2
            width: wheel.innerRadius * 2
            height: width
            radius: width / 2
            color: wheel.styleTokens?.surfaceColor("chrome") ?? Theme.surfaceContainerHighest
            opacity: 0.92
        }

        OrbitNode {
            x: wheel.originX - width / 2
            y: wheel.originY - height / 2
            width: 72 * wheel.layoutScale
            height: width
            iconName: wheel.originIcon
            label: wheel.closeLabel
            selected: true
            interactive: wheel.interactive
            styleTokens: wheel.styleTokens
            motionTokens: wheel.motionTokens
            onTriggered: wheel.closeRequested()
        }

        Repeater {
            model: wheel.categories

            OrbitNode {
                id: category
                required property int index
                required property var modelData
                readonly property real angle: wheel.angle(index, wheel.categories.length)

                x: wheel.originX + wheel.sideSign * Math.cos(angle) * 185 * wheel.layoutScale - width / 2
                y: wheel.originY + Math.sin(angle) * 185 * wheel.layoutScale - height / 2
                width: 62 * wheel.layoutScale
                height: width
                iconName: modelData.icon
                label: modelData.label
                selected: index === wheel.currentCategory
                focused: selected && wheel.categoryFocused
                interactive: wheel.interactive
                styleTokens: wheel.styleTokens
                motionTokens: wheel.motionTokens
                onTriggered: wheel.categoryPicked(category.index)
            }
        }

        Repeater {
            model: wheel.commands

            OrbitNode {
                id: command
                required property int index
                required property var modelData
                readonly property real angle: wheel.angle(index, wheel.commands.length)

                x: wheel.originX + wheel.sideSign * Math.cos(angle) * 319 * wheel.layoutScale - width / 2
                y: wheel.originY + Math.sin(angle) * 319 * wheel.layoutScale - height / 2
                width: 68 * wheel.layoutScale
                height: width
                iconName: modelData.icon
                label: modelData.title
                selected: index === wheel.currentCommand
                focused: selected && wheel.commandFocused
                interactive: wheel.interactive
                styleTokens: wheel.styleTokens
                motionTokens: wheel.motionTokens
                onTriggered: wheel.commandPicked(command.index)
            }
        }
    }
}
