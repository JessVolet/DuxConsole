import QtQuick

AudioTargetCarousel {
    property var audioService: null
    model: audioService?.applications ?? []
    title: tr("audio.apps", "Application volume")
    zoneId: "audio-app-mixer"
    orientation: Qt.Vertical
    wheel: true
}
