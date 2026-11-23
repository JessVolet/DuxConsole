import QtQuick
import QtMultimedia
import qs.Common
import qs.Widgets
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

        ControlStrip {
            anchors.centerIn: parent
            width: implicitWidth
            visible: preview.video && !preview.playing && (!preview.expanded || preview.canPlay)
            styleTokens: preview.styleTokens
            motionTokens: preview.motionTokens
            iconsPadManager: preview.iconsPadManager
            interactive: preview.interactive
            entries: [{label: preview.tr("mockup.media.play", "Play"), glyph: "I.Accept"}]
            onInvoked: preview.activated()
        }

        TapHandler {
            enabled: preview.interactive && Boolean(preview.entry) && !preview.expanded
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
