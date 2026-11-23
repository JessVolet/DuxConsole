pragma ComponentBehavior: Bound

import QtQuick
import "../primitives/buttons"

Item {
    id: anchor

    property Item targetItem: null
    property var iconsPadManager: null
    property var styleTokens: null
    property string glyphAction: "I.Options"
    property bool hidden: false
    property real edgePadding: 8

    property bool _syncScheduled: false
    property bool _syncing: false

    readonly property alias buttonItem: actionPill

    signal triggered()

    function scheduleSync() {
        if (_syncScheduled || _syncing)
            return
        _syncScheduled = true
        Qt.callLater(_runSync)
    }

    function _runSync() {
        _syncScheduled = false
        syncPosition()
    }

    function syncPosition() {
        if (_syncing || !targetItem || !parent)
            return
        _syncing = true
        const mapped = targetItem.mapToItem(parent, 0, 0, targetItem.width, targetItem.height)
        const maxX = Math.max(edgePadding, parent.width - width - edgePadding)
        const maxY = Math.max(edgePadding, parent.height - height - edgePadding)
        const nextX = Math.max(edgePadding, Math.min(maxX, mapped.x + mapped.width - width * 0.65))
        const nextY = Math.max(edgePadding, Math.min(maxY, mapped.y - height * 0.35))
        if (Math.abs(x - nextX) > 0.5)
            x = nextX
        if (Math.abs(y - nextY) > 0.5)
            y = nextY
        _syncing = false
    }

    implicitWidth: actionPill.implicitWidth
    implicitHeight: actionPill.implicitHeight
    width: implicitWidth
    height: implicitHeight
    visible: targetItem !== null && !hidden
    z: 20

    onTargetItemChanged: scheduleSync()
    onParentChanged: scheduleSync()

    Connections {
        target: anchor.targetItem
        function onXChanged() { anchor.scheduleSync() }
        function onYChanged() { anchor.scheduleSync() }
        function onWidthChanged() { anchor.scheduleSync() }
        function onHeightChanged() { anchor.scheduleSync() }
    }

    Connections {
        target: anchor.parent
        function onWidthChanged() { anchor.scheduleSync() }
        function onHeightChanged() { anchor.scheduleSync() }
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
