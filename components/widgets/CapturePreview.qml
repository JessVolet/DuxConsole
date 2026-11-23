import QtQuick
import QtMultimedia
import QtQuick.Controls
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets as DCommon
import "../primitives/meters"
import "../primitives/surfaces"

Item {
    id: preview

    property var entry: null
    property var styleTokens: null
    property var motionTokens: null
    property var iconsPadManager: null
    property var i18n: null
    property bool interactive: true
    property bool focused: false
    property bool expanded: false
    property bool selected: false
    signal activated()
    readonly property bool video: entry?.kind === "video"
    readonly property bool canPlay: video && (entry?.source ?? "") !== "" && clip.error === MediaPlayer.NoError
    readonly property bool playing: clip.playbackState === MediaPlayer.PlayingState
    readonly property color foreground: styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText
    readonly property string title: entry?.title ?? tr(entry?.titleKey, "")

    Accessible.role: Accessible.Button
    Accessible.name: title
    Accessible.description: tr("mockup.capture.viewer", "Capture viewer")
    Accessible.ignored: !interactive || !visible || expanded || !entry || video
    Accessible.focused: focused && !Accessible.ignored
    Accessible.onPressAction: {
        if (!Accessible.ignored)
            activated()
    }

    function tr(key, fallback) {
        return i18n?.t(key, fallback) ?? fallback
    }

    function togglePlay() {
        if (!expanded || !canPlay)
            return
        if (playing)
            clip.pause()
        else
            clip.play()
    }

    function rewind() {
        if (expanded && canPlay)
            clip.position = 0
    }

    onVisibleChanged: {
        if (!visible)
            clip.stop()
    }

    MediaPlayer {
        id: clip

        source: preview.expanded && preview.visible && preview.video ? (preview.entry?.source ?? "") : ""
        videoOutput: movie
    }

    SlantedImage {
        anchors.fill: parent
        anchors.bottomMargin: preview.expanded && preview.canPlay ? controls.height + Theme.spacingS : 0
        source: preview.entry?.artwork ?? ""
        skewAngle: 0
        showGradientOverlay: Boolean(preview.entry)
        styleTokens: preview.styleTokens
        motionTokens: preview.motionTokens
        selected: preview.selected
        focused: preview.focused
        fallbackText: preview.entry ? preview.tr("mockup.capture.unavailable", "Preview unavailable") : preview.tr("mockup.capture.empty", "No captures yet")

        VideoOutput {
            id: movie

            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectFit
            visible: preview.expanded && preview.canPlay && clip.position > 0
        }

        StyledText {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.spacingM
            visible: preview.title !== ""
            text: preview.title
            elide: Text.ElideRight
            color: preview.foreground
            font.weight: Font.Medium
        }

        RoundButton {
            id: previewPlay
            anchors.centerIn: parent
            width: Math.min(64, parent.height * 0.22)
            height: width
            radius: width / 2
            focusPolicy: Qt.NoFocus
            visible: preview.video && !preview.playing && (!preview.expanded || preview.canPlay)
            enabled: preview.interactive
            Accessible.name: preview.tr("mockup.media.play", "Play")
            Accessible.focused: preview.focused && !Accessible.ignored
            Accessible.ignored: !visible || !enabled
            onClicked: preview.activated()

            background: Rectangle {
                radius: previewPlay.radius
                color: preview.styleTokens?.scrimColor(0.65) ?? Theme.surface
                border.color: preview.foreground
                border.width: (previewPlay.hovered || preview.focused) ? 4 : 3
            }

            contentItem: Item {
                DCommon.DIcon {
                    anchors.centerIn: parent
                    name: "play_arrow"
                    size: Math.round(previewPlay.width * 0.58)
                    color: preview.foreground
                }
            }
        }

        TapHandler {
            enabled: preview.interactive && Boolean(preview.entry) && !preview.expanded && !preview.video
            onTapped: preview.activated()
        }
    }

    Row {
        id: controls

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: Theme.spacingM
        visible: preview.expanded && preview.canPlay

        ControlStrip {
            id: playButton

            width: implicitWidth
            styleTokens: preview.styleTokens
            motionTokens: preview.motionTokens
            iconsPadManager: preview.iconsPadManager
            interactive: preview.interactive
            focusedIndex: preview.focused ? 0 : -1
            entries: [{ label: preview.playing ? preview.tr("mockup.media.pause", "Pause") : preview.tr("mockup.media.play", "Play"), glyph: "I.Accept" }]
            onInvoked: preview.activated()
        }

        ValueMeter {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width - playButton.width - parent.spacing)
            styleTokens: preview.styleTokens
            motionTokens: preview.motionTokens
            maximum: clip.duration
            value: clip.position
            label: preview.tr("mockup.media.progress", "Playback progress")

            TapHandler {
                enabled: preview.interactive && clip.seekable
                onTapped: event => clip.position = clip.duration * Math.max(0, Math.min(1, event.position.x / parent.width))
            }
        }
    }
}
