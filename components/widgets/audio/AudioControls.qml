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
    property var mediaService: null
    property var inputManager: null
    property var layerManager: null
    property var navigationManager: null
    property var iconsPadManager: null
    property var styleTokens: null
    property var motionTokens: null
    property var i18n: null
    property string layerName: "dashboard"
    property bool mediaTransformActive: false

    readonly property alias mediaCard: mediaCard
    signal mediaExpandRequested()

    readonly property var focusedTarget: layerManager?.activeZone === apps.focusZone ? apps.selectedTarget : layerManager?.activeZone === outputs.focusZone ? outputs.selectedTarget : layerManager?.activeZone === inputs.focusZone ? inputs.selectedTarget : null
    readonly property var focusedWidget: layerManager?.activeZone === apps.focusZone ? apps : layerManager?.activeZone === outputs.focusZone ? outputs : layerManager?.activeZone === inputs.focusZone ? inputs : null
    readonly property var activeOutput: (audioService?.outputs ?? []).find(target => target.active) ?? null
    readonly property var activeInput: (audioService?.inputs ?? []).find(target => target.active) ?? null
    readonly property string summary: {
        const parts = [];
        if (activeOutput)
            parts.push(activeOutput.title + " " + Math.round(activeOutput.volume * 100) + "%");
        if (activeInput)
            parts.push(activeInput.title + " " + Math.round(activeInput.volume * 100) + "%");
        return parts.join(" · ");
    }

    function tr(key, fallback) {
        return i18n ? i18n.t(key, fallback) : fallback;
    }
    function connectWidget(widget) {
        widget.activationRequested.connect(key => audioService?.activate(key));
        widget.volumeRequested.connect((key, value) => audioService?.setVolume(key, value));
        widget.muteRequested.connect((key, muted) => audioService?.setMuted(key, muted));
        widget.optionsRequested.connect((key, source) => options.open(key, source));
    }
    // Mouse twin of LT/RT on the focused carousel.
    function browse(delta) {
        controls.focusedWidget?.focusZone?.cycleSubItem(delta);
    }
    Component.onCompleted: {
        for (const widget of [apps, outputs, inputs])
            connectWidget(widget);
    }

    SectionTitle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacingXL
        anchors.rightMargin: Theme.spacingXL
        title: controls.tr("nav.sound", "Sound")
        subtitle: controls.summary
        titleSize: Theme.fontSizeLarge
        styleTokens: controls.styleTokens
    }

    GridLayout {
        id: layout
        anchors.top: header.bottom
        anchors.topMargin: Theme.spacingM
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.spacingXL
        anchors.rightMargin: Theme.spacingXL
        columns: 3
        columnSpacing: Theme.spacingXL
        rowSpacing: Theme.spacingM

        AudioPanel {
            id: knobPanel
            Layout.row: 0
            Layout.column: 0
            Layout.fillWidth: true
            Layout.preferredWidth: Math.max(300, controls.width * 0.30)
            Layout.preferredHeight: 470
            Layout.alignment: Qt.AlignTop
            styleTokens: controls.styleTokens

            Column {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.spacingM

                AngularVolumeKnob {
                    id: knob
                    width: Math.min(340, controls.width * 0.22)
                    height: width
                    value: controls.focusedTarget?.volume ?? 0
                    maximum: controls.focusedTarget?.maxVolume ?? 1
                    muted: controls.focusedTarget?.muted ?? false
                    targetKey: controls.focusedTarget?.key ?? ""
                    caption: controls.focusedTarget?.title ?? ""
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

                SectionTitle {
                    width: parent.width
                    title: controls.focusedTarget?.title ?? controls.tr("audio.select_target", "Select an audio target")
                    subtitle: controls.audioService?.error ? controls.tr("audio.operation_failed", "Audio operation failed") : controls.tr("audio.knob_hint", "Right stick: volume · R3: mute")
                    role: "card"
                    styleTokens: controls.styleTokens
                }

                Row {
                    spacing: Theme.spacingS

                    ActionPill {
                        glyphAction: "I.PressStick.R"
                        iconsPadManager: controls.iconsPadManager
                        styleTokens: controls.styleTokens
                        text: knob.muted ? controls.tr("audio.unmute", "Unmute") : controls.tr("audio.mute", "Mute")
                        enabled: knob.enabled
                        primary: knob.muted
                        onClicked: knob.mute()
                    }

                    ActionPill {
                        glyphAction: "I.ActionOption.L"
                        iconsPadManager: controls.iconsPadManager
                        styleTokens: controls.styleTokens
                        text: controls.tr("media.prev", "Previous")
                        enabled: controls.focusedWidget !== null
                        onClicked: controls.browse(-1)
                    }

                    ActionPill {
                        glyphAction: "I.ActionOption.R"
                        iconsPadManager: controls.iconsPadManager
                        styleTokens: controls.styleTokens
                        text: controls.tr("media.next", "Next")
                        enabled: controls.focusedWidget !== null
                        onClicked: controls.browse(1)
                    }
                }
            }
        }

        AudioPanel {
            id: mixerPanel
            Layout.row: 0
            Layout.column: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: Math.max(300, controls.width * 0.30)
            styleTokens: controls.styleTokens

            AppVolumeMixer {
                id: apps
                anchors.fill: parent
                audioService: controls.audioService
                layerManager: controls.layerManager
                navigationManager: controls.navigationManager
                iconsPadManager: controls.iconsPadManager
                styleTokens: controls.styleTokens
                motionTokens: controls.motionTokens
                i18n: controls.i18n
                defaultFocus: true
            }
        }

        AudioNowPlaying {
            id: mediaCard
            Layout.row: 1
            Layout.column: 0
            Layout.fillWidth: true
            Layout.preferredWidth: Math.max(300, controls.width * 0.30)
            Layout.preferredHeight: 132
            Layout.alignment: Qt.AlignVCenter
            hiddenVisual: controls.mediaTransformActive
            zoneId: "sound-media"
            layerName: controls.layerName
            mediaService: controls.mediaService
            layerManager: controls.layerManager
            navigationManager: controls.navigationManager
            styleTokens: controls.styleTokens
            motionTokens: controls.motionTokens
            i18n: controls.i18n
            onExpandRequested: controls.mediaExpandRequested()
        }

        AudioPanel {
            id: outputsPanel
            Layout.row: 1
            Layout.column: 1
            Layout.fillWidth: true
            Layout.minimumWidth: 300
            Layout.preferredWidth: Math.max(300, controls.width * 0.30)
            Layout.preferredHeight: 242
            styleTokens: controls.styleTokens

            AudioOutputSelector {
                id: outputs
                anchors.fill: parent
                audioService: controls.audioService
                layerManager: controls.layerManager
                navigationManager: controls.navigationManager
                iconsPadManager: controls.iconsPadManager
                styleTokens: controls.styleTokens
                motionTokens: controls.motionTokens
                i18n: controls.i18n
            }
        }

        AudioPanel {
            id: inputsPanel
            Layout.row: 1
            Layout.column: 2
            Layout.fillWidth: true
            Layout.minimumWidth: 300
            Layout.preferredWidth: Math.max(300, controls.width * 0.30)
            Layout.preferredHeight: 242
            styleTokens: controls.styleTokens

            AudioInputSelector {
                id: inputs
                anchors.fill: parent
                audioService: controls.audioService
                layerManager: controls.layerManager
                navigationManager: controls.navigationManager
                iconsPadManager: controls.iconsPadManager
                styleTokens: controls.styleTokens
                motionTokens: controls.motionTokens
                i18n: controls.i18n
            }
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
