import QtQuick

AudioTargetList {
    property var audioService: null
    model: audioService?.inputs ?? []
    title: tr("audio.inputs", "Input devices")
    zoneId: "audio-inputs"
    iconKind: "input"
}
