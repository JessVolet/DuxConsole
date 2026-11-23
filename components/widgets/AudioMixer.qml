pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/meters"
import "../primitives/surfaces"
import "../primitives/text"

Item {
    id: mixer

    property var channels: []
    property int currentIndex: 0
    property bool focused: false
    property bool interactive: true
    property var i18n: null
    property var styleTokens: null
    property var motionTokens: null
    signal channelRequested(int index)

    readonly property color foreground: styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText
    readonly property real rowHeight: Math.min(height * 0.25, 112)

    function tr(key, fallback) {
        return i18n?.t(key, fallback) ?? fallback
    }

    function distanceTo(index) {
        const count = channels.length
        const delta = index - currentIndex
        return Math.abs(delta) > count / 2 ? delta - Math.sign(delta) * count : delta
    }

    Item {
        id: stack

        anchors.fill: parent
        anchors.bottomMargin: Theme.spacingXL
        clip: true

        Repeater {
            model: mixer.channels

            delegate: SlantedSurface {
                id: channel

                required property int index
                required property var modelData
                readonly property int distance: mixer.distanceTo(index)

                role: selected ? "selectedCard" : "card"
                width: parent.width * (selected ? 0.94 : 0.84)
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2 + distance * mixer.rowHeight * 0.8
                height: selected ? mixer.rowHeight : mixer.rowHeight * 0.62
                z: selected ? 2 : 1
                opacity: selected ? 1 : Math.max(0, 0.72 - Math.abs(distance) * 0.2)
                visible: opacity > 0.01
                selected: index === mixer.currentIndex
                focused: mixer.focused && selected
                surfaceOpacity: selected ? 1 : 0.72
                styleTokens: mixer.styleTokens
                motionTokens: mixer.motionTokens

                Accessible.role: Accessible.Button
                Accessible.ignored: !visible || !mixer.interactive
                Accessible.focused: channel.focused && !Accessible.ignored
                Accessible.name: title.text + ", " + summary.text
                Accessible.onPressAction: {
                    if (mixer.interactive)
                        mixer.channelRequested(index)
                }

                Behavior on y {
                    NumberAnimation {
                        duration: mixer.motionTokens?.durationNormal ?? 0
                        easing.type: mixer.motionTokens?.easingSnappy ?? Easing.Linear
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: mixer.motionTokens?.fadeInDuration ?? 0
                        easing.type: mixer.motionTokens?.fadeInEasing ?? Easing.Linear
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.spacingXL
                    spacing: Theme.spacingXS

                    StyledText {
                        id: title

                        width: parent.width
                        text: mixer.tr(channel.modelData.labelKey, channel.modelData.name ?? "")
                        color: mixer.foreground
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    StyledText {
                        id: summary

                        text: channel.modelData.muted ? mixer.tr("mockup.audio.muted", "Muted") : channel.modelData.level + "%"
                        color: Theme.withAlpha(mixer.foreground, 0.72)
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    ValueMeter {
                        visible: channel.selected && channel.height >= 60
                        enabled: mixer.interactive
                        width: parent.width
                        styleTokens: mixer.styleTokens
                        motionTokens: mixer.motionTokens
                        value: channel.modelData.muted ? 0 : channel.modelData.level
                        unit: "%"
                        label: title.text
                    }
                }

                TapHandler {
                    enabled: mixer.interactive
                    onTapped: mixer.channelRequested(channel.index)
                }
            }
        }

        StatusMessage {
            anchors.centerIn: parent
            visible: mixer.channels.length === 0
            styleTokens: mixer.styleTokens
            text: mixer.tr("mockup.audio.noChannels", "No audio channels")
        }
    }

    StyledText {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        text: mixer.tr("mockup.audio.mixer", "Mixer")
        color: mixer.foreground
        font.weight: Font.Bold
    }
}
