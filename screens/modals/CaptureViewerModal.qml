import QtQuick
import qs.Common
import "../../components/widgets"
import "../../core/interaction"

FixtureModalFrame {
    id: viewer

    property var entries: []
    property int currentIndex: 0
    property var i18n: null
    property var motionTokens: null
    property var iconsPadManager: null
    property var layerManager: null
    property var navigationManager: null
    property string layerName: "mock-capture-viewer"

    signal entryRequested(int index)

    visible: layerManager?.stack.includes(layerName) ?? false
    accessibilityActive: layerManager?.topLayer === layerName
    preferredWidth: width - Theme.spacingXL * 2
    preferredHeight: height - Theme.spacingXL * 2
    accessibleLabel: i18n?.t("mockup.capture.viewer", "Capture viewer") ?? "Capture viewer"

    FocusZone {
        id: playbackZone

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: stripZone.top
        anchors.margins: Theme.spacingM
        zoneId: "mock-capture-playback"
        layerName: viewer.layerName
        layerManager: viewer.layerManager
        navigationManager: viewer.navigationManager
        defaultFocus: Boolean(playback.entry)
        enabled: playback.canPlay
        showFocusRing: false
        navDown: stripZone
        actionHints: [
            { action: "I.Accept", labelKey: "mockup.media.playPause", fallback: "Play / Pause" },
            { action: "I.Action", labelKey: "mockup.media.restart", fallback: "Restart" }
        ]
        onActivated: playback.togglePlay()
        onSecondaryTriggered: playback.rewind()

        CapturePreview {
            id: playback

            anchors.fill: parent
            entry: viewer.entries[viewer.currentIndex] ?? null
            i18n: viewer.i18n
            expanded: true
            styleTokens: viewer.styleTokens
            motionTokens: viewer.motionTokens
            iconsPadManager: viewer.iconsPadManager
            focused: playbackZone.active
            interactive: !playbackZone.inert
            onActivated: {
                if (playbackZone.requestZoneFocus())
                    playbackZone.activate()
            }
        }
    }

    FocusZone {
        id: stripZone

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingM
        height: parent.height * 0.23
        zoneId: "mock-capture-viewer-strip"
        layerName: viewer.layerName
        layerManager: viewer.layerManager
        navigationManager: viewer.navigationManager
        defaultFocus: !playbackZone.enabled
        showFocusRing: false
        navUp: playbackZone
        actionHints: [
            { action: "I.Dpad.Left", labelKey: "hints.cycle", fallback: "Cycle" },
            { action: "I.Dpad.Right", labelKey: "hints.cycle", fallback: "Cycle" }
        ]
        onDpadUnhandled: direction => {
            const count = viewer.entries.length
            if (count < 2 || (direction !== "left" && direction !== "right"))
                return
            const delta = direction === "left" ? -1 : 1
            viewer.entryRequested((viewer.currentIndex + delta + count) % count)
        }

        CaptureGallery {
            anchors.fill: parent
            entries: viewer.entries
            currentIndex: viewer.currentIndex
            i18n: viewer.i18n
            styleTokens: viewer.styleTokens
            motionTokens: viewer.motionTokens
            focused: stripZone.active
            interactive: !stripZone.inert
            onEntryRequested: index => {
                if (stripZone.requestZoneFocus()) {
                    viewer.entryRequested(index)
                }
            }
        }
    }
}
