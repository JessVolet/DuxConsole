import QtQuick
import qs.Common

Column {
    id: actions

    property var i18n: null
    property var styleTokens: null
    property var motionTokens: null
    property var iconsPadManager: null
    property bool recording: false
    property bool replayEnabled: false
    property bool interactive: true
    property int focusedIndex: -1

    signal commandRequested(int index)

    function tr(key, fallback) {
        return i18n?.t(key, fallback) ?? fallback
    }

    spacing: Theme.spacingM

    ControlStrip {
        width: parent.width
        prominent: true
        vertical: true
        entries: [
            {label: actions.tr("mockup.capture.screenshot", "Take screenshot"), glyph: "I.Accept"},
            {label: actions.recording ? actions.tr("mockup.capture.stop", "Stop recording") : actions.tr("mockup.capture.record", "Record"), glyph: "I.Accept", selected: actions.recording},
            {label: actions.tr("mockup.capture.replay", "Last 30 seconds"), glyph: "I.Accept", disabled: !actions.replayEnabled}
        ]
        styleTokens: actions.styleTokens
        motionTokens: actions.motionTokens
        iconsPadManager: actions.iconsPadManager
        interactive: actions.interactive
        focusedIndex: actions.focusedIndex
        onInvoked: index => actions.commandRequested(index)
    }

    ControlStrip {
        width: parent.width
        entries: [{label: actions.tr("mockup.capture.settings", "Settings"), glyph: "I.Options"}]
        styleTokens: actions.styleTokens
        motionTokens: actions.motionTokens
        iconsPadManager: actions.iconsPadManager
        interactive: actions.interactive
        focusedIndex: actions.focusedIndex === 3 ? 0 : -1
        onInvoked: actions.commandRequested(3)
    }
}
