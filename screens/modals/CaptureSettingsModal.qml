import QtQuick
import qs.Common
import "../../components/primitives/text"
import "../../components/widgets"
import "../../core/interaction"

FixtureModalFrame {
    id: modal

    property bool replayEnabled: false
    property bool microphone: false
    property var layerManager: null
    property var navigationManager: null
    property var i18n: null
    property var motionTokens: null
    property var iconsPadManager: null
    property string layerName: "mock-capture-settings"
    signal optionRequested(int index)

    function tr(key, fallback) {
        return i18n?.t(key, fallback) ?? fallback
    }

    visible: layerManager?.stack.includes(layerName) ?? false
    accessibilityActive: layerManager?.topLayer === layerName
    preferredWidth: 460
    preferredHeight: 260
    accessibleLabel: tr("mockup.capture.settings", "Settings")

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingXL

        SectionTitle {
            width: parent.width
            title: modal.accessibleLabel
            styleTokens: modal.styleTokens
        }

        FocusZone {
            id: options

            width: parent.width
            height: controls.implicitHeight
            zoneId: "mock-capture-settings-options"
            layerName: modal.layerName
            layerManager: modal.layerManager
            navigationManager: modal.navigationManager
            defaultFocus: true
            showFocusRing: false
            subItemCount: 2
            actionHints: [
                { action: "I.Accept", labelKey: "mockup.capture.toggle", fallback: "Toggle" },
                { action: "I.ActionOption.L", labelKey: "hints.cycle", fallback: "Cycle" },
                { action: "I.ActionOption.R", labelKey: "hints.cycle", fallback: "Cycle" }
            ]
            onActivated: index => modal.optionRequested(index)

            ControlStrip {
                id: controls

                width: parent.width
                vertical: true
                interactive: !options.inert
                styleTokens: modal.styleTokens
                motionTokens: modal.motionTokens
                iconsPadManager: modal.iconsPadManager
                focusedIndex: options.active ? options.currentSubIndex : -1
                entries: [
                    { label: modal.tr("mockup.capture.buffer", "Replay buffer") + " · " + (modal.replayEnabled ? modal.tr("mockup.capture.on", "On") : modal.tr("mockup.capture.off", "Off")), selected: modal.replayEnabled },
                    { label: modal.tr("mockup.capture.microphone", "Include microphone") + " · " + (modal.microphone ? modal.tr("mockup.capture.on", "On") : modal.tr("mockup.capture.off", "Off")), selected: modal.microphone }
                ]
                onInvoked: index => {
                    if (options.requestZoneFocus()) {
                        options.currentSubIndex = index
                        options.activate()
                    }
                }
            }
        }
    }
}
