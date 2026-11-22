pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: carousel

    property int currentIndex: 0
    property var model: 0
    property Component delegate: null
    property var motionTokens: null

    property real cardWidth: 180
    property real cardHeight: 120
    property real selectedWidth: 380
    property real selectedHeight: 156
    property real spacing: 18
    property int visibleCount: 7

    readonly property int count: typeof model === "number" ? model : (model?.length ?? 0)
    readonly property int effectiveItemCount: Math.min(Math.max(1, count), visibleCount)
    readonly property int effectivePositions: Math.max(1, effectiveItemCount - 1)
    readonly property int animDuration: motionTokens ? motionTokens.durationNormal : 220
    readonly property int animEasing: motionTokens ? motionTokens.easingSnappy : Easing.OutCubic
    readonly property real pathSpan: effectivePositions * (cardWidth + spacing)

    implicitHeight: selectedHeight + 16
    clip: true

    PathView {
        id: view
        anchors.fill: parent
        model: carousel.model
        currentIndex: carousel.currentIndex
        pathItemCount: carousel.effectiveItemCount
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        highlightMoveDuration: carousel.animDuration
        interactive: false

        path: Path {
            startX: (view.width - carousel.pathSpan) / 2
            startY: view.height / 2
            PathLine {
                x: (view.width + carousel.pathSpan) / 2
                y: view.height / 2
            }
        }

        delegate: Item {
            id: slot
            required property int index

            readonly property int delta: {
                const n = carousel.count
                if (n <= 0)
                    return 0
                let d = index - carousel.currentIndex
                if (d > n / 2)
                    d -= n
                if (d < -n / 2)
                    d += n
                return d
            }

            readonly property real shiftOffset: (carousel.selectedWidth - carousel.cardWidth) / 2
            property real translateX: delta === 0 ? 0 : (delta < 0 ? -shiftOffset : shiftOffset)

            width: delta === 0 ? carousel.selectedWidth : carousel.cardWidth
            height: delta === 0 ? carousel.selectedHeight : carousel.cardHeight
            z: delta === 0 ? 10 : 1
            opacity: delta === 0 ? 1.0 : 0.72

            transform: Translate {
                x: slot.translateX
            }

            Behavior on width {
                NumberAnimation { duration: carousel.animDuration; easing.type: carousel.animEasing }
            }
            Behavior on height {
                NumberAnimation { duration: carousel.animDuration; easing.type: carousel.animEasing }
            }
            Behavior on opacity {
                NumberAnimation { duration: carousel.animDuration; easing.type: carousel.animEasing }
            }
            Behavior on translateX {
                NumberAnimation { duration: carousel.animDuration; easing.type: carousel.animEasing }
            }

            Loader {
                id: itemLoader
                anchors.fill: parent
                sourceComponent: carousel.delegate

                function syncProps() {
                    if (!item)
                        return
                    if ("index" in item)
                        item.index = slot.index
                }

                onLoaded: syncProps()
            }

            onIndexChanged: itemLoader.syncProps()
        }
    }
}
