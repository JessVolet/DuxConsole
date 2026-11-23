import QtQuick
import "../../core/shell"
import "../../components/widgets/audio"
import "../modals"

ScreenBase {
    id: screen
    screenId: "sound"
    title: tr("nav.sound", "Sound")

    AudioControls {
        id: audioControls
        anchors.fill: parent
        audioService: screen.audioService
        mediaService: screen.mediaService
        inputManager: screen.inputManager
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        iconsPadManager: screen.iconsPadManager
        styleTokens: screen.styleTokens
        motionTokens: screen.motionTokens
        i18n: screen.i18n
        mediaTransformActive: mediaModal.transformActive
        onMediaExpandRequested: screen.layerManager?.push("media-player")
    }

    MediaPlayerModal {
        id: mediaModal
        sourceItem: audioControls.mediaCard
        mediaService: screen.mediaService
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        iconsPadManager: screen.iconsPadManager
        styleTokens: screen.styleTokens
        motionTokens: screen.motionTokens
        i18n: screen.i18n
    }
}
