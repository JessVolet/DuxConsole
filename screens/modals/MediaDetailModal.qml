import QtQuick
import qs.Common
import "../../components/widgets"
import "../../core/interaction"

FixtureModalFrame {
    id: modal

    property var track: null
    property var i18n: null
    property var motionTokens: null
    property var iconsPadManager: null
    property var layerManager: null
    property var navigationManager: null
    property string layerName: "mock-media"

    signal playRequested()
    signal seekRequested(real position)

    visible: layerManager?.stack.includes(layerName) ?? false
    accessibilityActive: layerManager?.topLayer === layerName
    entranceDuration: motionTokens?.sheetEntranceDuration ?? 0
    entranceEasing: motionTokens?.easingSnappy ?? Easing.OutCubic
    preferredWidth: 580
    preferredHeight: 360
    accessibleLabel: i18n?.t("media.title", "Media Player") ?? "Media Player"

    FocusZone {
        id: controls

        anchors.fill: parent
        anchors.margins: Theme.spacingS
        zoneId: "mock-media-controls"
        layerName: modal.layerName
        layerManager: modal.layerManager
        navigationManager: modal.navigationManager
        showFocusRing: false
        defaultFocus: true
        subItemCount: modal.track ? 3 : 0
        currentSubIndex: 1
        actionHints: modal.track ? [
            { action: "I.Accept", labelKey: "mockup.media.playPause", fallback: "Play / Pause" },
            { action: "I.ActionOption.L", labelKey: "hints.cycle", fallback: "Cycle" },
            { action: "I.ActionOption.R", labelKey: "hints.cycle", fallback: "Cycle" }
        ] : []
        onActivated: index => {
            if (!modal.track)
                return
            if (index === 1)
                modal.playRequested()
            else
                modal.seekRequested(modal.track.position + (index === 0 ? -10 : 10))
        }

        DemoMediaPlayer {
            anchors.fill: parent
            expanded: true
            interactive: !controls.inert
            controlIndex: controls.active ? controls.currentSubIndex : -1
            track: modal.track
            styleTokens: modal.styleTokens
            motionTokens: modal.motionTokens
            i18n: modal.i18n
            iconsPadManager: modal.iconsPadManager
            onPlayRequested: modal.playRequested()
            onSeekRequested: position => modal.seekRequested(position)
        }
    }
}
