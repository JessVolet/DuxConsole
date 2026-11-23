pragma ComponentBehavior: Bound

import QtQuick
import "../../components/primitives/buttons"
import "../../components/primitives/surfaces"
import "../../components/widgets"

Item {
    id: modal

    property Item sourceItem: null
    property var windowManager: null
    property var layerManager: null
    property var navigationManager: null
    property var styleTokens: null
    property var motionTokens: null
    property var iconsPadManager: null
    property var i18n: null
    property string layerName: "modal"
    property int targetWindowId: -1

    readonly property bool isOpen: layerManager ? layerManager.isLayerActive(layerName) : false
    readonly property bool transformActive: isOpen || transition.progress > 0
    readonly property real targetWidth: Math.min(Math.max(240, modal.width - 48), 440)
    readonly property real targetContentWidth: Math.max(120, targetWidth - transition.contentPadding * 2 - 48)

    function ensureOptionsFocus() {
        if (isOpen && transition.contentReady)
            navigationManager?.ensureFocus(layerName)
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(modal.ensureOptionsFocus)
    }

    Connections {
        target: transition
        function onContentReadyChanged() {
            if (transition.contentReady)
                Qt.callLater(modal.ensureOptionsFocus)
        }
    }

    anchors.fill: parent
    visible: transformActive
    z: 150

    MouseArea {
        anchors.fill: parent
        enabled: modal.isOpen
        onClicked: modal.layerManager?.pop()
    }

    TransformSurface {
        id: transition
        sourceItem: modal.sourceItem
        expanded: modal.isOpen
        motionTokens: modal.motionTokens
        styleTokens: modal.styleTokens
        shape: "slanted"
        expandedSize: Qt.size(
            modal.targetWidth,
            Math.min(Math.max(160, modal.height - 48), Math.max(180, actionsPanel.implicitHeight + transition.contentPadding * 2 + 16))
        )
        originContentSize: Qt.size(
            modal.sourceItem ? modal.sourceItem.width : 44,
            modal.sourceItem ? modal.sourceItem.height : 36
        )
        originContent: Component {
            ActionPill {
                glyphAction: "I.Refuse"
                iconsPadManager: modal.iconsPadManager
                styleTokens: modal.styleTokens
                enabled: modal.isOpen
                onClicked: modal.layerManager?.pop()
            }
        }

        WindowActionsPanel {
            id: actionsPanel
            width: modal.targetContentWidth
            opacity: transition.contentOpacity
            windowManager: modal.windowManager
            layerManager: modal.layerManager
            navigationManager: modal.navigationManager
            styleTokens: modal.styleTokens
            motionTokens: modal.motionTokens
            i18n: modal.i18n
            layerName: modal.layerName
            targetWindowId: modal.targetWindowId
            open: modal.isOpen
            contentReady: transition.contentReady
        }
    }
}
