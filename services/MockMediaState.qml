import QtQuick
import Quickshell.Io

Item {
    id: mediaState

    property string scene: ""
    property var audio: ({ outputs: [], inputs: [], channels: [], selectedOutput: "", selectedInput: "" })
    property var capture: ({ items: [], recording: false, elapsed: 0, replayEnabled: false, microphone: true })
    property var playlist: []
    property int trackIndex: 0
    property var track: null
    property int nextCaptureId: 0
    property var captureTemplates: []
    signal notice(string key)

    visible: false

    function asset(path) {
        return path ? Qt.resolvedUrl("../fixtures/mockup/" + path).toString() : ""
    }

    function loadAudio(data) {
        const unavailable = mediaState.scene === "audio-unavailable"
        mediaState.audio = {
            outputs: unavailable ? [] : data.outputs,
            inputs: unavailable ? [] : data.inputs,
            channels: unavailable ? [] : data.channels,
            selectedOutput: unavailable ? "" : data.selectedOutput,
            selectedInput: unavailable ? "" : data.selectedInput
        }
        mediaState.playlist = unavailable ? [] : (data.playlist ?? []).map(entry => Object.assign({}, entry, {
            artwork: mediaState.asset(entry.artwork)
        }))
        mediaState.trackIndex = 0
        mediaState.track = mediaState.playlist[0] ?? null
    }

    function loadCapture(data) {
        mediaState.captureTemplates = data.items.map(item => Object.assign({}, item, {
            artwork: mediaState.asset(item.artwork),
            source: mediaState.asset(item.source)
        }))
        mediaState.capture = Object.assign({}, data, {
            items: mediaState.scene === "capture-empty" ? [] : mediaState.captureTemplates,
            recording: mediaState.scene === "capture-recording"
        })
        mediaState.nextCaptureId = 0
    }

    function updateCapture(patch) {
        mediaState.capture = Object.assign({}, mediaState.capture, patch)
    }

    function setDevice(group, id) {
        const propertyName = group === "outputs" ? "selectedOutput" : "selectedInput"
        if (!mediaState.audio[group].some(device => device.id === id))
            return
        mediaState.audio = Object.assign({}, mediaState.audio, { [propertyName]: id })
    }

    function updateLevel(action, data) {
        const group = data.group
        if (!["outputs", "inputs", "channels"].includes(group))
            return
        const delta = Number(data.delta)
        if (action === "audio.adjust" && !Number.isFinite(delta))
            return
        const values = mediaState.audio[group].map(entry => {
            if (entry.id !== data.id)
                return entry
            if (action === "audio.mute")
                return Object.assign({}, entry, { muted: !entry.muted })
            return Object.assign({}, entry, { level: Math.max(0, Math.min(100, entry.level + delta)) })
        })
        mediaState.audio = Object.assign({}, mediaState.audio, { [group]: values })
    }

    function appendCapture(kind, duration) {
        const template = mediaState.captureTemplates.find(item => item.kind === kind)
        const entry = {
            id: "mock-capture-" + (++mediaState.nextCaptureId),
            kind: kind,
            titleKey: kind === "video" ? "mockup.capture.recordingItem" : "mockup.capture.imageItem",
            artwork: template?.artwork ?? "",
            source: template?.source ?? "",
            duration: duration
        }
        mediaState.updateCapture({items: mediaState.capture.items.concat([entry])})
        mediaState.notice(kind === "video" ? "mockup.capture.savedVideo" : "mockup.capture.savedImage")
    }

    function dispatch(action, payload) {
        const data = payload ?? {}
        switch (action) {
        case "audio.output":
            mediaState.setDevice("outputs", data.id)
            return true
        case "audio.input":
            mediaState.setDevice("inputs", data.id)
            return true
        case "audio.adjust":
        case "audio.mute":
            mediaState.updateLevel(action, data)
            return true
        case "capture.screenshot":
            mediaState.appendCapture("image", 0)
            return true
        case "capture.record":
            if (mediaState.capture.recording)
                mediaState.appendCapture("video", Math.max(1, mediaState.capture.elapsed))
            mediaState.updateCapture({ recording: !mediaState.capture.recording, elapsed: 0 })
            return true
        case "capture.replay":
            if (mediaState.capture.replayEnabled)
                mediaState.appendCapture("video", 30)
            else
                mediaState.notice("mockup.capture.bufferDisabled")
            return true
        case "capture.buffer":
            mediaState.updateCapture({ replayEnabled: !mediaState.capture.replayEnabled })
            return true
        case "capture.microphone":
            mediaState.updateCapture({ microphone: !mediaState.capture.microphone })
            return true
        case "media.play":
            if (mediaState.track) {
                const position = mediaState.track.position >= mediaState.track.duration ? 0 : mediaState.track.position
                mediaState.track = Object.assign({}, mediaState.track, { playing: !mediaState.track.playing, position: position })
            }
            return true
        case "media.previous":
        case "media.next":
            if (mediaState.playlist.length > 0) {
                const delta = action === "media.previous" ? -1 : 1
                const count = mediaState.playlist.length
                mediaState.trackIndex = (mediaState.trackIndex + delta + count) % count
                mediaState.track = Object.assign({}, mediaState.playlist[mediaState.trackIndex], {
                    playing: mediaState.track?.playing ?? false,
                    position: 0
                })
            }
            return true
        case "media.seek":
            if (mediaState.track && Number.isFinite(data.position))
                mediaState.track = Object.assign({}, mediaState.track, { position: Math.max(0, Math.min(mediaState.track.duration, data.position)) })
            return true
        default:
            return false
        }
    }

    onSceneChanged: {
        if (audioData.loaded)
            mediaState.loadAudio(JSON.parse(audioData.text()))
        if (captureData.loaded)
            mediaState.loadCapture(JSON.parse(captureData.text()))
    }

    FileView {
        id: audioData
        path: Qt.resolvedUrl("../fixtures/mockup/audio.json").toString().replace("file://", "")
        blockLoading: true
        onLoaded: mediaState.loadAudio(JSON.parse(text()))
    }

    FileView {
        id: captureData
        path: Qt.resolvedUrl("../fixtures/mockup/capture.json").toString().replace("file://", "")
        blockLoading: true
        onLoaded: mediaState.loadCapture(JSON.parse(text()))
    }

    Timer {
        interval: 1000
        repeat: true
        running: mediaState.track?.playing || mediaState.capture.recording
        onTriggered: {
            if (mediaState.track?.playing) {
                const position = Math.min(mediaState.track.duration, mediaState.track.position + 1)
                mediaState.track = Object.assign({}, mediaState.track, { position: position, playing: position < mediaState.track.duration })
            }
            if (mediaState.capture.recording)
                mediaState.updateCapture({ elapsed: mediaState.capture.elapsed + 1 })
        }
    }
}
