pragma ComponentBehavior: Bound

import QtQuick
import "../../components/widgets"
import "../../core/motion"
import "../../services"

Item {
    id: modal

    property Item sourceItem: null
    property var mediaService: null
    property var layerManager: null
    property var navigationManager: null
    property var iconsPadManager: null
    property var styleTokens: null
    property var motionTokens: null
    property var i18n: null
    property string layerName: "media-player"

    readonly property bool isOpen: layerManager ? layerManager.isLayerActive(layerName) : false
    readonly property bool isPresent: layerManager ? layerManager.stack.indexOf(layerName) >= 0 : false
    readonly property bool transformActive: isPresent || transition.progress > 0

    function ensurePlayerFocus() {
        if (isOpen && transition.contentReady)
            navigationManager?.ensureFocus(layerName)
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(modal.ensurePlayerFocus)
    }

    Connections {
        target: transition
        function onContentReadyChanged() {
            if (transition.contentReady)
                Qt.callLater(modal.ensurePlayerFocus)
        }
    }

    anchors.fill: parent
    visible: transformActive
    z: 100

    CavaService {
        id: cavaService
        active: modal.isOpen && Boolean(modal.mediaService?.isPlaying)
    }

    MouseArea {
        anchors.fill: parent
        enabled: modal.isOpen
        onClicked: modal.layerManager?.pop()
    }

    ContainerTransform {
        id: transition
        sourceItem: modal.sourceItem
        expanded: modal.isPresent
        motionTokens: modal.motionTokens
        horizontalDirection: "left"
        verticalDirection: "up"
        expandedSize: Qt.size(
            Math.min(Math.max(300, modal.width - 48), 980),
            Math.min(Math.max(240, modal.height - 48), 560)
        )

        MediaPlayerExpanded {
            anchors.fill: parent
            enabled: modal.isOpen && transition.contentReady
            contentReady: modal.isOpen && transition.contentReady
            contentOpacity: transition.contentOpacity
            mediaService: modal.mediaService
            cavaBars: cavaService.bars
            layerManager: modal.layerManager
            navigationManager: modal.navigationManager
            iconsPadManager: modal.iconsPadManager
            styleTokens: modal.styleTokens
            motionTokens: modal.motionTokens
            i18n: modal.i18n
            layerName: modal.layerName
            pickerVisible: playerPicker.visible
            onPlayersRequested: source => {
                playerPicker.sourceItem = source
                modal.layerManager?.push(playerPicker.layerName)
            }
        }
    }

    MediaPlayerPicker {
        id: playerPicker
        mediaService: modal.mediaService
        layerManager: modal.layerManager
        navigationManager: modal.navigationManager
        iconsPadManager: modal.iconsPadManager
        styleTokens: modal.styleTokens
        motionTokens: modal.motionTokens
        i18n: modal.i18n
    }
}
