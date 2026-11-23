import QtQuick
import qs.Common
import "../../core/shell"
import "../../core/interaction"
import "../../components/primitives/meters"
import "../../components/primitives/text"
import "../../components/widgets"
import "../modals"

ScreenBase {
    id: screen

    screenId: "mock-audio"
    title: tr("mockup.nav.audio", "Sound")

    readonly property var audioState: mockSession?.audio ?? null
    readonly property var channel: audioState?.channels?.[mixerZone.currentSubIndex] ?? null
    readonly property var output: audioState?.outputs?.find(device => device.id === audioState.selectedOutput) ?? null
    readonly property var input: audioState?.inputs?.find(device => device.id === audioState.selectedInput) ?? null
    readonly property var controlsTarget: controlsGroup === "channels" ? channel : (controlsGroup === "inputs" ? input : output)
    property string controlsGroup: "outputs"
    readonly property string controlsLabel: controlsGroup === "outputs" ? tr("mockup.audio.output", "Audio output") : (controlsTarget?.name ?? tr(controlsTarget?.labelKey ?? "", ""))
    readonly property var options: [
        { label: controlsTarget?.muted ? tr("mockup.audio.unmute", "Unmute") : tr("mockup.audio.mute", "Mute"), glyph: "I.Accept" },
        { label: tr("mockup.audio.lower", "Lower"), glyph: "I.ActionOption.L" },
        { label: tr("mockup.audio.raise", "Raise"), glyph: "I.ActionOption.R" }
    ]
    property bool fixtureOpened: false

    function dispatch(action, data) {
        mockSession?.dispatch(action, data ?? {})
    }

    function volumeAction(index) {
        if (!controlsTarget)
            return
        dispatch(index === 0 ? "audio.mute" : "audio.adjust", {
            group: controlsGroup,
            id: controlsTarget.id,
            delta: index === 1 ? -5 : 5
        })
    }

    Timer {
        id: fixtureOpening
        interval: 0
        onTriggered: screen.openFixture()
    }

    function openFixture() {
        if (!fixtureOpened && mockSession?.scene === "audio-expanded" && layerManager?.topLayer === "dashboard") {
            fixtureOpened = true
            layerManager.push("mock-media")
        }
    }

    onMockSessionChanged: fixtureOpening.restart()

    onOutputChanged: {
        const index = audioState?.outputs?.findIndex(device => device.id === output?.id) ?? -1
        if (index >= 0 && outputZone.currentSubIndex !== index)
            outputZone.currentSubIndex = index
    }

    onInputChanged: {
        const index = audioState?.inputs?.findIndex(device => device.id === input?.id) ?? -1
        if (index >= 0 && inputZone.currentSubIndex !== index)
            inputZone.currentSubIndex = index
    }

    SectionTitle {
        id: heading

        x: parent.width * 0.03
        width: parent.width - x
        titleSize: Theme.fontSizeXXLarge
        title: screen.title
        subtitle: screen.output?.name ?? screen.tr("mockup.audio.noDevices", "No devices")
        styleTokens: screen.styleTokens
    }

    ValueMeter {
        x: parent.width * 0.067
        y: parent.height * 0.16
        width: Math.min(parent.width * 0.20, parent.height * 0.30, 218)
        height: width
        radial: true
        unit: "%"
        label: screen.controlsLabel
        value: screen.controlsTarget?.muted ? 0 : (screen.controlsTarget?.level ?? 0)
        styleTokens: screen.styleTokens
        motionTokens: screen.motionTokens
    }

    FocusZone {
        id: controlsZone

        x: parent.width * 0.01
        y: parent.height * 0.59
        width: parent.width * 0.56
        height: Math.min(112, parent.height * 0.20)
        zoneId: "mock-audio-level"
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        showFocusRing: false
        navRight: mixerZone
        navDown: outputZone
        enabled: Boolean(screen.controlsTarget)
        subItemCount: screen.options.length
        onActivated: index => screen.volumeAction(index)

        SectionTitle {
            width: parent.width
            title: screen.controlsLabel
            styleTokens: screen.styleTokens
        }

        ControlStrip {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Theme.spacingXL * 2
            entries: screen.options
            styleTokens: screen.styleTokens
            motionTokens: screen.motionTokens
            iconsPadManager: screen.iconsPadManager
            interactive: !controlsZone.inert
            focusedIndex: controlsZone.active ? controlsZone.currentSubIndex : -1
            onInvoked: index => {
                if (controlsZone.requestZoneFocus()) {
                    controlsZone.currentSubIndex = index
                    screen.volumeAction(index)
                }
            }
        }
    }

    FocusZone {
        id: mixerZone

        x: parent.width * 0.80
        width: parent.width * 0.20
        y: parent.height * 0.12
        height: parent.height * 0.60
        zoneId: "mock-audio-mixer"
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        showFocusRing: false
        navLeft: controlsZone
        navDown: inputZone
        enabled: subItemCount > 0
        subItemCount: screen.audioState?.channels?.length ?? 0
        currentSubIndex: subItemCount > 2 ? 2 : 0
        onActiveChanged: {
            if (active)
                screen.controlsGroup = "channels"
        }
        onActivated: screen.volumeAction(0)
        onSecondaryTriggered: screen.volumeAction(0)
        actionHints: [
            { action: "I.Accept", labelKey: "mockup.audio.mute", fallback: "Mute" },
            { action: "I.ActionOption.L", labelKey: "hints.cycle", fallback: "Cycle" },
            { action: "I.ActionOption.R", labelKey: "hints.cycle", fallback: "Cycle" }
        ]

        AudioMixer {
            anchors.fill: parent
            channels: screen.audioState?.channels ?? []
            currentIndex: mixerZone.currentSubIndex
            focused: mixerZone.active
            interactive: !mixerZone.inert
            i18n: screen.i18n
            styleTokens: screen.styleTokens
            motionTokens: screen.motionTokens
            onChannelRequested: index => {
                if (mixerZone.requestZoneFocus())
                    mixerZone.currentSubIndex = index
            }
        }
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spacingM
        height: Math.min(170, parent.height * 0.22)
        spacing: Theme.spacingXL

        FocusZone {
            id: playerZone

            width: (parent.width - parent.spacing * 2) / 3
            height: parent.height * 0.88
            zoneId: "mock-audio-media"
            layerManager: screen.layerManager
            navigationManager: screen.navigationManager
            showFocusRing: false
            navUp: controlsZone
            navRight: outputZone
            expandable: Boolean(screen.mockSession?.track)
            enabled: expandable
            onActivated: screen.dispatch("media.play")
            onExpandRequested: screen.layerManager?.push("mock-media")
            actionHints: [
                { action: "I.Accept", labelKey: "mockup.media.playPause", fallback: "Play / Pause" },
                { action: "I.Select", labelKey: "hints.expand", fallback: "Expand" }
            ]

            DemoMediaPlayer {
                anchors.fill: parent
                track: screen.mockSession?.track ?? null
                i18n: screen.i18n
                styleTokens: screen.styleTokens
                motionTokens: screen.motionTokens
                interactive: !playerZone.inert
                focused: playerZone.active
                onExpandRequested: {
                    if (playerZone.requestZoneFocus())
                        playerZone.requestExpand()
                }
            }
        }

        FocusZone {
            id: outputZone

            width: playerZone.width
            height: parent.height
            zoneId: "mock-audio-outputs"
            layerManager: screen.layerManager
            navigationManager: screen.navigationManager
            defaultFocus: true
            enabled: subItemCount > 0
            subItemCount: screen.audioState?.outputs?.length ?? 0
            showFocusRing: false
            navUp: controlsZone
            navLeft: playerZone
            navRight: inputZone
            onActiveChanged: {
                if (active)
                    screen.controlsGroup = "outputs"
            }
            onActivated: index => screen.dispatch("audio.output", { id: screen.audioState?.outputs?.[index]?.id })
            onSubItemCycled: index => screen.dispatch("audio.output", { id: screen.audioState?.outputs?.[index]?.id })
            actionHints: [
                { action: "I.ActionOption.L", labelKey: "mockup.audio.change", fallback: "Change device" },
                { action: "I.ActionOption.R", labelKey: "mockup.audio.change", fallback: "Change device" }
            ]

            DeviceStrip {
                anchors.fill: parent
                devices: screen.audioState?.outputs ?? []
                selectedId: screen.audioState?.selectedOutput ?? ""
                currentIndex: outputZone.currentSubIndex
                focused: outputZone.active
                interactive: !outputZone.inert
                title: screen.tr("mockup.audio.speakers", "Speakers")
                i18n: screen.i18n
                styleTokens: screen.styleTokens
                motionTokens: screen.motionTokens
                onDeviceRequested: index => {
                    if (outputZone.requestZoneFocus()) {
                        outputZone.currentSubIndex = index
                        outputZone.activate()
                    }
                }
            }
        }

        FocusZone {
            id: inputZone

            width: playerZone.width
            height: parent.height
            zoneId: "mock-audio-inputs"
            layerManager: screen.layerManager
            navigationManager: screen.navigationManager
            enabled: subItemCount > 0
            subItemCount: screen.audioState?.inputs?.length ?? 0
            showFocusRing: false
            navUp: controlsZone
            navLeft: outputZone
            onActiveChanged: {
                if (active)
                    screen.controlsGroup = "inputs"
            }
            onActivated: index => screen.dispatch("audio.input", { id: screen.audioState?.inputs?.[index]?.id })
            onSubItemCycled: index => screen.dispatch("audio.input", { id: screen.audioState?.inputs?.[index]?.id })
            actionHints: outputZone.actionHints

            DeviceStrip {
                anchors.fill: parent
                devices: screen.audioState?.inputs ?? []
                selectedId: screen.audioState?.selectedInput ?? ""
                currentIndex: inputZone.currentSubIndex
                focused: inputZone.active
                interactive: !inputZone.inert
                title: screen.tr("mockup.audio.microphones", "Microphones")
                i18n: screen.i18n
                styleTokens: screen.styleTokens
                motionTokens: screen.motionTokens
                onDeviceRequested: index => {
                    if (inputZone.requestZoneFocus()) {
                        inputZone.currentSubIndex = index
                        inputZone.activate()
                    }
                }
            }
        }
    }

    MediaDetailModal {
        anchors.fill: parent
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        track: screen.mockSession?.track ?? null
        i18n: screen.i18n
        styleTokens: screen.styleTokens
        motionTokens: screen.motionTokens
        iconsPadManager: screen.iconsPadManager
        onPlayRequested: screen.dispatch("media.play")
        onSeekRequested: position => screen.dispatch("media.seek", { position })
    }
}
