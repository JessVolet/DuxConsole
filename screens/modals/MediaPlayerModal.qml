pragma ComponentBehavior: Bound

import QtQuick
import "../../components/widgets"
import "../../services"

Item {
    id: modal

    property var mediaService: null
    property var layerManager: null
    property var navigationManager: null
    property var iconsPadManager: null
    property var styleTokens: null
    property var motionTokens: null
    property var i18n: null
    property string layerName: "media-player"

    readonly property bool isOpen: layerManager ? layerManager.isLayerActive(layerName) : false
    readonly property int fadeDuration: motionTokens
        ? (isOpen ? motionTokens.fadeInDuration : motionTokens.fadeOutDuration)
        : 160

    anchors.fill: parent
    visible: isOpen || opacity > 0.01
    opacity: isOpen ? 1 : 0
    z: 100

    Behavior on opacity {
        NumberAnimation {
            duration: modal.fadeDuration
            easing.type: modal.motionTokens ? modal.motionTokens.easingSnappy : Easing.OutCubic
        }
    }

    CavaService {
        id: cavaService
        active: modal.isOpen && Boolean(modal.mediaService?.isPlaying)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: modal.layerManager?.pop()
    }

    MediaPlayerExpanded {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.88, 980)
        height: Math.min(parent.height * 0.82, 560)
        mediaService: modal.mediaService
        cavaBars: cavaService.bars
        layerManager: modal.layerManager
        navigationManager: modal.navigationManager
        iconsPadManager: modal.iconsPadManager
        styleTokens: modal.styleTokens
        motionTokens: modal.motionTokens
        i18n: modal.i18n
        layerName: modal.layerName
    }
}
