import QtQuick

AudioTargetList {
    property var audioService: null
    model: audioService?.outputs ?? []
    title: tr("audio.outputs", "Output devices")
    zoneId: "audio-outputs"
    iconKind: "output"
}
