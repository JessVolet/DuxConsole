pragma ComponentBehavior: Bound
import QtQuick
import "ContainerGeometry.js" as Geometry

Item {
    id: transform
    property Item sourceItem: null
    property Item targetItem: null
    property var motionTokens: null
    property bool expanded: false
    property rect sourceRect: Qt.rect(0, 0, 0, 0)
    property rect explicitTargetRect: Qt.rect(0, 0, -1, -1)
    readonly property var config: motionTokens ? motionTokens.containerTransform : ({})
    property size expandedSize: Qt.size(config.width ?? 640, config.height ?? 420)
    property string horizontalDirection: config.horizontalDirection ?? "auto"
    property string verticalDirection: config.verticalDirection ?? "auto"
    property real edgeMargin: config.edgeMargin ?? 24
    property point sourceAnchor: Qt.point(config.anchorX ?? 0.5, config.anchorY ?? 0.5)
    property bool _originActive: false
    property rect bounds: Qt.rect(edgeMargin, edgeMargin,
        Math.max(0, (parent ? parent.width : 0) - 2 * edgeMargin),
        Math.max(0, (parent ? parent.height : 0) - 2 * edgeMargin))
    property real progress: expanded ? 1 : 0
    readonly property rect targetRect: Geometry.destination(sourceRect, bounds,
        expandedSize, horizontalDirection, verticalDirection, explicitTargetRect)
    readonly property point anchorOffset: Qt.point(
        sourceRect.x + sourceRect.width * sourceAnchor.x - x,
        sourceRect.y + sourceRect.height * sourceAnchor.y - y)
    readonly property bool running: animation.running
    readonly property bool contentReady: expanded && !running && progress === 1
    readonly property real contentOpacity: Math.max(0, (progress - 0.75) / 0.25)
    signal originCaptured()
    signal destinationCaptured()

    function captureOrigin() {
        if (!sourceItem || !parent)
            return false
        sourceRect = sourceItem.mapToItem(parent, 0, 0, sourceItem.width, sourceItem.height)
        originCaptured()
        return true
    }

    function captureDestination() {
        if (!targetItem || !parent) {
            explicitTargetRect = Qt.rect(0, 0, -1, -1)
            return false
        }
        explicitTargetRect = targetItem.mapToItem(parent, 0, 0, targetItem.width, targetItem.height)
        destinationCaptured()
        return true
    }

    onTargetItemChanged: captureDestination()
    onParentChanged: {
        if (targetItem)
            captureDestination()
    }
    Connections {
        target: transform.parent
        function onWidthChanged() {
            if (transform.targetItem)
                transform.captureDestination()
        }
        function onHeightChanged() {
            if (transform.targetItem)
                transform.captureDestination()
        }
    }
    Connections {
        target: transform.targetItem
        function onXChanged() { transform.captureDestination() }
        function onYChanged() { transform.captureDestination() }
        function onWidthChanged() { transform.captureDestination() }
        function onHeightChanged() { transform.captureDestination() }
    }

    onExpandedChanged: {
        if (expanded && !_originActive) {
            captureOrigin()
            _originActive = true
        }
        if (targetItem)
            captureDestination()
    }
    onProgressChanged: {
        if (!expanded && progress === 0)
            _originActive = false
    }
    Component.onCompleted: {
        if (sourceItem)
            captureOrigin()
        if (targetItem)
            captureDestination()
    }

    x: sourceRect.x + (targetRect.x - sourceRect.x) * progress
    y: sourceRect.y + (targetRect.y - sourceRect.y) * progress
    width: sourceRect.width + (targetRect.width - sourceRect.width) * progress
    height: sourceRect.height + (targetRect.height - sourceRect.height) * progress
    visible: expanded || progress > 0

    Behavior on progress {
        NumberAnimation {
            id: animation
            duration: transform.motionTokens ? transform.motionTokens.containerTransformDuration : 0
            easing.type: transform.motionTokens ? transform.motionTokens.containerTransformEasing : Easing.OutCubic
        }
    }
}
