pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: carousel

    property int currentIndex: 0
    property var model: 0
    property Component delegate: null
    property var motionTokens: null
    property bool focused: false
    property int orientation: Qt.Horizontal
    readonly property bool vertical: orientation === Qt.Vertical

    property int maxVisibleItems: 6
    property int leftCount: -1
    property int rightCount: -1
    property bool alignLeft: false
    property int maxCachedItems: 2
    property real cardWidth: 180
    property real cardHeight: 120
    property real selectedWidth: 300
    property real selectedHeight: 156
    property real spacing: 24
    property real sideScale: 0.92

    readonly property int count: {
        if (typeof model === "number")
            return Math.max(0, Math.floor(model))
        if (Array.isArray(model))
            return model.length
        if (model && typeof model.count === "number")
            return Math.max(0, model.count)
        return 0
    }
    readonly property bool hasAsymmetricCounts: leftCount >= 0 || rightCount >= 0
    readonly property int resolvedLeftCount: Math.max(0, leftCount)
    readonly property int resolvedRightCount: Math.max(0, rightCount)
    readonly property int targetVisibleCount: hasAsymmetricCounts
        ? resolvedLeftCount + 1 + resolvedRightCount
        : Math.max(1, maxVisibleItems)
    readonly property int visibleItemCount: Math.min(count, Math.max(1, targetVisibleCount))
    readonly property int cachedItemCount: Math.min(maxCachedItems, Math.max(0, count - visibleItemCount))
    readonly property real highlightPosition: {
        if (!hasAsymmetricCounts)
            return 0.5
        const totalSides = resolvedLeftCount + resolvedRightCount
        return totalSides > 0 ? resolvedLeftCount / totalSides : 0.5
    }
    readonly property int selectedIndex: count > 0
        ? ((currentIndex % count) + count) % count
        : -1
    readonly property Item selectedItem: view.currentItem
    readonly property int pathIntervals: Math.max(0, visibleItemCount - 1)
    readonly property real unscaledStep: (vertical ? cardHeight : cardWidth) + spacing
    readonly property real unscaledShift: unscaledExpansion / 2
    readonly property real unscaledExpansion: Math.max(0, vertical ? selectedHeight - cardHeight : selectedWidth - cardWidth)
    readonly property int selectedNeighborCount: Math.min(2, pathIntervals)
    readonly property real requiredWidth: visibleItemCount * (vertical ? cardHeight : cardWidth)
        + pathIntervals * spacing
        + unscaledExpansion
        + selectedNeighborCount * unscaledShift
    readonly property real layoutScale: vertical
        ? Math.min(1, height / Math.max(1, requiredWidth), width / Math.max(1, selectedWidth))
        : (width > 0 && requiredWidth > width ? width / requiredWidth : 1)
    readonly property real resolvedCardWidth: cardWidth * layoutScale
    readonly property real resolvedCardHeight: cardHeight * layoutScale
    readonly property real resolvedSelectedWidth: selectedWidth * layoutScale
    readonly property real resolvedSelectedHeight: selectedHeight * layoutScale
    readonly property real resolvedSpacing: spacing * layoutScale
    readonly property real itemStep: (vertical ? resolvedCardHeight : resolvedCardWidth) + resolvedSpacing
    readonly property real shiftOffset: unscaledShift * layoutScale
    readonly property real pathSpan: pathIntervals * itemStep
    readonly property real leftStartX: resolvedSelectedWidth / 2 + 16 * layoutScale
    readonly property real pathStartX: vertical ? width / 2 : (alignLeft ? leftStartX : (width - pathSpan) / 2)
    readonly property real pathStartY: vertical ? (height - pathSpan) / 2 : height / 2
    readonly property real highlightX: pathStartX + highlightPosition * pathSpan
    readonly property real highlightY: pathStartY + highlightPosition * pathSpan
    readonly property int moveDuration: motionTokens ? motionTokens.durationNormal : 0
    property bool _snapping: false
    property bool _snapScheduled: false

    function scheduleSnap() {
        if (_snapScheduled || selectedIndex < 0)
            return
        _snapScheduled = true
        Qt.callLater(snapToSelected)
    }

    function snapToSelected() {
        _snapScheduled = false
        if (count <= 0 || selectedIndex < 0)
            return
        if (view.currentIndex === selectedIndex)
            return
        _snapping = true
        view.positionViewAtIndex(selectedIndex, PathView.SnapPosition)
        Qt.callLater(() => { _snapping = false })
    }

    implicitHeight: resolvedSelectedHeight + 16 * layoutScale
    clip: true

    PathView {
        id: view
        anchors.fill: parent
        visible: carousel.count > 0
        model: carousel.model
        pathItemCount: carousel.visibleItemCount
        cacheItemCount: carousel.cachedItemCount
        preferredHighlightBegin: carousel.highlightPosition
        preferredHighlightEnd: carousel.highlightPosition
        highlightRangeMode: PathView.StrictlyEnforceRange
        highlightMoveDuration: carousel._snapping ? 0 : carousel.moveDuration
        movementDirection: PathView.Shortest
        interactive: false

        onModelChanged: carousel.scheduleSnap()
        onVisibleChanged: {
            if (visible)
                carousel.scheduleSnap()
        }

        Binding {
            target: view
            property: "currentIndex"
            value: carousel.selectedIndex
            when: carousel.count > 0 && carousel.selectedIndex >= 0
        }

        delegate: Item {
            id: slot
            required property int index

            readonly property bool selected: PathView.isCurrentItem
            readonly property bool inPath: PathView.onPath
            readonly property real sideDistance: carousel.vertical ? y + height / 2 - carousel.highlightY : x + width / 2 - carousel.highlightX
            property real translateX: selected || Math.abs(sideDistance) < 1
                ? 0
                : (sideDistance < 0 ? -carousel.shiftOffset : carousel.shiftOffset)

            width: selected ? carousel.resolvedSelectedWidth : carousel.resolvedCardWidth
            height: selected ? carousel.resolvedSelectedHeight : carousel.resolvedCardHeight
            z: selected ? 10 : 1
            scale: selected ? 1 : carousel.sideScale
            opacity: inPath ? 1 : 0
            visible: opacity > 0.01

            transform: Translate { x: carousel.vertical ? 0 : slot.translateX; y: carousel.vertical ? slot.translateX : 0 }

            Behavior on width {
                NumberAnimation {
                    duration: carousel.moveDuration
                    easing.type: carousel.motionTokens ? carousel.motionTokens.easingSnappy : Easing.Linear
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: carousel.moveDuration
                    easing.type: carousel.motionTokens ? carousel.motionTokens.easingSnappy : Easing.Linear
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: carousel.moveDuration
                    easing.type: carousel.motionTokens ? carousel.motionTokens.easingSnappy : Easing.Linear
                }
            }
            Behavior on translateX {
                NumberAnimation {
                    duration: carousel.moveDuration
                    easing.type: carousel.motionTokens ? carousel.motionTokens.easingSnappy : Easing.Linear
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: carousel.motionTokens
                        ? (slot.inPath ? carousel.motionTokens.fadeInDuration : carousel.motionTokens.fadeOutDuration)
                        : 0
                    easing.type: carousel.motionTokens
                        ? (slot.inPath ? carousel.motionTokens.fadeInEasing : carousel.motionTokens.fadeOutEasing)
                        : Easing.Linear
                }
            }

            Loader {
                id: itemLoader
                anchors.fill: parent
                sourceComponent: carousel.delegate

                Binding {
                    target: itemLoader.item
                    property: "index"
                    value: slot.index
                    when: itemLoader.item !== null && ("index" in itemLoader.item)
                }
                Binding {
                    target: itemLoader.item
                    property: "selected"
                    value: slot.selected
                    when: itemLoader.item !== null && ("selected" in itemLoader.item)
                }
                Binding {
                    target: itemLoader.item
                    property: "focused"
                    value: carousel.focused && slot.selected
                    when: itemLoader.item !== null && ("focused" in itemLoader.item)
                }
                Binding {
                    target: itemLoader.item
                    property: "itemData"
                    value: carousel.itemDataAt(slot.index)
                    when: itemLoader.item !== null && ("itemData" in itemLoader.item)
                }
            }
        }

        path: Path {
            startX: carousel.pathStartX
            startY: carousel.pathStartY
            PathLine {
                x: carousel.vertical ? carousel.pathStartX : carousel.pathStartX + carousel.pathSpan
                y: carousel.vertical ? carousel.pathStartY + carousel.pathSpan : carousel.pathStartY
            }
        }
    }

    function itemDataAt(index) {
        if (Array.isArray(model))
            return model[index]
        if (model && typeof model.get === "function")
            return model.get(index)
        return index
    }
}
