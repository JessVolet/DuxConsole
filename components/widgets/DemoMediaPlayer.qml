pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/meters"
import "../primitives/surfaces"

SlantedSurface {
    id: player

    property var track: null
    property var i18n: null
    property var iconsPadManager: null
    property bool expanded: false
    property bool interactive: true
    property int controlIndex: 0
    signal playRequested()
    signal seekRequested(real position)
    signal expandRequested()

    readonly property color foreground: styleTokens?.onSurfaceColor(role) ?? Theme.surfaceText
    readonly property color accent: styleTokens?.accentColor ?? Theme.primary

    function tr(key, fallback) {
        return i18n?.t(key, fallback) ?? fallback
    }

    function timecode(seconds) {
        const ticks = Math.max(0, Math.floor(seconds ?? 0))
        return String(Math.floor(ticks / 60)) + ":" + String(ticks % 60).padStart(2, "0")
    }

    implicitWidth: expanded ? 520 : 340
    implicitHeight: expanded ? 330 : 110
    surfaceOpacity: 0.84
    skewAngle: expanded ? 0 : (styleTokens?.skewAngle ?? -8)

    Column {
        anchors.fill: parent
        anchors.margins: player.expanded ? Theme.spacingXL : Theme.spacingM
        spacing: Theme.spacingM

        Row {
            width: parent.width
            height: player.expanded ? 124 : parent.height
            spacing: Theme.spacingM

            SlantedImage {
                id: artwork

                width: Math.min(height, parent.width * 0.25)
                height: parent.height
                source: player.track?.artwork ?? ""
                styleTokens: player.styleTokens
                skewAngle: 0
                showGradientOverlay: false
                fallbackText: player.track ? player.tr("mockup.media.artwork", "Audio") : "—"
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, parent.width - artwork.width - parent.spacing)
                spacing: Theme.spacingXS

                StyledText {
                    width: parent.width
                    text: player.track?.title ?? player.tr("mockup.media.idle", "No active media")
                    color: player.foreground
                    font.pixelSize: player.expanded ? Theme.fontSizeLarge * 1.4 : Theme.fontSizeLarge
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    text: player.track?.artist ?? ""
                    visible: text !== ""
                    color: Theme.withAlpha(player.foreground, 0.72)
                    elide: Text.ElideRight
                }

                Row {
                    visible: !player.expanded && Boolean(player.track)
                    spacing: Theme.spacingXS

                    Repeater {
                        model: [8, 15, 10, 17, 6]

                        Rectangle {
                            required property int modelData
                            anchors.bottom: parent.bottom
                            width: Theme.spacingXS
                            height: player.track?.playing ? modelData : Theme.spacingXS
                            color: player.accent
                            radius: width / 2
                        }
                    }
                }
            }
        }

        ValueMeter {
            width: parent.width
            visible: player.expanded && Boolean(player.track)
            styleTokens: player.styleTokens
            motionTokens: player.motionTokens
            maximum: player.track?.duration ?? 1
            value: player.track?.position ?? 0
            label: player.tr("mockup.media.progress", "Playback progress")

            TapHandler {
                enabled: player.interactive && player.expanded && Boolean(player.track)
                onTapped: event => {
                    const fraction = Math.max(0, Math.min(1, event.position.x / parent.width))
                    player.seekRequested(fraction * (player.track?.duration ?? 0))
                }
            }
        }

        StyledText {
            visible: player.expanded && Boolean(player.track)
            color: player.foreground
            text: player.timecode(player.track?.position) + " / " + player.timecode(player.track?.duration)
        }

        ControlStrip {
            width: parent.width
            visible: player.expanded && Boolean(player.track)
            interactive: player.interactive
            focusedIndex: player.controlIndex
            styleTokens: player.styleTokens
            motionTokens: player.motionTokens
            iconsPadManager: player.iconsPadManager
            entries: [
                { label: player.tr("mockup.media.back", "Back 10 s"), glyph: "I.ActionOption.L" },
                { label: player.track?.playing ? player.tr("mockup.media.pause", "Pause") : player.tr("mockup.media.play", "Play"), glyph: "I.Accept" },
                { label: player.tr("mockup.media.forward", "Forward 10 s"), glyph: "I.ActionOption.R" }
            ]
            onInvoked: index => {
                if (index === 1)
                    player.playRequested()
                else
                    player.seekRequested((player.track?.position ?? 0) + (index === 0 ? -10 : 10))
            }
        }
    }

    TapHandler {
        enabled: player.interactive && !player.expanded && Boolean(player.track)
        onTapped: player.expandRequested()
    }
}
