import QtQuick

Item {
    id: carousel

    property int currentIndex: 0
    property var model: 0
    property Component delegate: null
    property var motionTokens: null

    property int maxVisibleItems: 6
    property real cardWidth: 180
    property real cardHeight: 120
    property real selectedWidth: 240
    property real selectedHeight: 156
    property real spacing: 18

    readonly property int count: {
        if (typeof model === "number")
            return Math.max(0, Math.floor(model))
        if (Array.isArray(model))
            return model.length
        if (model && typeof model.count === "number")
            return Math.max(0, model.count)
        return 0
    }
    readonly property int visibleItemCount: Math.min(count, Math.max(1, maxVisibleItems))
    readonly property int selectedIndex: count > 0
        ? ((currentIndex % count) + count) % count
        : -1
    readonly property int pathIntervals: Math.max(0, visibleItemCount - 1)
    readonly property real itemStep: (selectedWidth + cardWidth) / 2 + spacing
    readonly property real pathSpan: pathIntervals * itemStep
    readonly property int moveDuration: motionTokens ? motionTokens.durationNormal : 0

    implicitHeight: selectedHeight + 16
    clip: true

    PathView {
        id: view
        anchors.fill: parent
        visible: carousel.count > 0
        model: carousel.model
        delegate: carousel.delegate
        currentIndex: carousel.selectedIndex
        pathItemCount: carousel.visibleItemCount
        cacheItemCount: 0
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        highlightMoveDuration: carousel.moveDuration
        interactive: false

        path: Path {
            startX: (view.width - carousel.pathSpan) / 2
            startY: view.height / 2
            PathLine {
                x: (view.width + carousel.pathSpan) / 2
                y: view.height / 2
            }
        }
    }
}
