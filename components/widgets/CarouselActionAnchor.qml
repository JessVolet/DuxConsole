pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../primitives/buttons"

Item {
    id: anchor

    property Item targetItem: null
    property var iconsPadManager: null
    property var styleTokens: null
    property string glyphAction: "I.Options"
    property bool hidden: false
    property real edgePadding: 8

    readonly property alias buttonItem: actionPill

    signal triggered()

    function syncPosition() {
        if (!targetItem || !parent)
            return
        const mapped = targetItem.mapToItem(parent, 0, 0, targetItem.width, targetItem.height)
        const maxX = Math.max(edgePadding, parent.width - width - edgePadding)
        const maxY = Math.max(edgePadding, parent.height - height - edgePadding)
        x = Math.max(edgePadding, Math.min(maxX, mapped.x + mapped.width - width * 0.65))
        y = Math.max(edgePadding, Math.min(maxY, mapped.y - height * 0.35))
    }

    implicitWidth: actionPill.implicitWidth
    implicitHeight: actionPill.implicitHeight
    width: implicitWidth
    height: implicitHeight
    visible: targetItem !== null && !hidden
    z: 20

    onTargetItemChanged: Qt.callLater(syncPosition)
    onParentChanged: Qt.callLater(syncPosition)

    Connections {
        target: anchor.targetItem
        function onXChanged() { anchor.syncPosition() }
        function onYChanged() { anchor.syncPosition() }
        function onWidthChanged() { anchor.syncPosition() }
        function onHeightChanged() { anchor.syncPosition() }
    }

    Connections {
        target: anchor.parent
        function onWidthChanged() { anchor.syncPosition() }
        function onHeightChanged() { anchor.syncPosition() }
    }

    ActionPill {
        id: actionPill
        anchors.fill: parent
        glyphAction: anchor.glyphAction
        iconsPadManager: anchor.iconsPadManager
        styleTokens: anchor.styleTokens
        enabled: anchor.enabled && !anchor.hidden
        onClicked: anchor.triggered()
    }
}
