import QtQuick
import Quickshell.Io

Item {
    id: sessionService

    property string scene: "home"
    property int selectedWindowId: -1
    property var wheelChoices: ({})
    readonly property var sceneSpec: sceneData.data?.scenes?.[scene] ?? sceneData.data?.scenes?.home ?? ({})
    readonly property var appearance: sceneData.data?.appearance ?? ({})
    readonly property var session: homeData.data?.session ?? ({})
    readonly property var windows: {
        const data = homeData.data ?? ({})
        const entries = (data.windows ?? []).map(entry => Object.assign({}, entry, {
            artwork: entry.artwork ? Qt.resolvedUrl("../fixtures/mockup/" + entry.artwork) : ""
        }))
        const requestedCount = /^home-(\d+)$/.exec(scene)
        if (!requestedCount)
            return entries.slice(0, data.defaultWindowCount ?? entries.length)
        return entries.slice(0, Number(requestedCount[1]))
    }
    readonly property var audio: mediaState.audio
    readonly property var capture: mediaState.capture
    readonly property var track: mediaState.track

    signal notice(string messageKey)

    function resetSelection() {
        const requested = sceneSpec.selectedWindowId ?? homeData.data.initialWindowId
        selectedWindowId = windows.some(entry => entry.id === requested) ? requested : (windows[0]?.id ?? -1)
    }

    onSceneChanged: {
        wheelChoices = ({})
        resetSelection()
    }
    onWindowsChanged: resetSelection()
    Component.onCompleted: resetSelection()

    function wheelLevel(id) {
        if (id === "brightness-level")
            return wheelSelection(id) ?? -1

        const output = id === "volume-level"
        if (!output && id !== "microphone-level")
            return -1

        const devices = output ? audio.outputs : audio.inputs
        const selectedId = output ? audio.selectedOutput : audio.selectedInput
        const device = devices?.find(entry => entry.id === selectedId)
        return device ? (device.muted ? 0 : device.level) : -1
    }

    function wheelSelection(id) {
        return wheelChoices[id] ?? sceneData.data?.defaults?.[id] ?? null
    }

    function wheelValue(id) {
        const value = wheelChoices[id]
        return typeof value === "number" ? value + "%" : ""
    }

    function dispatchWheel(id, value) {
        const aliases = {
            "capture-screenshot": "capture.screenshot",
            "capture-record": "capture.record",
            "capture-replay": "capture.replay",
            "media-toggle": "media.play",
            "media-previous": "media.previous",
            "media-next": "media.next"
        }
        if (aliases[id] && mediaState?.dispatch(aliases[id], {}))
            return
        if (id === "volume-level" || id === "microphone-level") {
            const group = id === "volume-level" ? "outputs" : "inputs"
            const deviceId = group === "outputs" ? audio.selectedOutput : audio.selectedInput
            const device = audio[group]?.find(entry => entry.id === deviceId)
            if (device && typeof value === "number") {
                mediaState?.dispatch("audio.adjust", { group, id: deviceId, delta: value - device.level })
                wheelChoices = Object.assign({}, wheelChoices, { [id]: value })
                return
            }
        }
        wheelChoices = Object.assign({}, wheelChoices, { [id]: value })
        notice("mockup.simulated")
    }

    function dispatch(action, payload) {
        if (action === "window.select") {
            if (!windows.some(entry => entry.id === payload?.id))
                return { status: "unavailable" }
            selectedWindowId = payload.id
            return { status: "success" }
        }
        if (action === "window.focus" && !windows.some(entry => entry.id === payload?.id))
            return { status: "unavailable" }

        if (mediaState?.dispatch(action, payload))
            return { status: "success" }

        switch (action) {
        case "session.resume":
        case "window.focus":
        case "launch-entry":
            notice("mockup.simulated")
            return { status: "success", messageKey: "mockup.simulated" }
        case "wheel-command":
            if (!payload?.id)
                return { status: "unavailable" }
            dispatchWheel(payload.id, payload.value)
            return { status: "success" }
        default:
            return { status: "unavailable" }
        }
    }

    FileView {
        id: sceneData
        path: Qt.resolvedUrl("../fixtures/mockup/scenes.json").toString().replace("file://", "")
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        property var data: ({})
        onLoaded: {
            try {
                data = JSON.parse(text())
            } catch (error) {
                console.warn("DuxConsole fixture JSON:", path, error)
                data = ({})
            }
        }
    }

    FileView {
        id: homeData
        path: Qt.resolvedUrl("../fixtures/mockup/home.json").toString().replace("file://", "")
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        property var data: ({})
        onLoaded: {
            try {
                data = JSON.parse(text())
            } catch (error) {
                console.warn("DuxConsole fixture JSON:", path, error)
                data = ({})
            }
        }
    }

    MockMediaState {
        id: mediaState
        scene: sessionService.scene
        onNotice: messageKey => sessionService.notice(messageKey)
    }
}
