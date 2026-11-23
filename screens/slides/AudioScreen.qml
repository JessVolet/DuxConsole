import QtQuick
import "../../core/shell"
import "../../components/widgets/audio"

ScreenBase {
    id: screen
    screenId: "sound"
    title: tr("nav.sound", "Sound")
    AudioControls {
        anchors.fill: parent
        audioService: screen.audioService
        inputManager: screen.inputManager
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        iconsPadManager: screen.iconsPadManager
        styleTokens: screen.styleTokens
        motionTokens: screen.motionTokens
        i18n: screen.i18n
    }
}
