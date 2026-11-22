import QtQuick
import qs.Common

Rectangle {
    id: ring

    property var targetZone: null
    property Item coordinateSpace: parent
    property var motionTokens: null
    property var styleTokens: null

    readonly property int animDuration: motionTokens ? motionTokens.durationFast : 120
    readonly property int animEasing: motionTokens ? motionTokens.easingSnappy : Easing.OutCubic

    color: "transparent"
    border.width: 2
    border.color: styleTokens ? styleTokens.accentColor : Theme.primary
    radius: targetZone?.ringRadius ?? Theme.cornerRadius

    opacity: (targetZone && targetZone.showFocusRing && targetZone.visible && !targetZone.inert && width > 0 && height > 0) ? 1.0 : 0.0
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

    Behavior on x { NumberAnimation { duration: ring.animDuration; easing.type: ring.animEasing } }
    Behavior on y { NumberAnimation { duration: ring.animDuration; easing.type: ring.animEasing } }
    Behavior on width { NumberAnimation { duration: ring.animDuration; easing.type: ring.animEasing } }
    Behavior on height { NumberAnimation { duration: ring.animDuration; easing.type: ring.animEasing } }
    Behavior on radius { NumberAnimation { duration: ring.animDuration; easing.type: ring.animEasing } }
    Behavior on opacity { NumberAnimation { duration: ring.animDuration; easing.type: ring.animEasing } }
}
