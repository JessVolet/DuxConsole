pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Common
import ".."
import "../../primitives/buttons"
import "../../primitives/text"

Item {
    id: controls
    property var audioService: null
    property var inputManager: null
    property var layerManager: null
    property var navigationManager: null
    property var iconsPadManager: null
    property var styleTokens: null
    property var motionTokens: null
    property var i18n: null
    property string layerName: "dashboard"
    readonly property var focusedTarget: layerManager?.activeZone === apps.focusZone ? apps.selectedTarget : layerManager?.activeZone === outputs.focusZone ? outputs.selectedTarget : layerManager?.activeZone === inputs.focusZone ? inputs.selectedTarget : null
    function tr(key, fallback) {
        return i18n ? i18n.t(key, fallback) : fallback;
    }
    function connectWidget(widget) {
        widget.activationRequested.connect(key => audioService?.activate(key));
        widget.volumeRequested.connect((key, value) => audioService?.setVolume(key, value));
        widget.muteRequested.connect((key, muted) => audioService?.setMuted(key, muted));
        widget.optionsRequested.connect((key, source) => options.open(key, source));
    }
    Component.onCompleted: {
        for (const widget of [apps, outputs, inputs])
            connectWidget(widget);
    }
    Flickable {
        id: viewport
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(height, layout.implicitHeight)
        clip: true
        GridLayout {
            id: layout
            width: viewport.width
            height: viewport.contentHeight
            columns: controls.width < 800 ? 1 : 2
            columnSpacing: Theme.spacingXL
            rowSpacing: Theme.spacingM
            AppVolumeMixer {
                id: apps
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rowSpan: controls.width < 800 ? 1 : 2
                Layout.preferredHeight: 420
                Layout.minimumHeight: 300
                audioService: controls.audioService
                layerManager: controls.layerManager
                navigationManager: controls.navigationManager
                iconsPadManager: controls.iconsPadManager
                styleTokens: controls.styleTokens
                motionTokens: controls.motionTokens
                i18n: controls.i18n
                defaultFocus: true
            }
            AudioOutputSelector {
                id: outputs
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 180
                Layout.minimumHeight: 180
                audioService: controls.audioService
                layerManager: controls.layerManager
                navigationManager: controls.navigationManager
                iconsPadManager: controls.iconsPadManager
                styleTokens: controls.styleTokens
                motionTokens: controls.motionTokens
                i18n: controls.i18n
            }
            AudioInputSelector {
                id: inputs
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 180
                Layout.minimumHeight: 180
                audioService: controls.audioService
                layerManager: controls.layerManager
                navigationManager: controls.navigationManager
                iconsPadManager: controls.iconsPadManager
                styleTokens: controls.styleTokens
                motionTokens: controls.motionTokens
                i18n: controls.i18n
            }
            RowLayout {
                Layout.columnSpan: controls.width < 800 ? 1 : 2
                Layout.fillWidth: true
                Layout.preferredHeight: 156
                SectionTitle {
                    Layout.fillWidth: true
                    title: controls.focusedTarget?.title ?? controls.tr("audio.select_target", "Select an audio target")
                    subtitle: controls.audioService?.error ? controls.tr("audio.operation_failed", "Audio operation failed") : controls.tr("audio.knob_hint", "Right stick: volume · R3: mute")
                    styleTokens: controls.styleTokens
                }
                AngularVolumeKnob {
                    id: knob
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 150
                    value: controls.focusedTarget?.volume ?? 0
                    maximum: controls.focusedTarget?.maxVolume ?? 1
                    muted: controls.focusedTarget?.muted ?? false
                    targetKey: controls.focusedTarget?.key ?? ""
                    label: controls.tr("audio.volume", "Volume")
                    mutedText: controls.tr("audio.muted", "Muted")
                    inputConfig: controls.inputManager?.config?.analog?.right ?? null
                    enabled: controls.visible && controls.focusedTarget !== null && Boolean(controls.focusedTarget.canSetVolume)
                    styleTokens: controls.styleTokens
                    onValueRequested: value => controls.audioService?.setVolume(targetKey, value)
                    onMuteToggleRequested: {
                        if (controls.focusedTarget)
                            controls.audioService?.setMuted(targetKey, !controls.focusedTarget.muted);
                    }
                }
                ActionPill {
                    glyphAction: "I.PressStick.R"
                    iconsPadManager: controls.iconsPadManager
                    styleTokens: controls.styleTokens
                    text: knob.muted ? controls.tr("audio.unmute", "Unmute") : controls.tr("audio.mute", "Mute")
                    enabled: knob.enabled
                    primary: knob.muted
                    onClicked: knob.mute()
                }
            }
        }
    }
    Connections {
        target: controls.layerManager
        function onActiveZoneChanged() {
            const zone = controls.layerManager.activeZone;
            if (!controls.visible || ![apps.focusZone, outputs.focusZone, inputs.focusZone].includes(zone))
                return;
            const pos = zone.mapToItem(viewport.contentItem, 0, 0);
            if (pos.y < viewport.contentY)
                viewport.contentY = Math.max(0, pos.y);
            else if (pos.y + zone.height > viewport.contentY + viewport.height)
                viewport.contentY = Math.min(viewport.contentHeight - viewport.height, pos.y + zone.height - viewport.height);
        }
    }
    AudioDeviceOptions {
        id: options
        objectName: "audio-device-options"
        audioService: controls.audioService
        layerManager: controls.layerManager
        navigationManager: controls.navigationManager
        styleTokens: controls.styleTokens
        motionTokens: controls.motionTokens
        iconsPadManager: controls.iconsPadManager
        i18n: controls.i18n
    }
    Connections {
        target: controls.inputManager
        function onTriggered(action, payload) {
            if (!knob.enabled)
                return;
            if (action === controls.inputManager.config?.analog?.right?.action)
                knob.handleStick(payload?.x, payload?.y);
            else if (action === "I.PressStick.R")
                knob.mute();
        }
        function onAnalogReset() {
            knob.resetInput();
        }
    }
}
