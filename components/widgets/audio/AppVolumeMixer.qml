import QtQuick

AudioTargetList {
    property var audioService: null
    model: audioService?.applications ?? []
    title: tr("audio.apps", "Application volume")
    zoneId: "audio-app-mixer"
    iconKind: "app"
}
