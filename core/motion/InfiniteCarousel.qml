import QtQuick

Item {
    id: carousel

    property int currentIndex: 0
    property var model: 0
    property Component delegate: null
    property var motionTokens: null
    property int itemWidth: 160
    property int itemSpacing: 16

    readonly property int count: typeof model === "number" ? model : (model?.length ?? 0)
    readonly property int visibleSlots: Math.max(3, Math.floor(width / Math.max(1, itemWidth + itemSpacing)) | 1)

    clip: true

    PathView {
        id: view
        anchors.fill: parent
        model: carousel.model
        delegate: carousel.delegate
        currentIndex: carousel.currentIndex
        pathItemCount: Math.min(Math.max(1, carousel.count), carousel.visibleSlots + 2)
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        highlightMoveDuration: carousel.motionTokens ? carousel.motionTokens.durationNormal : 220
        interactive: false

        path: Path {
            startX: 0
            startY: view.height / 2
            PathLine {
                x: view.width
                y: view.height / 2
            }
        }
    }
}
