import QtQuick
import qs.Common

Rectangle {
    id: ring

    property var targetZone: null
    property Item coordinateSpace: parent

    color: "transparent"
    border.width: 2
    border.color: Theme.primary
    radius: targetZone?.ringRadius ?? Theme.cornerRadius

    opacity: (targetZone && targetZone.visible && !targetZone.inert && width > 0 && height > 0) ? 1.0 : 0.0
    visible: opacity > 0.01

    function syncGeometry() {
        if (!targetZone || !coordinateSpace)
            return

        const pad = targetZone.ringPadding ?? 0
        const rect = targetZone.mapToItem(
            coordinateSpace,
            -pad,
            -pad,
            targetZone.width + pad * 2,
            targetZone.height + pad * 2
        )

        x = rect.x
        y = rect.y
        width = rect.width
        height = rect.height
    }

    onTargetZoneChanged: syncGeometry()
    onCoordinateSpaceChanged: syncGeometry()

    Connections {
        target: ring.targetZone ?? null
        function onXChanged() { ring.syncGeometry() }
        function onYChanged() { ring.syncGeometry() }
        function onWidthChanged() { ring.syncGeometry() }
        function onHeightChanged() { ring.syncGeometry() }
        function onVisibleChanged() { ring.syncGeometry() }
    }

    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on radius { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
}
